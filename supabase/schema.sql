-- ============================================================
-- Thuisverzorgd — Supabase Database Schema
-- Plak dit in Supabase → SQL Editor → New query → Run
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE user_role        AS ENUM ('elderly', 'buddy', 'family');
CREATE TYPE task_category    AS ENUM ('companionship','groceries','medication_reminder','bed_help','light_cleaning','meal_prep','walk_outdoors','appointment','other');
CREATE TYPE task_status      AS ENUM ('open','accepted','arrived','in_progress','completed','cancelled');
CREATE TYPE task_timing_type AS ENUM ('now','today','scheduled');


-- ============================================================
-- PROFILES (basis voor alle gebruikers, gekoppeld aan auth.users)
-- ============================================================

CREATE TABLE profiles (
    id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role         user_role NOT NULL,
    first_name   TEXT NOT NULL DEFAULT '',
    last_name    TEXT NOT NULL DEFAULT '',
    phone_number TEXT,
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ELDERLY PROFILES
-- ============================================================

CREATE TABLE elderly_profiles (
    id               UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    address          TEXT DEFAULT '',
    latitude         DOUBLE PRECISION,
    longitude        DOUBLE PRECISION,
    date_of_birth    DATE,
    allergies        TEXT[]  DEFAULT '{}',
    medication_notes TEXT    DEFAULT '',
    credit_euros     DECIMAL(10,2) DEFAULT 10.00
);

-- ============================================================
-- BUDDY PROFILES
-- ============================================================

CREATE TABLE buddy_profiles (
    id                      UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    bio                     TEXT DEFAULT '',
    study                   TEXT DEFAULT '',
    avatar_system_name      TEXT DEFAULT 'person.crop.circle.fill',
    rating_average          DOUBLE PRECISION DEFAULT 0.0,
    total_tasks             INTEGER DEFAULT 0,
    offered_services        TEXT[] DEFAULT '{}',
    kvk_number              TEXT,
    vog_valid               BOOLEAN DEFAULT FALSE,
    vog_expires_at          TIMESTAMPTZ,
    intake_done             BOOLEAN DEFAULT FALSE,
    iban_last4              TEXT DEFAULT '****',
    is_available_now        BOOLEAN DEFAULT FALSE,
    is_onboarding_complete  BOOLEAN DEFAULT FALSE
);

-- ============================================================
-- FAMILY PROFILES
-- ============================================================

CREATE TABLE family_profiles (
    id           UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    relationship TEXT DEFAULT ''
);

-- ============================================================
-- FAMILY ↔ ELDERLY KOPPELING (via welkomstcode)
-- ============================================================

CREATE TABLE family_elderly_links (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id  UUID REFERENCES profiles(id) ON DELETE CASCADE,
    elderly_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    linked_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(family_id, elderly_id)
);

-- Welkomstcodes voor koppeling (6-cijferige code op welkomstkaart)
CREATE TABLE linking_codes (
    code        TEXT PRIMARY KEY,              -- bijv. "483921"
    elderly_id  UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    expires_at  TIMESTAMPTZ DEFAULT NOW() + INTERVAL '1 year',
    used_at     TIMESTAMPTZ                    -- null = nog niet gebruikt
);

-- ============================================================
-- TAKEN
-- ============================================================

CREATE TABLE tasks (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    elderly_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    assigned_buddy_id    UUID REFERENCES profiles(id) ON DELETE SET NULL,
    category             task_category NOT NULL,
    timing_type          task_timing_type DEFAULT 'now',
    scheduled_at         TIMESTAMPTZ,
    note                 TEXT DEFAULT '',
    price_cents          INTEGER NOT NULL,
    status               task_status DEFAULT 'open',
    created_at           TIMESTAMPTZ DEFAULT NOW(),
    accepted_at          TIMESTAMPTZ,
    arrived_at           TIMESTAMPTZ,
    completed_at         TIMESTAMPTZ,
    completion_note      TEXT,
    buddy_eta_minutes    INTEGER
);

-- ============================================================
-- BEOORDELINGEN
-- ============================================================

CREATE TABLE reviews (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id      UUID REFERENCES tasks(id) ON DELETE CASCADE,
    reviewer_id  UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reviewee_id  UUID REFERENCES profiles(id) ON DELETE CASCADE,
    stars        INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 5),
    body         TEXT DEFAULT '',
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- VERDIENSTEN
-- ============================================================

CREATE TABLE earnings (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    buddy_id      UUID REFERENCES profiles(id) ON DELETE CASCADE,
    task_id       UUID REFERENCES tasks(id) ON DELETE CASCADE,
    elderly_name  TEXT NOT NULL,        -- alleen voornaam (privacy)
    category      task_category NOT NULL,
    amount_cents  INTEGER NOT NULL,     -- netto (na 20% commissie)
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- SOS EVENTS
-- ============================================================

CREATE TABLE sos_events (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    elderly_id   UUID REFERENCES profiles(id) ON DELETE CASCADE,
    triggered_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at  TIMESTAMPTZ,
    notes        TEXT DEFAULT ''
);

-- ============================================================
-- INDEXEN (performance)
-- ============================================================

CREATE INDEX idx_tasks_status           ON tasks(status);
CREATE INDEX idx_tasks_elderly_id       ON tasks(elderly_id);
CREATE INDEX idx_tasks_buddy_id         ON tasks(assigned_buddy_id);
CREATE INDEX idx_tasks_created_at       ON tasks(created_at DESC);
CREATE INDEX idx_buddy_available        ON buddy_profiles(is_available_now);
CREATE INDEX idx_earnings_buddy_id      ON earnings(buddy_id);
CREATE INDEX idx_family_links_family    ON family_elderly_links(family_id);
CREATE INDEX idx_family_links_elderly   ON family_elderly_links(elderly_id);
CREATE INDEX idx_linking_codes_elderly  ON linking_codes(elderly_id);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- AUTOMATISCH PROFIEL AANMAKEN BIJ REGISTRATIE
-- Wordt getriggerd zodra iemand sign-up doet via Supabase Auth
-- ============================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- role en namen worden meegegeven als metadata bij registratie
    INSERT INTO public.profiles (id, role, first_name, last_name, phone_number)
    VALUES (
        NEW.id,
        (NEW.raw_user_meta_data->>'role')::public.user_role,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        NEW.phone
    );

    -- Maak rol-specifiek profiel aan
    IF (NEW.raw_user_meta_data->>'role') = 'elderly' THEN
        INSERT INTO public.elderly_profiles (id) VALUES (NEW.id);
    ELSIF (NEW.raw_user_meta_data->>'role') = 'buddy' THEN
        INSERT INTO public.buddy_profiles (id) VALUES (NEW.id);
    ELSIF (NEW.raw_user_meta_data->>'role') = 'family' THEN
        INSERT INTO public.family_profiles (id) VALUES (NEW.id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- BUDDY RATING AUTOMATISCH UPDATEN NA NIEUWE REVIEW
-- ============================================================

CREATE OR REPLACE FUNCTION update_buddy_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE buddy_profiles
    SET rating_average = (
        SELECT ROUND(AVG(stars)::numeric, 1)
        FROM reviews
        WHERE reviewee_id = NEW.reviewee_id
    ),
    total_tasks = (
        SELECT COUNT(*)
        FROM tasks
        WHERE assigned_buddy_id = NEW.reviewee_id
          AND status = 'completed'
    )
    WHERE id = NEW.reviewee_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_buddy_rating
    AFTER INSERT ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_buddy_rating();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- Zorgt dat gebruikers alleen hun eigen data kunnen zien
-- ============================================================

ALTER TABLE profiles              ENABLE ROW LEVEL SECURITY;
ALTER TABLE elderly_profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE buddy_profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_elderly_links  ENABLE ROW LEVEL SECURITY;
ALTER TABLE linking_codes         ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews               ENABLE ROW LEVEL SECURITY;
ALTER TABLE earnings              ENABLE ROW LEVEL SECURITY;
ALTER TABLE sos_events            ENABLE ROW LEVEL SECURITY;

-- Profiles: aanmaken (trigger), lezen en updaten
CREATE POLICY "Trigger kan profielen aanmaken" ON profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "Eigen profiel lezen"            ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Eigen profiel updaten"          ON profiles FOR UPDATE USING (auth.uid() = id);

-- Elderly profiles: eigen + gekoppelde familie kan lezen
CREATE POLICY "Eigen elderly profiel" ON elderly_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Familie kan elderly profiel lezen" ON elderly_profiles FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM family_elderly_links
        WHERE family_id = auth.uid() AND elderly_id = elderly_profiles.id
    )
);
CREATE POLICY "Elderly kan eigen profiel updaten" ON elderly_profiles FOR UPDATE USING (auth.uid() = id);

-- Buddy profiles: iedereen kan lezen (nodig voor taakmatching op de kaart)
CREATE POLICY "Buddy profielen zijn publiek leesbaar" ON buddy_profiles FOR SELECT USING (TRUE);
CREATE POLICY "Buddy kan eigen profiel updaten" ON buddy_profiles FOR UPDATE USING (auth.uid() = id);

-- Taken: open taken zichtbaar voor alle buddies; eigen taken voor elderly/family
CREATE POLICY "Open taken zichtbaar voor ingelogde buddies" ON tasks FOR SELECT USING (
    auth.uid() IS NOT NULL AND (
        status = 'open'
        OR elderly_id = auth.uid()
        OR assigned_buddy_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM family_elderly_links
            WHERE family_id = auth.uid() AND elderly_id = tasks.elderly_id
        )
    )
);
CREATE POLICY "Elderly kan eigen taken aanmaken" ON tasks FOR INSERT WITH CHECK (elderly_id = auth.uid());
CREATE POLICY "Buddy kan taakstatus updaten" ON tasks FOR UPDATE USING (
    assigned_buddy_id = auth.uid() OR elderly_id = auth.uid()
);

