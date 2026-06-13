# Audit Fase A — Backend-consistentie

Vergelijking tussen wat de Swift-app aanroept (`Services/*.swift`, DTO's in
`SupabaseManager.swift`) en wat de database toestaat (`schema.sql`,
`analytics.sql`). Alle correcties staan in
`migrations/0001_fase_a_backend_consistency.sql` (idempotent).

## Kritieke gaten (blokkeerden echte writes)

| # | Probleem | Aanroep in code | Oorzaak | Fix |
|---|----------|-----------------|---------|-----|
| 1 | INSERT in `earnings` faalt op RLS | `TaskService.completeTask` (earnings insert) | alleen SELECT-policy op `earnings`, geen INSERT | INSERT-policy `buddy_id = auth.uid()` |
| 2 | INSERT in `family_elderly_links` faalt op RLS | `TaskService.linkFamilyToElderly` | geen INSERT-policy | INSERT-policy `family_id = auth.uid()` |
| 3 | UPDATE `linking_codes.used_at` faalt op RLS | `TaskService.linkFamilyToElderly` (code markeren) | geen UPDATE-policy | UPDATE-policy voor nog-ongebruikte codes |

Deze drie zorgden ervoor dat koppelen via welkomstcode en het vastleggen van
verdiensten in live-modus stil faalden.

## Schema-gaten (kolommen/rol die de app verwacht)

| # | Probleem | Bewijs | Fix |
|---|----------|--------|-----|
| 4 | `user_role` mist `admin` | `UserRole.admin` + volledige `AdminTabView` | `ALTER TYPE ... ADD VALUE IF NOT EXISTS 'admin'` |
| 5 | `tasks` heeft geen coördinaat | `ServiceTask.coordinate`; buddy-kaart toont taken op locatie | `latitude`/`longitude` op `tasks` (gevuld in Fase D) |
| 6 | `buddy_profiles` mist BTW/uurtarief/afstand/ZZP | onboarding-stappen 5,6,7,9 verzamelen dit | `btw_number`, `hourly_rate_cents`, `max_distance_km`, `is_zzp` |

## Beveiliging

| # | Probleem | Fix |
|---|----------|-----|
| 7 | Zelf-escalatie: `profiles`-UPDATE-policy had geen `WITH CHECK`, dus een client kon z'n eigen `role` op `admin` zetten | trigger `prevent_role_self_change` — rolwijziging alleen door service-role |
| 8 | Admin kon niets lezen over rollen heen (RLS beperkt tot eigen rijen) | helper `is_admin()` + read-only admin-SELECT-policies op profiles, elderly/family-profielen, tasks, earnings, links, sos |

## Bewust nog NIET in deze migratie (volgende fases)

- `notification_preferences` + `analytics_consent` tabellen → **Fase B**.
- `create_task_on_behalf` SECURITY DEFINER-RPC (admin telefonische aanvraag) en
  facturatie-view over `tasks`+`earnings`+`profiles` → **Fase C**.
- Persisteren van geocodede coördinaten op profiel/taak (kolommen staan nu
  klaar) → **Fase D**.
- `purchases`/betaalstatus-persistentie voor extra's (display-only) → **Fase F**.

## Niet-blokkerende observaties

- `DBElderlyProfile` decodeert `date_of_birth` niet, terwijl de kolom bestaat —
  geen fout (Supabase negeert niet-gevraagde kolommen), `age` komt nu uit
  mock-data. Meenemen wanneer echte elderly-data gekoppeld wordt (Fase F).
- `DBBuddyProfile` decodeert `offered_services`, `kvk_number`, `avatar_system_name`
  niet; idem — uitbreiden bij het echt laden van buddy-data (Fase F).
- Belangrijkste structurele bevinding voor Fase F: `AppState`-taakacties
  (`requestHelp`, `buddyCompletes`, enz.) muteren **alleen lokale arrays** en
  roepen `TaskService`/`ProfileService` niet aan. De services bestaan en zijn
  correct; ze worden alleen nog niet vanuit de flows gebruikt. Dat is de kern
  van Fase F (echte persistentie naast de mock-data).
