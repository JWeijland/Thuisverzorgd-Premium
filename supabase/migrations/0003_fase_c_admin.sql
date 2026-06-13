-- ============================================================
-- Fase C — Adminschil: RPC's, facturatie- en dashboard-view (idempotent)
-- Draai NA 0002. Alle admin-schrijfacties lopen via SECURITY DEFINER-RPC's
-- die op is_admin() controleren; gewone RLS staat dit niet toe.
-- ============================================================

-- ------------------------------------------------------------
-- C0. Rolwijziging: admins (en service-role) mogen wél, clients niet.
--     Vervangt de trigger-functie uit 0001 zodat admin_set_role werkt.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION prevent_role_self_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.role IS DISTINCT FROM OLD.role
       AND auth.uid() IS NOT NULL
       AND NOT is_admin() THEN
        RAISE EXCEPTION 'Rol wijzigen is niet toegestaan vanaf de client';
    END IF;
    RETURN NEW;
END;
$$;

-- ------------------------------------------------------------
-- C1. Telefonische aanvraag — taak namens een oudere aanmaken
--     RLS staat een INSERT alleen toe als elderly_id = auth.uid(); een admin
--     plaatst namens iemand anders, dus dat moet via deze definer-RPC.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_task_on_behalf(
    p_elderly_id   UUID,
    p_category     task_category,
    p_timing_type  task_timing_type,
    p_scheduled_at TIMESTAMPTZ,
    p_note         TEXT,
    p_price_cents  INTEGER,
    p_latitude     DOUBLE PRECISION DEFAULT NULL,
    p_longitude    DOUBLE PRECISION DEFAULT NULL
)
RETURNS tasks
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_task tasks;
BEGIN
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'Alleen admins mogen namens een oudere een taak aanmaken';
    END IF;

    INSERT INTO tasks (
        elderly_id, category, timing_type, scheduled_at,
        note, price_cents, latitude, longitude
    ) VALUES (
        p_elderly_id, p_category, p_timing_type, p_scheduled_at,
        COALESCE(p_note, ''), p_price_cents, p_latitude, p_longitude
    )
    RETURNING * INTO v_task;

    RETURN v_task;
END;
$$;

GRANT EXECUTE ON FUNCTION create_task_on_behalf(
    UUID, task_category, task_timing_type, TIMESTAMPTZ, TEXT, INTEGER,
    DOUBLE PRECISION, DOUBLE PRECISION
) TO authenticated;

-- ------------------------------------------------------------
-- C2. Intake & VOG beheren
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION admin_set_intake(p_buddy_id UUID, p_done BOOLEAN)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF NOT is_admin() THEN RAISE EXCEPTION 'Alleen admins'; END IF;
    UPDATE buddy_profiles SET intake_done = p_done WHERE id = p_buddy_id;
END; $$;

CREATE OR REPLACE FUNCTION admin_set_vog(
    p_buddy_id UUID, p_valid BOOLEAN, p_expires_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF NOT is_admin() THEN RAISE EXCEPTION 'Alleen admins'; END IF;
    UPDATE buddy_profiles
       SET vog_valid = p_valid,
           vog_expires_at = COALESCE(p_expires_at, vog_expires_at)
     WHERE id = p_buddy_id;
END; $$;

GRANT EXECUTE ON FUNCTION admin_set_intake(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_set_vog(UUID, BOOLEAN, TIMESTAMPTZ) TO authenticated;

-- ------------------------------------------------------------
-- C3. Rollen beheren (zonder zelf-escalatie / eigen rol wijzigen)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION admin_set_role(p_user_id UUID, p_role user_role)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'Alleen admins mogen rollen wijzigen';
    END IF;
    IF p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'Je kunt je eigen rol niet wijzigen';
    END IF;
    UPDATE profiles SET role = p_role WHERE id = p_user_id;
END; $$;

GRANT EXECUTE ON FUNCTION admin_set_role(UUID, user_role) TO authenticated;

-- ------------------------------------------------------------
-- C4. Koppelcode aanmaken (admin) — RLS verbiedt directe INSERT
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION admin_create_linking_code(p_elderly_id UUID, p_code TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF NOT is_admin() THEN RAISE EXCEPTION 'Alleen admins'; END IF;
    INSERT INTO linking_codes (code, elderly_id)
    VALUES (p_code, p_elderly_id)
    ON CONFLICT (code) DO NOTHING;
END; $$;

GRANT EXECUTE ON FUNCTION admin_create_linking_code(UUID, TEXT) TO authenticated;

-- ------------------------------------------------------------
-- C5. Facturatie-overzicht (display-only) — view met is_admin()-guard
--     Non-admins krijgen nul rijen. Klant betaalt = task.price_cents,
--     buddy verdienste = earnings.amount_cents (netto), fee = verschil.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW admin_billing AS
SELECT
    e.id,
    e.created_at,
    to_char(e.created_at AT TIME ZONE 'Europe/Amsterdam', 'YYYY-MM') AS month,
    e.elderly_name,
    e.category,
    bp.first_name        AS buddy_first_name,
    bp.last_name         AS buddy_last_name,
    COALESCE(t.price_cents, e.amount_cents) AS client_amount_cents,
    e.amount_cents       AS buddy_amount_cents,
    COALESCE(t.price_cents, e.amount_cents) - e.amount_cents AS platform_fee_cents
FROM earnings e
JOIN profiles bp ON bp.id = e.buddy_id
LEFT JOIN tasks t ON t.id = e.task_id
WHERE is_admin();

GRANT SELECT ON admin_billing TO authenticated;

-- ------------------------------------------------------------
-- C6. Dashboard-tellingen — read-only, één rij, is_admin()-guard
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW admin_dashboard_stats AS
SELECT
    (SELECT COUNT(*) FROM profiles        WHERE role = 'buddy')   AS buddies,
    (SELECT COUNT(*) FROM profiles        WHERE role = 'elderly') AS elderly,
    (SELECT COUNT(*) FROM profiles        WHERE role = 'family')  AS families,
    (SELECT COUNT(*) FROM tasks           WHERE status = 'open')                                AS open_tasks,
    (SELECT COUNT(*) FROM tasks           WHERE status IN ('accepted','arrived','in_progress')) AS active_tasks,
    (SELECT COUNT(*) FROM tasks           WHERE status = 'completed')                           AS completed_tasks,
    (SELECT COUNT(*) FROM buddy_profiles  WHERE NOT intake_done)  AS pending_intakes,
    (SELECT COUNT(*) FROM buddy_profiles  WHERE NOT vog_valid)    AS pending_vog
WHERE is_admin();

GRANT SELECT ON admin_dashboard_stats TO authenticated;

-- ============================================================
-- KLAAR — Fase C.
-- ============================================================
