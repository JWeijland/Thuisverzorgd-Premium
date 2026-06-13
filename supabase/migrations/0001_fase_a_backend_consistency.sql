-- ============================================================
-- Fase A — Backend-consistentie (idempotente migratie)
-- Draai dit NA schema.sql en analytics.sql, in Supabase → SQL Editor.
--
-- Doel: alle gaten dichten die uit de audit kwamen tussen wat de Swift-app
-- aanroept en wat de database toestaat. Veilig om meermaals te draaien:
-- overal IF NOT EXISTS / DROP ... IF EXISTS / CREATE OR REPLACE.
--
-- Zie AUDIT_FASE_A.md voor de volledige onderbouwing per blok.
-- ============================================================

-- ------------------------------------------------------------
-- A1. ROL 'admin' toevoegen aan de user_role enum
--     De Swift UserRole-enum kent .admin en er is een volledige AdminTabView,
--     maar de enum in de database kende alleen elderly/buddy/family. Zonder
--     deze waarde kan een admin nooit echt in de database bestaan.
--     ADD VALUE IF NOT EXISTS mag NIET in dezelfde transactie gebruikt worden
--     als waar de waarde wordt gelezen; daarom vergelijken we verderop altijd
--     op role::text = 'admin'.
-- ------------------------------------------------------------
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'admin';

-- ------------------------------------------------------------
-- A2. Ontbrekende kolommen die de app al verwacht/verzamelt
-- ------------------------------------------------------------

-- buddy_profiles: de onboarding verzamelt BTW, uurtarief, max. afstand en
-- ZZP-status, maar die konden nergens heen.
ALTER TABLE buddy_profiles ADD COLUMN IF NOT EXISTS btw_number        TEXT;
ALTER TABLE buddy_profiles ADD COLUMN IF NOT EXISTS hourly_rate_cents INTEGER;
ALTER TABLE buddy_profiles ADD COLUMN IF NOT EXISTS max_distance_km   INTEGER DEFAULT 10;
ALTER TABLE buddy_profiles ADD COLUMN IF NOT EXISTS is_zzp            BOOLEAN DEFAULT FALSE;

-- tasks: de buddy-kaart heeft per taak een coördinaat nodig. Zonder eigen
-- lat/long op de taak vallen alle aanvragen terug op één gedeeld
-- default-coördinaat en stapelen ze op één punt (zie Fase D).
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS latitude  DOUBLE PRECISION;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- ------------------------------------------------------------
-- A3. Admin-helper — is de ingelogde gebruiker een admin?
--     SECURITY DEFINER zodat de functie de profiles-rij mag lezen ook als de
--     RLS-policy de aanroeper dat (nog) niet toestaat. Vergelijkt op ::text
--     i.v.m. de zojuist toegevoegde enum-waarde.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role::text = 'admin'
    )
$$;

-- ------------------------------------------------------------
-- A4. RLS-schrijfgaten dichten die echte writes blokkeerden
--     Deze drie ontbraken volledig, waardoor de bijbehorende client-calls in
--     live-modus stilletjes faalden op RLS.
-- ------------------------------------------------------------

-- earnings: completeTask() doet een INSERT in earnings, maar er was alleen
-- een SELECT-policy → de insert werd geweigerd.
DROP POLICY IF EXISTS "Buddy kan eigen verdienste vastleggen" ON earnings;
CREATE POLICY "Buddy kan eigen verdienste vastleggen"
    ON earnings FOR INSERT
    WITH CHECK (buddy_id = auth.uid());

-- family_elderly_links: linkFamilyToElderly() doet een INSERT, maar er was
-- geen INSERT-policy → koppelen via welkomstcode mislukte in live-modus.
DROP POLICY IF EXISTS "Familie kan zichzelf koppelen" ON family_elderly_links;
CREATE POLICY "Familie kan zichzelf koppelen"
    ON family_elderly_links FOR INSERT
    WITH CHECK (family_id = auth.uid());

-- linking_codes: na koppelen wordt used_at gezet (UPDATE), maar er was geen
-- UPDATE-policy. We staan het verzilveren van een nog-ongebruikte code toe.
DROP POLICY IF EXISTS "Ongebruikte code verzilveren" ON linking_codes;
CREATE POLICY "Ongebruikte code verzilveren"
    ON linking_codes FOR UPDATE
    USING (used_at IS NULL)
    WITH CHECK (TRUE);

-- ------------------------------------------------------------
-- A5. Admin-leesrechten (read-only beheerschil)
--     Een admin moet over rollen heen kunnen lezen voor facturatie en
--     dashboard. Schrijfacties namens anderen lopen via SECURITY DEFINER-RPC's
--     (Fase C), niet via brede write-policies.
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Admin leest alle profielen"        ON profiles;
CREATE POLICY "Admin leest alle profielen"        ON profiles            FOR SELECT USING (is_admin());

DROP POLICY IF EXISTS "Admin leest elderly profielen"     ON elderly_profiles;
CREATE POLICY "Admin leest elderly profielen"     ON elderly_profiles    FOR SELECT USING (is_admin());

DROP POLICY IF EXISTS "Admin leest family profielen"      ON family_profiles;
CREATE POLICY "Admin leest family profielen"      ON family_profiles     FOR SELECT USING (is_admin());

DROP POLICY IF EXISTS "Admin leest alle taken"            ON tasks;
CREATE POLICY "Admin leest alle taken"            ON tasks               FOR SELECT USING (is_admin());

DROP POLICY IF EXISTS "Admin leest alle verdiensten"      ON earnings;
CREATE POLICY "Admin leest alle verdiensten"      ON earnings            FOR SELECT USING (is_admin());

DROP POLICY IF EXISTS "Admin leest alle koppelingen"      ON family_elderly_links;
CREATE POLICY "Admin leest alle koppelingen"      ON family_elderly_links FOR SELECT USING (is_admin());

DROP POLICY IF EXISTS "Admin leest alle sos events"       ON sos_events;
CREATE POLICY "Admin leest alle sos events"       ON sos_events          FOR SELECT USING (is_admin());

-- (buddy_profiles + reviews zijn al publiek leesbaar; linking_codes al via
--  "Iedereen kan code valideren".)

-- ------------------------------------------------------------
-- A6. Zelf-escalatie naar admin blokkeren
--     De profiles-UPDATE-policy had geen WITH CHECK, dus een gebruiker kon
--     z'n eigen rol op 'admin' zetten. We bewaken de rol met een trigger:
--     wijzigen van role mag alleen door de service-role (auth.uid() IS NULL),
--     niet door een ingelogde client.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION prevent_role_self_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.role IS DISTINCT FROM OLD.role AND auth.uid() IS NOT NULL THEN
        RAISE EXCEPTION 'Rol wijzigen is niet toegestaan vanaf de client';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_role_self_change ON profiles;
CREATE TRIGGER trg_prevent_role_self_change
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION prevent_role_self_change();

-- ------------------------------------------------------------
-- A7. Realtime-publicatie voor taken (idempotent)
--     SUPABASE_SETUP stap 2 vraagt dit handmatig; we borgen het hier ook.
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'tasks'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
    END IF;
END $$;

-- ============================================================
-- KLAAR — Fase A. Zie 0002+ voor Fase B/C.
-- ============================================================