-- Verdiensten: alleen eigen verdiensten
CREATE POLICY "Eigen verdiensten" ON earnings FOR SELECT USING (buddy_id = auth.uid());

-- Reviews: iedereen kan beoordelingen lezen (voor buddy profiel)
CREATE POLICY "Reviews zijn publiek leesbaar" ON reviews FOR SELECT USING (TRUE);
CREATE POLICY "Elderly kan review plaatsen" ON reviews FOR INSERT WITH CHECK (reviewer_id = auth.uid());

-- SOS: eigen elderly + gekoppelde familie
CREATE POLICY "SOS events voor betrokkenen" ON sos_events FOR SELECT USING (
    elderly_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM family_elderly_links
        WHERE family_id = auth.uid() AND elderly_id = sos_events.elderly_id
    )
);
CREATE POLICY "Elderly kan SOS aanmaken" ON sos_events FOR INSERT WITH CHECK (elderly_id = auth.uid());

-- Linking codes: elderly kan eigen code lezen; iedereen kan controleren (voor koppeling)
CREATE POLICY "Elderly kan eigen codes lezen" ON linking_codes FOR SELECT USING (elderly_id = auth.uid());
CREATE POLICY "Iedereen kan code valideren" ON linking_codes FOR SELECT USING (TRUE);
