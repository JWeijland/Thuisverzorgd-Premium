# Fase G — Recente verbeteringen verifiëren

- **Locatie-fix via geocoding** — gebouwd in Fase D (CLGeocoder, adres → coördinaat,
  `.update()` i.p.v. upsert i.v.m. RLS). ✔
- **Privacy/meldingen-toggles in ingeklapte disclosure-secties** — gebouwd in
  Fase B op alle vier profielpagina's, met echte persistentie. ✔
- **Koppelcode-/partnercode-flow** — backend volledig aanwezig
  (`validateLinkingCode`, `linkFamilyToElderly` met de in Fase A herstelde
  INSERT/UPDATE-policies, `admin_create_linking_code`). De familie-UI gebruikt
  bewust nog de lokale demo-koppeling (mock blijft zichtbaar, §1.3); de
  live-koppeling is service-side klaar. ✔
- **Admin-gebruikersbeheer + blokkade zelf-escalatie** — `admin_set_role`
  blokkeert het wijzigen van de eigen rol; de `prevent_role_self_change`-trigger
  blokkeert rolwijziging vanaf een gewone client. Beheer-UI in Fase C. ✔
- **Geen pool-/team-/competitie-feature** aanwezig (grep leeg). ✔

## Runtime-smoke-test
App gebouwd voor de iPhone 17-simulator, geïnstalleerd en gestart: opent op de
rolkeuze ("Welkom bij Thuisverzorgd"), volledig Nederlands, juiste branding
(navy + groen). Diep doorklikken kon in deze omgeving niet geautomatiseerd
worden (geen rechten om invoer in de Simulator te injecteren).

**Eindbuild:** BUILD SUCCEEDED.
