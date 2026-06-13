# Fase D — Locatie

## Audit
- Taken kregen hun coördinaat van `elderlyUser.coordinate`; bij ontbrekend/
  gedeeld default-punt stapelen aanvragen op één plek.
- `ElderlyUser.coordinate` was `let` → niet bij te werken na geocoding.
- Adres opslaan (EditProfileSheet) zette wél het adres, maar nooit een coördinaat.
- Info.plist-locatierechten: `NSLocationWhenInUseUsageDescription` staat al in
  de build-settings en is Nederlands — geen wijziging nodig.

## Geleverd
- `GeocodingService` (CLGeocoder, geen API-key) — adres → coördinaat, voegt
  "Nederland" toe voor eenduidige resultaten (`ProfileService.swift`).
- `ProfileService.updateElderlyAddress(...)` — persisteert adres + lat/long met
  `.update()` (rij bestaat al via signup-trigger; géén upsert i.v.m. RLS).
- `ElderlyUser.coordinate` is nu `var`.
- `AppState.updateCoordinateFromAddress(_:forFamilyElderly:)` — geocodeert en
  werkt de coördinaat van het juiste profiel bij (eigen of actieve gekoppelde
  oudere), persisteert in live-modus voor het **eigen** elderly-profiel
  (familie-namens mag elderly_profiles niet schrijven onder RLS — bewust).
- EditProfileSheet roept dit aan bij opslaan, voor zowel de oudere zelf als de
  familie-namens-flow → aanvragen staan op het echte adres en stapelen niet.
- Buddy-kaart centreert op de gebruikerslocatie met Amsterdam-fallback; pins
  staan op `task.coordinate`.

## Getest
`xcodebuild -scheme "Buddy Care" -destination 'generic/platform=iOS Simulator'`
→ **BUILD SUCCEEDED**.
