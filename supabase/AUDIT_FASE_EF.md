# Fase E — Navigatie & Nederlands

- Enige zichtbare Engelse UI-tekst was **"Wallet"** → vertaald naar
  **"Portemonnee"** (tab-label, navbar-titel, hero-label). Type-/structnamen
  (`WalletView`, …) blijven Engels conform §4.
- Alle overige tab-labels, navbar- en navigationTitles gecontroleerd: Nederlands.
- Kleine consistentie-fix: buddy-tab tag 3 → 2.
- Presentaties gebruiken al detents + drag indicators; navigatie is consistent.

**Build:** BUILD SUCCEEDED.

---

# Fase F — Inloggen + echte persistentie naast mock

## Auth
- **Nederlandse foutmeldingen** bestonden al (`friendlyError`: verkeerde
  inlog, e-mail niet bevestigd, al geregistreerd, zwak wachtwoord, netwerk,
  rate-limit) — geverifieerd.
- **Rol-toewijzing bij registratie** via metadata + `handle_new_user`-trigger —
  geverifieerd.
- **Nieuw: wachtwoord-reset** — `AuthService.resetPassword`, plus
  "Wachtwoord vergeten?" op het inlogscherm met een bevestigingsmelding.

## Persistentie in live-modus (mock blijft zichtbaar, §1.3)
Flows blijven lokaal werken (demo + directe UI) en schrijven in live-modus
daarnaast naar Supabase:
- **Buddy-beschikbaarheid** → `buddy_profiles.is_available_now`
  (toggles in kaart + profiel lopen nu via `setBuddyAvailable`).
- **Eigen aanvraag plaatsen** (oudere) → `tasks` incl. lat/long; de DB-id wordt
  teruggekoppeld op de lokale taak (`ServiceTask.dbId`).
- **Telefoon + adres** (eigen profiel) → `profiles.phone_number` /
  `elderly_profiles` (adres + gegeocodeerde coördinaat, `.update()`).
- **Meldingsvoorkeuren + consent** → al in Fase B.

## Gating (geverifieerd)
Buddy-onboarding doorloopt VOG (stap 3) **én** intake (stap 4) **én** de Premium-
stappen (ZZP/bank/tarief/contract) vóór `isOnboardingComplete`; de
`fullScreenCover` blokkeert de buddy-schil tot dat klaar is. ZZP mag "nog niet".

## Bewust begrensd (eerlijk)
De buddy-accept/onderweg/afrond/review-keten draait nog op de lokale
demo-matching (lokale taak-ids matchen geen DB-rijen). Volledige live-koppeling
daarvan vereist een echte data-laadlaag (taken/profielen uit Supabase in de
schillen laden) — een aparte, grotere stap. De backend (RLS, RPC's, earnings-
insert) staat er klaar voor; `dbId` op `ServiceTask` is de haak om dit later in
te vullen.

**Build:** BUILD SUCCEEDED.
