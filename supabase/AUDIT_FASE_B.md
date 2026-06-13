# Fase B — Voorkeuren (meldingen + privacy/consent)

Toggles waren cosmetisch (lokale `@State`, verdwenen bij navigeren) en privacy/
consent bestond niet. Nu echt opgeslagen in Supabase en consistent getoond.

## Wat ontbrak

- **Meldingen:** `ElderlyProfileView` (`@State notificationsEnabled`) en
  `FamilyProfileView` (`@State notifyOnVisit/SOS/Review`) waren niet gekoppeld
  aan opslag. Buddy en admin hadden helemaal geen meldingen-toggle.
- **Privacy/consent:** geen UI en geen opslag; `analytics_record()` verzamelde
  zonder toestemming.

## Wat is gebouwd

**Backend** — `migrations/0002_fase_b_voorkeuren.sql` (idempotent):
- `notification_preferences` (push_enabled, visit_updates, new_tasks_nearby,
  sos_alerts, monthly_report) + RLS (eigen rij: select/insert/update).
- `analytics_consent` (consented, default FALSE = opt-in) + RLS.
- `updated_at`-triggers.
- `analytics_record()` herschreven met **consent-gate**: zonder toestemming
  wordt een event server-side genegeerd.

**Swift** (geen nieuwe bestanden — bestaande uitgebreid):
- DTO's `DBNotificationPreferences`, `DBAnalyticsConsent`
  (`SupabaseManager.swift`).
- `PreferencesService` met fetch/upsert (`ProfileService.swift`); upsert op
  `user_id` zodat het werkt of de rij nu bestaat of niet.
- `NotificationPreferences`-struct (`NotificationModels.swift`).
- `AppState`: `notificationPrefs`, `analyticsConsentGiven`, `loadPreferences()`
  (bij login, alleen live-modus), `updateNotificationPrefs`, `setAnalyticsConsent`,
  binding-fabrieken, en `deliverPush()` dat (mock-)pushes filtert op voorkeur
  (SOS gaat altijd door; `Config.enableRealPushNotifications` blijft hoofd-
  schakelaar). Alle bestaande `MockPushService().send` calls lopen nu via
  `deliverPush`.
- Design-system: `BCDisclosureSection` (rustige, ingeklapte sectie),
  `BCToggleRow`, `BCPrivacySection` (identiek op elke pagina).
- Alle vier profielpagina's (elderly/buddy/family/admin) tonen Meldingen én
  Privacy nu in **ingeklapte disclosure-secties**, identiek gestyled.

## Gedrag

- **Demo-modus:** voorkeuren blijven puur lokaal (geen netwerk) — conform §1.3.
- **Live-modus:** laden bij login, opslaan bij elke wijziging.

## Getest

`xcodebuild -scheme "Buddy Care" -destination 'generic/platform=iOS Simulator'`
→ **BUILD SUCCEEDED**.

## Nog open (latere fase)

- Er worden nog geen analytics-events vanuit de app verstuurd; de consent-keuze
  wordt bewaard en server-side gerespecteerd zodra dat wel gebeurt.
- Echte APNs-pushregistratie/-deregistratie volgt wanneer
  `enableRealPushNotifications` aangaat (push-laag is nu mock).
