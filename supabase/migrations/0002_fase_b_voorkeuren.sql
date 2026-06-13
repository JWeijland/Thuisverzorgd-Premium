-- ============================================================
-- Fase B — Voorkeuren: meldingen + privacy/consent (idempotent)
-- Draai dit NA 0001_fase_a_backend_consistency.sql.
--
-- Aparte tabellen (gekozen opslagvorm), elk met RLS waarin een gebruiker
-- uitsluitend zijn/haar eigen rij ziet en schrijft. De app gebruikt upsert,
-- dus we geven SELECT + INSERT + UPDATE op de eigen rij.
-- ============================================================

-- ------------------------------------------------------------
-- B1. Meldingsvoorkeuren — één rij per gebruiker
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notification_preferences (
    user_id          UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    push_enabled     BOOLEAN NOT NULL DEFAULT TRUE,   -- hoofd-toggle per gebruiker
    visit_updates    BOOLEAN NOT NULL DEFAULT TRUE,   -- bezoek: geaccepteerd/onderweg/afgerond
    new_tasks_nearby BOOLEAN NOT NULL DEFAULT TRUE,   -- buddy: nieuwe taken in de buurt
    sos_alerts       BOOLEAN NOT NULL DEFAULT TRUE,   -- familie: SOS-alarm
    monthly_report   BOOLEAN NOT NULL DEFAULT FALSE,  -- familie: maandrapport per e-mail
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Eigen meldingsvoorkeuren lezen"   ON notification_preferences;
DROP POLICY IF EXISTS "Eigen meldingsvoorkeuren aanmaken" ON notification_preferences;
DROP POLICY IF EXISTS "Eigen meldingsvoorkeuren updaten"  ON notification_preferences;
CREATE POLICY "Eigen meldingsvoorkeuren lezen"
    ON notification_preferences FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Eigen meldingsvoorkeuren aanmaken"
    ON notification_preferences FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Eigen meldingsvoorkeuren updaten"
    ON notification_preferences FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ------------------------------------------------------------
-- B2. Privacy/analytics-consent — opt-in (default FALSE, AVG-vriendelijk)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics_consent (
    user_id    UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    consented  BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE analytics_consent ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Eigen consent lezen"   ON analytics_consent;
DROP POLICY IF EXISTS "Eigen consent aanmaken" ON analytics_consent;
DROP POLICY IF EXISTS "Eigen consent updaten"  ON analytics_consent;
CREATE POLICY "Eigen consent lezen"
    ON analytics_consent FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Eigen consent aanmaken"
    ON analytics_consent FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Eigen consent updaten"
    ON analytics_consent FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ------------------------------------------------------------
-- B3. updated_at bijwerken bij wijziging
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_notif_prefs_updated_at ON notification_preferences;
CREATE TRIGGER trg_notif_prefs_updated_at
    BEFORE UPDATE ON notification_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_consent_updated_at ON analytics_consent;
CREATE TRIGGER trg_consent_updated_at
    BEFORE UPDATE ON analytics_consent
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ------------------------------------------------------------
-- B4. Server-side consent-gate op analytics_record()
--     Zo stopt/start het verzamelen écht: zonder consent wordt een event
--     stil genegeerd, ongeacht wat de client aanroept. De rest van de functie
--     is identiek aan analytics.sql.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION analytics_record(
    p_event_type   TEXT,
    p_age_bucket   TEXT             DEFAULT NULL,
    p_region       TEXT             DEFAULT NULL,
    p_category     task_category    DEFAULT NULL,
    p_timing_type  task_timing_type DEFAULT NULL,
    p_extras       TEXT[]           DEFAULT '{}',
    p_amount_cents INTEGER          DEFAULT NULL,
    p_rating       INTEGER          DEFAULT NULL,
    p_props        JSONB            DEFAULT '{}'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid  UUID := auth.uid();
    v_role user_role;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'analytics_record vereist een ingelogde gebruiker';
    END IF;

    -- Consent-gate: geen toestemming → niets verzamelen.
    IF NOT EXISTS (
        SELECT 1 FROM analytics_consent WHERE user_id = v_uid AND consented
    ) THEN
        RETURN;
    END IF;

    SELECT role INTO v_role FROM profiles WHERE id = v_uid;

    INSERT INTO analytics_events (
        event_type, actor_hash, role, age_bucket, region,
        category, timing_type, extras, amount_cents, rating, props
    ) VALUES (
        p_event_type,
        analytics_actor_hash(v_uid),
        v_role,
        p_age_bucket,
        p_region,
        p_category,
        p_timing_type,
        COALESCE(p_extras, '{}'),
        p_amount_cents,
        p_rating,
        COALESCE(p_props, '{}')
    );
END;
$$;

-- ============================================================
-- KLAAR — Fase B.
-- ============================================================
