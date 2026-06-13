# Fase C — Adminschil (mét facturatie)

## Wat ontbrak
- Telefonische aanvraag schreef alleen lokaal (geen DB-write; RLS staat een
  oudere-insert toe, niet een admin-namens-insert).
- Geen dashboard-stats, intake/VOG-beheer, gebruikers-/rolbeheer of koppelcode-
  beheer. Instellingen waren placeholders.
- Facturatie leunde op mock; geen echte bron over rollen heen.

## Backend — `migrations/0003_fase_c_admin.sql` (idempotent)
- `create_task_on_behalf(...)` — SECURITY DEFINER, admin-only namens-insert
  (incl. lat/long).
- `admin_set_intake`, `admin_set_vog`, `admin_set_role`, `admin_create_linking_code`
  — alle admin-only; `admin_set_role` blokkeert het wijzigen van de **eigen** rol.
- `prevent_role_self_change`-trigger aangepast: admins/service-role mogen rollen
  wijzigen, gewone clients niet (zelf-escalatie blijft geblokkeerd).
- `admin_billing`-view (klant betaalt / buddy verdient / 20% fee per regel) en
  `admin_dashboard_stats`-view — beide met `WHERE is_admin()` zodat non-admins
  nul rijen krijgen.

## Swift (bestaande bestanden uitgebreid, geen nieuwe files)
- `AdminService` (RPC-wrappers + `fetchDashboardStats`/`fetchBilling`) in
  `TaskService.swift`; DTO's `DBBillingRow`/`DBDashboardStats`.
- DB-mapping-helpers op `TaskCategory`/`TaskStatus`/`TaskTiming`
  (`Models.swift`) — snake_case ↔ Swift, ook nodig voor Fase F.
- `BuddyUser.vogValid` → `var`, nieuw `var intakeDone` (default true).
- `AppState`: `adminSetVOG/Intake/Role`, `adminCreateLinkingCode`,
  `persistTaskOnBehalf` — lokaal + (live) via RPC.
- Telefonische aanvraag persisteert nu in live-modus.
- Nieuwe **Beheer**-tab (`AdminManagementView`): dashboard-tellingen, intake/VOG-
  goedkeuring, koppelcode-generatie, gebruikers + rolwijziging. Leunt in live op
  de echte views, in demo op de lokale staat (mock blijft zichtbaar).

## Getest
`xcodebuild -scheme "Buddy Care" -destination 'generic/platform=iOS Simulator'`
→ **BUILD SUCCEEDED**.
