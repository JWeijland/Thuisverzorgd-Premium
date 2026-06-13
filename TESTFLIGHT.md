# Thuisverzorgd Premium — testers aan de slag

## Voordat je begint (eenmalig, in Supabase)
Draai in de SQL Editor in deze volgorde:
1. `supabase/schema.sql`
2. `supabase/analytics.sql`
3. `supabase/migrations/0001_fase_a_backend_consistency.sql`
4. `supabase/migrations/0002_fase_b_voorkeuren.sql`
5. `supabase/migrations/0003_fase_c_admin.sql`

Zet daarna **Authentication → Email** aan. Voor een interne testronde mag
*Confirm email* uit; voor een publieke beta aan (dan moeten testers hun e-mail
bevestigen). Zie `supabase/SUPABASE_SETUP.md` voor de rest (realtime, OTP, Apple).

## Twee manieren om de app te gebruiken
- **Demo overslaan** — op het inlogscherm onderaan "Demo overslaan" → kies een
  rol. Je ziet direct de mock-data en kunt alle schermen verkennen zonder account.
  Demo-data blijft altijd zichtbaar.
- **Echt account** — Registreren met naam, rol (oudere/buddy/familie),
  e-mail + wachtwoord. Wachtwoord vergeten? Gebruik de link op het inlogscherm.

## Wat in live-modus echt wordt opgeslagen
- Account + rol (bij registratie), sessieherstel, uitloggen.
- Meldingsvoorkeuren en privacy/consent (profielpagina, ingeklapte secties).
- Buddy-beschikbaarheid.
- Profiel: telefoon + adres (adres wordt gegeocodeerd naar een kaartlocatie).
- Een aanvraag die je als ingelogde oudere zelf plaatst (incl. locatie).

## Rollen kort
- **Oudere** — hulp vragen, buddies, betalingen (display-only), profiel.
- **Buddy** — kaart met aanvragen, portemonnee/verdiensten, profiel. Live na
  VOG **én** intake (onboarding doorlopen; ZZP mag "nog niet" zijn).
- **Familie** — gekoppelde ouderen beheren via welkomstcode, activiteit, profiel.
- **Admin** — overzicht/facturatie (display-only), telefonische aanvraag,
  beheer (dashboard, intakes/VOG, koppelcodes, gebruikers), instellingen.

## Belangrijk
- **Betalingen zijn display-only** — bedragen worden getoond, niet geïnd
  (`Config.enableRealPayments = false`). Mollie komt later, zonder UI-wijziging.
- Mock-/demo-data blijft naast je echte data zichtbaar.
