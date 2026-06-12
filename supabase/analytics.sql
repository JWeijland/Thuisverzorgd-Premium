-- ============================================================
-- Thuisverzorgd — Analytics & geaggregeerde data-verzameling
-- Plak dit in Supabase → SQL Editor → New query → Run
-- (Draai dit NA schema.sql.)
--
-- Doel: heel veel data verzamelen over GROEPEN mensen, nooit over
-- individuen. Daarom:
--   1. Ruwe events worden weggeschreven via een server-functie die een
--      PSEUDONIEME actor-hash berekent (geen e-mail/naam/uid in de data).
--   2. De ruwe tabel is voor clients NIET leesbaar (geen SELECT-policy).
--   3. Alleen GEAGGREGEERDE views zijn uitleesbaar, met K-ANONIMITEIT:
--      groepen kleiner dan K (=5) personen worden weggelaten, zodat je
--      nooit tot een individu kunt herleiden.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- voor digest()/hashing

-- ============================================================
-- 0. CONFIG — k-anonimiteitsdrempel
--    Pas dit getal aan om strenger/soepeler te zijn (min. aanbevolen: 5).
-- ============================================================

CREATE OR REPLACE FUNCTION analytics_k_threshold()
RETURNS int LANGUAGE sql IMMUTABLE AS $$ SELECT 5 $$;

