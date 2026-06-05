# Thuisverzorgd — Supabase Master Setup

Dit document bevat **alles** wat je in Supabase moet uitvoeren, in volgorde.
Elke stap geeft aan of je hem in de **SQL Editor** of via het **Dashboard** uitvoert.

> De app draait in de MVP volledig op lokale mock-data. Deze setup is nodig
> zodra je de echte backend wilt koppelen.

---

## Stap 1 — Volledig schema aanmaken

> **Waar:** Supabase → SQL Editor → New query → plak → Run

Plak de volledige inhoud van `supabase/schema.sql` en klik **Run**.
Controleer daarna of dit slaagt (geen rode foutmeldingen).

---

## Stap 2 — Realtime inschakelen voor taken

> **Waar:** Supabase → Database → Replication

1. Ga naar **Database** → **Replication**
2. Klik op het getal naast `supabase_realtime`
3. Zet de toggle **AAN** voor de tabel **`tasks`**
4. Klik **Save**

Of via SQL:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
```

---

## Stap 3 — Auth instellingen

> **Waar:** Supabase → Authentication → Providers & Settings

### 3a. E-mail provider
1. **Authentication** → **Providers** → **Email**
2. Zet **Enable Email provider** AAN
3. **Confirm email:** voor interne test UIT, voor publieke beta AAN
4. **Save**

### 3b. Wachtwoordloze OTP (voor ouderen)
1. **Authentication** → **Providers** → **Phone**
2. Zet **Enable Phone provider** AAN
3. SMS provider: **Twilio** (apart account)
4. **Save**

> **Zonder Twilio:** telefoon-OTP werkt niet. Voor de eerste ronde volstaat
> e-mail + wachtwoord.

### 3c. Apple Sign-In (optioneel)
1. **Authentication** → **Providers** → **Apple**
2. Vul Service ID + Secret key (.p8) in → **Save**

---

## Stap 4 — Verificatie: alles werkt

> **Waar:** Supabase → SQL Editor

```sql
-- 1. Alle tabellen
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' ORDER BY table_name;
-- Verwacht: buddy_profiles, earnings, elderly_profiles, family_elderly_links,
--           family_profiles, linking_codes, profiles, reviews, sos_events, tasks

-- 2. RLS ingeschakeld op alle tabellen
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public' ORDER BY tablename;

-- 3. Triggers
SELECT trigger_name, event_object_table FROM information_schema.triggers
WHERE trigger_schema = 'public' ORDER BY trigger_name;
-- Verwacht: on_auth_user_created, trg_profiles_updated_at, trg_update_buddy_rating
```

---

## Stap 5 — Eerste testgebruikers aanmaken

> **Waar:** Supabase → Authentication → Users → Add user

### Testbuddy
1. **Add user** → e-mail `testbuddy@thuisverzorgd.nl`, wachtwoord `Test1234!`
2. Profiel compleet maken (vervang `[UUID]`):
```sql
INSERT INTO profiles (id, role, first_name, last_name)
VALUES ('[UUID]', 'buddy', 'Test', 'Buddy');

INSERT INTO buddy_profiles (id, vog_valid, intake_done, is_onboarding_complete, offered_services)
VALUES ('[UUID]', true, true, true, ARRAY['Gezelschap','Boodschappen','Wandelen']);
```

### Testoudere
1. **Add user** → e-mail `testoudere@thuisverzorgd.nl`, wachtwoord `Test1234!`
2. Profiel:
```sql
INSERT INTO profiles (id, role, first_name, last_name, phone_number)
VALUES ('[UUID]', 'elderly', 'Riet', 'van der Berg', '0612345678');

INSERT INTO elderly_profiles (id, address, latitude, longitude)
VALUES ('[UUID]', 'Elandsgracht 86, Amsterdam', 52.3717, 4.8836);
```

---

## Stap 6 — Welkomstcode aanmaken voor testoudere

> **Waar:** Supabase → SQL Editor

```sql
-- Vervang [ELDERLY_UUID] met het UUID van de testoudere
INSERT INTO linking_codes (code, elderly_id, expires_at)
VALUES ('123456', '[ELDERLY_UUID]', NOW() + INTERVAL '1 year');
```

---

## Overzicht: wat is waar in Supabase

| Onderdeel | Locatie |
|---|---|
| Tabellen bekijken | Table Editor |
| SQL uitvoeren | SQL Editor |
| Gebruikers beheren | Authentication → Users |
| Auth providers | Authentication → Providers |
| Realtime | Database → Replication |
| API keys | Project Settings → API |

---

## Supabase project gegevens

- **Project URL:** `https://oopmfcymxjataisfhryq.supabase.co`
- **Publishable key:** zit in `Services/SupabaseManager.swift`
- **Service role key:** ⚠️ NIET in de app — alleen in dashboard/backend

---

## Nog te bouwen (latere fase)

- **Betalingen** — nu display-only in de app (`Config.enableRealPayments = false`).
- **VOG- en intake-status** synchroniseren met `buddy_profiles` (`vog_valid`, `intake_done`).