-- ============================================================
-- 1. RUWE EVENT-TABEL
--    Eén rij per gebeurtenis. Bevat alleen dimensies die nuttig zijn voor
--    groepsanalyse — bewust GEEN directe identifiers, adres of geboortedatum.
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics_events (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    occurred_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    event_type    TEXT NOT NULL,                 -- bv. 'task_created', 'extra_purchased'
    actor_hash    TEXT NOT NULL,                 -- pseudoniem (zie analytics_record)

    -- Groepsdimensies (allemaal grofkorrelig / niet-identificerend)
    role          user_role,                     -- elderly | buddy | family
    age_bucket    TEXT,                          -- '60-69', '70-79', '80-89', '90+'
    region        TEXT,                          -- gemeente/provincie (NOOIT straat)
    category      task_category,
    timing_type   task_timing_type,
    extras        TEXT[] NOT NULL DEFAULT '{}',  -- ['urgent','wide_reach','extended_stay']
    amount_cents  INTEGER,                       -- bedrag bij betaal-events
    rating        INTEGER,                       -- 1..5 bij review-events

    -- Vrije, uitbreidbare eigenschappen voor toekomstige metrics
    props         JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_analytics_event_type ON analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_occurred   ON analytics_events(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_region     ON analytics_events(region);
CREATE INDEX IF NOT EXISTS idx_analytics_category   ON analytics_events(category);

-- ============================================================
-- 2. HASH-HELPER + SCHRIJF-FUNCTIE
--    Clients schrijven NIET direct in de tabel. Ze roepen analytics_record()
--    aan (RPC). De functie berekent zelf de pseudonieme actor-hash uit het
--    ingelogde auth.uid(), zodat een client geen identiteiten kan vervalsen
--    of koppelen. De hash is stabiel per gebruiker (voor distinct-tellingen)
--    maar niet terug te rekenen naar de gebruiker.
-- ============================================================

CREATE OR REPLACE FUNCTION analytics_actor_hash(p_uid UUID)
RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
    -- Salt voorkomt dat een uitgelekte tabel via een simpele uid-hash
    -- gekoppeld kan worden. Wijzig de salt NIET na livegang (breekt tellingen).
    SELECT encode(
        digest('tvz-analytics-pepper-v1::' || COALESCE(p_uid::text, 'anon'), 'sha256'),
        'hex'
    )
$$;

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
-- 3. RLS — ruwe events afschermen
--    Geen enkele client mag ruwe rijen lezen. Inserts lopen uitsluitend via
--    analytics_record() (SECURITY DEFINER), dus we geven clients ook geen
--    directe INSERT/SELECT op de tabel.
-- ============================================================

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;
-- Bewust GEEN policies: met RLS aan en zonder policy is de tabel voor
-- gewone rollen volledig dicht. De definer-functie omzeilt dit veilig.

REVOKE ALL ON analytics_events FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION analytics_record(
    TEXT, TEXT, TEXT, task_category, task_timing_type, TEXT[], INTEGER, INTEGER, JSONB
) TO authenticated;

-- ============================================================
-- 4. INTERNE "ENRICHED" VIEW (tijdsdimensies)
--    We berekenen dag/week/maand/uur/weekdag hier in plaats van in
--    GENERATED-kolommen, omdat tijdzone-conversie niet immutable is.
--    Lokale tijd = Europe/Amsterdam. Deze view is NIET voor clients.
-- ============================================================

CREATE OR REPLACE VIEW analytics_events_enriched AS
SELECT
    e.*,
    (e.occurred_at AT TIME ZONE 'Europe/Amsterdam')::date                       AS day,
    date_trunc('week',  e.occurred_at AT TIME ZONE 'Europe/Amsterdam')::date    AS week,
    date_trunc('month', e.occurred_at AT TIME ZONE 'Europe/Amsterdam')::date    AS month,
    EXTRACT(HOUR  FROM e.occurred_at AT TIME ZONE 'Europe/Amsterdam')::int       AS hour_of_day,
    EXTRACT(ISODOW FROM e.occurred_at AT TIME ZONE 'Europe/Amsterdam')::int      AS dow  -- 1=ma .. 7=zo
FROM analytics_events e;

REVOKE ALL ON analytics_events_enriched FROM anon, authenticated;

-- ============================================================
-- 5. GEAGGREGEERDE VIEWS (k-anonimiteit afgedwongen)
--    Deze views draaien met de rechten van de eigenaar (security_invoker = off,
--    de standaard) en geven UITSLUITEND geaggregeerde rijen terug waarin de
--    groep >= K personen telt.
-- ============================================================

-- 5a. Wekelijks actieve gebruikers per rol
CREATE OR REPLACE VIEW analytics_active_users AS
SELECT
    week,
    role,
    COUNT(DISTINCT actor_hash)                       AS active_people,
    COUNT(*) FILTER (WHERE event_type = 'app_open')  AS app_opens,
    COUNT(*)                                         AS total_events
FROM analytics_events_enriched
GROUP BY week, role
HAVING COUNT(DISTINCT actor_hash) >= analytics_k_threshold();

-- 5b. Vraag naar hulp per categorie en regio
CREATE OR REPLACE VIEW analytics_demand_by_category AS
SELECT
    week,
    region,
    category,
    COUNT(*)                    AS requests,
    COUNT(DISTINCT actor_hash)  AS distinct_people,
    ROUND(AVG(amount_cents))    AS avg_amount_cents
FROM analytics_events_enriched
WHERE event_type = 'task_created'
GROUP BY week, region, category
HAVING COUNT(DISTINCT actor_hash) >= analytics_k_threshold();

-- 5c. Tijdsverdeling van aanvragen (uur van de dag × weekdag)
CREATE OR REPLACE VIEW analytics_demand_by_time AS
SELECT
    dow,
    hour_of_day,
    region,
    COUNT(*)                    AS requests,
    COUNT(DISTINCT actor_hash)  AS distinct_people
FROM analytics_events_enriched
WHERE event_type = 'task_created'
GROUP BY dow, hour_of_day, region
HAVING COUNT(DISTINCT actor_hash) >= analytics_k_threshold();

-- 5d. Conversietrechter: aangevraagd → geaccepteerd → afgerond → geannuleerd
CREATE OR REPLACE VIEW analytics_task_funnel AS
SELECT
    week,
    region,
    COUNT(*) FILTER (WHERE event_type = 'task_created')   AS created,
    COUNT(*) FILTER (WHERE event_type = 'task_accepted')  AS accepted,
    COUNT(*) FILTER (WHERE event_type = 'task_completed') AS completed,
    COUNT(*) FILTER (WHERE event_type = 'task_cancelled') AS cancelled,
    COUNT(DISTINCT actor_hash)                            AS distinct_people
FROM analytics_events_enriched
WHERE event_type IN ('task_created','task_accepted','task_completed','task_cancelled')
GROUP BY week, region
HAVING COUNT(DISTINCT actor_hash) >= analytics_k_threshold();

-- 5e. Gebruik van betaalde extra's (per losse extra, regio, leeftijdsgroep)
CREATE OR REPLACE VIEW analytics_extras_uptake AS
SELECT
    week,
    region,
    age_bucket,
    extra,
    COUNT(*)                    AS purchases,
    COUNT(DISTINCT actor_hash)  AS distinct_buyers,
    SUM(amount_cents)           AS gross_amount_cents
FROM analytics_events_enriched,
     LATERAL unnest(extras) AS extra
WHERE event_type = 'extra_purchased'
GROUP BY week, region, age_bucket, extra
HAVING COUNT(DISTINCT actor_hash) >= analytics_k_threshold();

-- 5f. Omzet uit extra's per week en regio
CREATE OR REPLACE VIEW analytics_revenue AS
SELECT
    week,
    region,
    COUNT(*)                    AS paid_transactions,
    COUNT(DISTINCT actor_hash)  AS paying_people,
    SUM(amount_cents)           AS gross_amount_cents,
    ROUND(AVG(amount_cents))    AS avg_amount_cents
FROM analytics_events_enriched
WHERE event_type = 'extra_purchased'
GROUP BY week, region
HAVING COUNT(DISTINCT actor_hash) >= analytics_k_threshold();

-- 5g. Tevredenheid (reviews) per regio en categorie
CREATE OR REPLACE VIEW analytics_satisfaction AS
SELECT
    month,
    region,
    category,
    COUNT(*)                       AS reviews,
    COUNT(DISTINCT actor_hash)     AS distinct_reviewers,
    ROUND(AVG(rating)::numeric, 2) AS avg_rating
FROM analytics_events_enriched
WHERE event_type = 'review_submitted' AND rating IS NOT NULL
GROUP BY month, region, category
HAVING COUNT(DISTINCT actor_hash) >= analytics_k_threshold();

-- 5h. Demografische opbouw van de actieve groep (nooit per persoon)
CREATE OR REPLACE VIEW analytics_demographics AS
SELECT
    month,
    region,
    role,
    age_bucket,
    COUNT(DISTINCT actor_hash) AS people
FROM analytics_events_enriched
GROUP BY month, region, role, age_bucket
HAVING COUNT(DISTINCT actor_hash) >= analytics_k_threshold();

-- ============================================================
-- 6. RECHTEN OP DE VIEWS
--    Alleen geaggregeerde views zijn leesbaar voor ingelogde gebruikers.
--    (Wil je ze alleen voor jezelf/dashboards? Verwijder dan 'authenticated'
--     en lees via de service-role key in je eigen backend/dashboard.)
-- ============================================================

GRANT SELECT ON
    analytics_active_users,
    analytics_demand_by_category,
    analytics_demand_by_time,
    analytics_task_funnel,
    analytics_extras_uptake,
    analytics_revenue,
    analytics_satisfaction,
    analytics_demographics
TO authenticated;

-- ============================================================
-- KLAAR.
--
-- Gebruik vanuit de app (voorbeeld, via Supabase RPC):
--   try await supabase.rpc("analytics_record", params: [
--       "p_event_type": "task_created",
--       "p_region": "Utrecht",
--       "p_age_bucket": "70-79",
--       "p_category": "groceries",
--       "p_timing_type": "now",
--       "p_extras": ["urgent"],
--       "p_amount_cents": 500
--   ]).execute()
--
-- Voorbeeld-uitlezen (dashboard / SQL editor):
--   SELECT * FROM analytics_demand_by_category ORDER BY week DESC;
--   SELECT * FROM analytics_extras_uptake     ORDER BY week DESC;
--   SELECT * FROM analytics_revenue           ORDER BY week DESC;
--
-- Privacy: ruwe rijen zijn niet opvraagbaar; elke view verbergt groepen
-- kleiner dan analytics_k_threshold() (=5). Verhoog die drempel voor
-- strengere anonimisering.
-- ============================================================
