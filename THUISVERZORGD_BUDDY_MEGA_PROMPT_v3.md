# THUISVERZORGD — BUDDY PLATFORM MEGA PROMPT v3 (Betaalde Buddies)

> Feed this **entire file** to Claude Code in a **fresh, empty GitHub repository** to autonomously build the new Thuisverzorgd app from scratch.
> Version: 3.0 · Target: iOS 17+ SwiftUI · Mode: Autonomous execution · This is a NEW standalone project with **zero** overlap with any previous Thuisverzorgd/Buddie Care codebase.

---

## PART 0 — HOW TO EXECUTE THIS PROMPT

You are operating as an **autonomous Claude Code agent** inside a brand-new, empty repository. Build the complete app described below from scratch. Do not pause for clarification; when a detail is ambiguous, make the best reasonable call and document it with a `// DECISION:` comment.

### Ground rules
- **Greenfield**: This repo is empty (or contains only a README/.gitignore). Create a fresh Xcode SwiftUI project structure. Do **not** copy or reference any prior codebase.
- **Mock-first, local-only**: No backend, no network calls, no API keys, no Supabase. All data lives locally via **SwiftData**. Every place that *would* call an external service (payments, push, SMS, maps geocoding) is mocked with a clearly marked `// TODO[real-integration]:` comment.
- **No payments yet**: Money is **displayed** (amounts owed, buddy earnings, platform fee) but **never charged**. A global flag `Config.enableRealPayments = false` gates all payment UI behind a "Betaling volgt later in de app" placeholder.
- **Low-threshold + light vetting**: Onboarding is deliberately short, BUT a Buddy must (a) submit a **VOG** (Verklaring Omtrent Gedrag) and (b) complete a **short intakegesprek** (intake conversation) before they go live and appear in matching. There is still NO in-app ID-document scan / KYC and NO selfie/QR gate — VOG and intake are **mocked** (status flags + a scheduled call), marked `// TODO[real-integration]:`. Trust is reinforced by reviews, ratings, profiles, optional KvK, plus the VOG + intake.
- **Language**: Code, types, and comments in **English**. All user-visible UI strings in **Dutch**, wrapped in `String(localized:)` so i18n works later.
- **Commit cadence**: One `git commit` per numbered build step in PART 13. Message format: `[step N] short description`. Commit working, compiling code at each step.
- **Compiles at every step**: Never leave the project in a non-compiling state at a commit boundary.

### Stack decisions (already made — do not deviate)
- SwiftUI + the iOS 17 **`@Observable`** macro for app state (no TCA, no Combine boilerplate).
- **SwiftData** for all local persistence (this is our "backend" for the MVP).
- **MapKit** for the buddy task map and routing display.
- **SF Symbols** for icons; custom fonts optional (system font is fine to start).
- **No third-party dependencies** in the MVP.

---

## PART 1 — VISION & PRODUCT

**Product name:** Thuisverzorgd
**Tagline:** *"Een vertrouwde buddy om de hoek."*
**Bundle ID:** `nl.thuisverzorgd.buddy`
**Minimum iOS:** 17.0
**Positioning:** Ouderen-first, maar open voor iedereen die hulp, gezelschap of een klusje gedaan wil hebben.

### The problem
Veel ouderen wonen zelfstandig thuis maar hebben regelmatig behoefte aan hulp die níet onder professionele zorg valt: gezelschap, boodschappen, tuinieren, hond uitlaten, hulp met de computer, vervoer naar een afspraak, kleine klusjes. Professionele zorg is duur en heeft hier geen tijd voor; familie woont niet altijd dichtbij; vrijwilligers zijn onbetrouwbaar beschikbaar. Tegelijk zijn veel mensen bereid om voor betrouwbare hulp te betalen.

### The solution
Thuisverzorgd is een **marktplaats** waarop mensen eenvoudig een betrouwbare **Buddy** boeken voor praktische ondersteuning en welzijn. De Buddy is **geen zorgverlener**, levert **geen medische handelingen**, en helpt bij het dagelijks leven. Vergelijk: *Uber* voor vervoer, *Helpling* voor schoonmaak, *Werkspot* voor klusjes — maar gericht op welzijn en het dagelijks leven, met ouderen als kern.

### Business model (display-only in MVP)
- De klant betaalt rechtstreeks voor de Buddy (uurtarief, typisch **€18–25/uur**).
- Thuisverzorgd rekent een **platformfee** (standaard **€5/uur**, instelbaar in `Config`).
- Voorbeeld: klant betaalt €25/u → Buddy ontvangt €20 → Thuisverzorgd €5.
- **Geen** afhankelijkheid van gemeenten, subsidies, zorgverzekeraars, WMO of PGB. Elke klant = directe omzet.
- In de MVP worden bedragen alleen **getoond**, niet geïnd.

### Explicitly OUT of scope (do NOT build these)
These existed in older concepts and must **not** appear anywhere:
- ❌ Verzekering / aansprakelijkheidsverzekering als onboarding-stap of product
- ❌ WMO, PGB, SVB, gemeente-subsidie, "Zorg in Natura", keukentafelgesprek, declaraties
- ❌ Zorginstellingen / Cordaan / organisatie-lidmaatschappen
- ❌ In-app ID-document scan / KYC, selfie-check, QR-deurcode  *(NB: VOG én intakegesprek zijn er WÉL — zie PART 6, alleen gemockt)*
- ❌ Service levels (0–4), certificeringen, e-learning/cursussen, medische handelingen (BIG)
- ❌ Echte betaling / Stripe / wallet met saldo-opname

---

## PART 2 — THE FOUR ROLES

The app has a role selector on first launch (after splash). A user picks one role per device session for the MVP (no cross-role account switching needed beyond Family→linked clients).

1. **Client (Klant)** — *primary persona: oudere; secondary: iedereen.* Gets **free** access, requests help, sees matched buddy, tracks the visit, pays (placeholder), reviews. Onboarding is minimal.
2. **Buddy** — a ZZP'er (student, gepensioneerde, buurtbewoner, parttimer) who offers services, sees open tasks on a map, accepts, checks in, completes, gets paid (placeholder) and rated. Onboarding is **low-threshold**.
3. **Family (Familielid)** — child/relative of a client. Links to one or more clients via a 6-digit code, can **book on their behalf**, and sees an activity timeline. Strong selling point toward "kinderen van ouderen".
4. **Admin** — operator (you). Read-mostly oversight: list of buddies, clients, all tasks, simple moderation (flag/deactivate a buddy), and headline stats. **No billing/WMO** — just operational overview.

### Personas (for mock data + tone)
- **Oma Riet** (78, Rotterdam-Zuid, weduwe, kinderen in Brabant) — wil gezelschap, hulp met boodschappen en vervoer naar de dokter. Wil simpel, groot, vertrouwd.
- **Buddy Aiyla** (21, student, Rotterdam) — vrije middagen, wil bijverdienen als ZZP'er, pakt klussen op de kaart.
- **Buddy Henk** (67, gepensioneerd, handig) — doet tuinklusjes en kleine reparaties in de buurt.
- **Familielid Sandra** (52, dochter van Riet, druk, woont op afstand) — boekt namens Riet, wil zien dat er iemand is geweest.

---

## PART 3 — SERVICE MODEL (FLAT — NO LEVELS)

No levels, no certifications. A flat catalog of services grouped into 4 categories. A Buddy ticks which services they offer; a Client picks a service when requesting help. Matching is by **service offered + distance + rating/availability** only.

```
enum ServiceCategory: String, CaseIterable, Codable {
    case social        // Sociaal
    case practical     // Praktisch
    case digital       // Digitaal
    case accompaniment // Begeleiding & vervoer
}
```

Each category contains concrete services (name in Dutch, an SF Symbol, a suggested hourly rate used to prefill the buddy's tariff):

**Sociaal** (`person.2.fill`)
- Koffie drinken & gesprek · Samen wandelen · Samen sporten · Spelletjes spelen · Samen koken

**Praktisch** (`hammer.fill`)
- Boodschappen doen · Hond uitlaten · Tuinieren · Kleine klusjes in huis · Administratieve hulp

**Digitaal** (`laptopcomputer`)
- Telefoon instellen · E-mail uitleggen · Videobellen · Apps installeren · Algemene computerhulp

**Begeleiding & vervoer** (`car.fill`)
- Vervoer naar afspraak · Bezoek aan familie · Samen winkelen · Begeleiding bij activiteiten

Model each concrete service as a `BuddyService` value (id, displayName, category, sfSymbol, suggestedHourlyRateCents). Provide a single `ServiceCatalog.all` static list. Suggested rates fall in **€18–25/uur**; default platform fee **€5/uur**.

---

## PART 4 — DATA MODELS (SwiftData)

Define `@Model` classes (SwiftData) for persistence. Keep models clean — **no** level, certification, organization, VOG, insurance, or WMO fields anywhere.

```
@Model final class ClientProfile {
    var id: UUID
    var firstName: String
    var lastName: String
    var phoneNumber: String?
    var address: String?            // optional; used for matching/distance
    var latitude: Double?
    var longitude: Double?
    var notes: String               // e.g. "Bel aan bij de achterdeur"
    var favoriteBuddyIDs: [UUID]
    var familyMemberIDs: [UUID]
    var createdAt: Date
}

@Model final class BuddyProfile {
    var id: UUID
    var firstName: String
    var lastName: String
    var phoneNumber: String?
    var bio: String
    var city: String
    var latitude: Double?
    var longitude: Double?
    var photoSystemName: String     // SF Symbol placeholder until real photos
    var kvkNumber: String?          // OPTIONAL — ZZP nicety, not required, not verified
    var offeredServiceIDs: [UUID]   // which BuddyService ids they offer
    var hourlyRateCents: Int        // buddy sets own ZZP rate
    var maxDistanceKm: Int
    var isAvailableNow: Bool
    var ratingAverage: Double
    var totalTasks: Int
    var isActive: Bool              // admin can deactivate
    var vogStatus: VettingStatus   // VOG: notSubmitted / submitted / approved (mocked)
    var vogSubmittedAt: Date?
    var intakeStatus: VettingStatus // intakegesprek: notSubmitted(=notScheduled) / submitted(=scheduled) / approved(=completed)
    var intakeDate: Date?
    var createdAt: Date
    // A buddy is "live" (appears in matching) only when isActive && vogStatus == .approved && intakeStatus == .approved.
    // For the demo, seed example buddies as fully approved so the marketplace has content immediately.
}

enum VettingStatus: String, Codable {
    case notSubmitted, submitted, approved
}

@Model final class FamilyProfile {
    var id: UUID
    var firstName: String
    var lastName: String
    var relationship: String        // "Dochter van Riet"
    var linkedClientIDs: [UUID]
    var createdAt: Date
}

@Model final class HelpTask {
    var id: UUID
    var clientID: UUID
    var clientName: String
    var clientAddress: String?
    var latitude: Double?
    var longitude: Double?
    var serviceID: UUID             // chosen BuddyService
    var serviceName: String         // denormalized for display
    var category: String            // ServiceCategory.rawValue
    var note: String
    var timing: TaskTiming          // .now / .today(hour) / .scheduled(Date)
    var estimatedHours: Double      // default 1.0
    var hourlyRateCents: Int        // taken from matched buddy or suggested
    var platformFeeCents: Int       // Config.platformFeeCentsPerHour * hours
    var status: TaskStatus
    var assignedBuddyID: UUID?
    var assignedBuddyName: String?
    var assignedBuddyRating: Double?
    var etaMinutes: Int?
    var createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var completionNote: String?
    // Payment is display-only; no charge happens.
}

enum TaskStatus: String, Codable {
    case open, accepted, onTheWay, inProgress, completed, cancelled
}

enum TaskTiming: Codable {        // use enum with associated values; Codable conformance
    case now
    case today(hour: Int)
    case scheduled(date: Date)
}

@Model final class Review {
    var id: UUID
    var taskID: UUID
    var buddyID: UUID
    var clientName: String
    var stars: Int                  // 1...5
    var comment: String
    var createdAt: Date
}
```

`AppState` (an `@Observable` class injected via `.environment`) holds: current role, current user id, transient UI state (toasts, active flow), and convenience methods that read/write SwiftData via a `ModelContext`. Keep a `DemoSeeder` that, on first launch, seeds the personas and a handful of open tasks so every screen has content.

---

## PART 5 — SCREENS PER ROLE

### App shell
- **SplashView** → animated logo, 1.2s.
- **RoleSelectionView** → four big cards: Klant · Buddy · Familielid · Beheer.
- **LoginView** → simplified: name + phone (no password needed in MVP; mock "login"). For Client/Family, even simpler. `// TODO[real-integration]: real auth`.

### Client (Klant)
- **ClientHomeView** — warm greeting, big primary button **"Hulp vragen"**, an active-task banner when a buddy is assigned/on the way, list of recent buddies, easy access to favorites. Large text, high contrast, minimal chrome.
- **RequestHelpFlow** — 3 steps: (1) pick **category → service**, (2) pick **timing** (nu / vandaag om… / op datum) + estimated hours, (3) **confirm** with optional note and a clear price summary ("Richtprijs: €X/u · geschat €Y · betaling volgt later in de app").
- **MyBuddiesView** — favorites + recently worked with; tap to rebook or set as vaste buddy.
- **BuddyProfileSheet** — buddy photo placeholder, bio, services, rating, reviews, "Kies als vaste buddy".
- **TaskTrackingView** — live status of the current task (open → matched → onderweg (ETA) → bezig → afgerond).
- **PaymentPlaceholderView** — shows what *would* be paid; "Betalen" button disabled with note. Gated by `Config.enableRealPayments`.
- **ReviewView** — 1–5 sterren + comment, after completion.
- **ClientProfileView** — personal info, linking code to share with family, logout.

### Buddy
- **BuddyTabView** — tabs: Kaart · Klussen · Verdiensten · Profiel.
- **BuddyMapView** — MapKit with open tasks as pins near the buddy; tap a pin → **TaskDetailSheet** (service, distance, timing, note, price split: "Jij ontvangt €X, platformfee €Y") → **"Klus aannemen"**.
- **MyJobsView** — accepted/active/completed jobs list.
- **CheckInFlow** — **simplified**: a single "Ik ben aangekomen" confirm with optional GPS-distance display (mock geocoding). NO selfie, NO QR. Sets status → inProgress. A "Klus afronden" action with completion note → completed.
- **EarningsView** — list of completed jobs with amounts the buddy *earned* (display-only), running total. Clear note: payouts come later.
- **BuddyProfileView** — bio, offered services (editable), hourly rate (editable), max distance, availability toggle, optional KvK, reviews received, logout.
- **BuddyOnboardingFlow** — see PART 6.

### Family (Familielid)
- **FamilyTabView** — tabs: Overzicht · Tijdlijn · Profiel.
- **FamilyDashboardView** — switcher across linked clients; per client: request help on their behalf, see active task, recent buddies, satisfaction.
- **FamilyLinkingView** — enter a 6-digit code (from the client's profile) to link.
- **ActivityTimelineView** — chronological visits (wie, wanneer, welke dienst, beoordeling).
- **FamilyProfileView** — linked clients, logout.

### Admin (Beheer)
- **AdminTabView** — tabs: Overzicht · Buddies · Klussen.
- **AdminOverviewView** — headline stats: # actieve buddies, # klanten, # open klussen, # afgeronde klussen deze maand, totale (getoonde) omzet & platformfee.
- **AdminBuddiesView** — list of buddies with rating/total tasks and their **VOG-** and **intake-status**; tap to view; **activeren/deactiveren** toggle (moderation) and **VOG/intake goedkeuren** actions (sets the respective `VettingStatus` → `.approved`). A buddy only goes live after both are approved. Show a "wachtend op goedkeuring" filter.
- **AdminTasksView** — all tasks with filters by status; tap for detail. No billing finalize, no CSV/WMO.

---

## PART 6 — BUDDY ONBOARDING (LOW-THRESHOLD + VOG & INTAKE, ZZP)

Deliberately short and friendly — no insurance step, no in-app ID/KYC scan, no selfie. But a buddy **does** submit a VOG and complete a short intakegesprek before going live. Goal: motivated buddy fully signed up in minutes; "live" status follows once VOG + intake are approved (both mocked).

1. **Welkom** — "Word Buddy. Help mensen in de buurt en verdien bij als zelfstandige."
2. **Account** — voornaam, achternaam, e-mail, telefoon.
3. **Profiel** — korte bio, woonplaats/postcode, (foto-placeholder via SF Symbol kiezer).
4. **ZZP-bevestiging** — uitleg + checkbox: *"Ik werk als zelfstandige (ZZP). Ik ben zelf verantwoordelijk voor mijn belastingaangifte en eventuele verzekering."* Optioneel veld: **KvK-nummer** (mag leeg, niet geverifieerd).
5. **Diensten** — kies uit de `ServiceCatalog` welke diensten je aanbiedt (multi-select per categorie).
6. **Beschikbaarheid & afstand** — beschikbaar nu (toggle) + max reisafstand (km).
7. **Uurtarief** — stel je tarief in (prefill = hoogste suggested rate van gekozen diensten, binnen €18–25). Toon de split: "Klant betaalt €X, jij ontvangt €(X − fee)".
8. **VOG aanvragen** — leg kort uit waarom: *"Voor het vertrouwen van klanten vragen we een Verklaring Omtrent Gedrag (VOG)."* Een knop **"VOG aanvragen / uploaden"** zet `vogStatus = .submitted` (mock; `// TODO[real-integration]: Justis/VOG-flow`). Toon de status duidelijk.
9. **Intakegesprek plannen** — *"We doen een kort kennismakingsgesprek (telefonisch, ~10 min)."* Een knop **"Plan intakegesprek"** kiest een (mock) datum/tijd en zet `intakeStatus = .submitted` (= scheduled).
10. **Huisregels** — korte gedragscode (respect, betrouwbaarheid, geen medische handelingen) + akkoord.
11. **Bijna klaar** — samenvatting + status: *"Je account is aangemaakt. Zodra je VOG én intakegesprek zijn goedgekeurd, sta je live en kun je klussen aannemen."* De buddy mag de app/kaart alvast verkennen (read-only) maar verschijnt nog niet in matching tot `vogStatus == .approved && intakeStatus == .approved`. (Demo: een `Config.demoAutoApproveVetting` flag of admin-actie kan beide direct goedkeuren zodat je de flow kunt tonen.)

Client & Family onboarding are even lighter: name + phone, optional address (client) → straight into the app. Free, no barriers.

---

## PART 7 — CORE FLOWS

### Request → Match → Complete
1. Client (or Family on behalf) creates a `HelpTask` (status `.open`) via RequestHelpFlow.
2. **MatchingService.rankBuddies(for:)** ranks **live** buddies (hard filter: `isActive && vogStatus == .approved && intakeStatus == .approved`) by: offers this service (hard filter) → within `maxDistanceKm` (hard filter) → distance ascending → ratingAverage descending → availableNow. Returns top candidates.
3. Buddy sees the open task on the map, taps **"Klus aannemen"** → status `.accepted`, assign buddy + ETA (mock 6–15 min). Client's TaskTrackingView updates.
4. Buddy taps **"Ik ben onderweg"** → `.onTheWay`. Then **"Ik ben aangekomen"** (CheckInFlow, simplified) → `.inProgress`, `startedAt` set.
5. Buddy taps **"Klus afronden"** + note → `.completed`, `completedAt` set, amounts finalized for *display*.
6. Client gets a review prompt → creates a `Review`; buddy's `ratingAverage` + `totalTasks` recompute.
7. PaymentPlaceholderView shows the amount; no charge. `// TODO[real-integration]: payment provider`.

### Cancellation
- Buddy can release an accepted task before arrival → back to `.open`, buddy cleared, re-rank.
- Client/Family can cancel an open or accepted task → `.cancelled`.

### Demo helpers
- Provide an **auto-accept** demo toggle in `Config` (`Config.demoAutoAcceptSeconds`) so that when a client requests help, a mock buddy auto-accepts after N seconds — handy for showcasing the client flow without a second device. Keep it clearly behind a demo flag.

---

## PART 8 — TRUST & SAFETY (WITHOUT ID CHECKS)

Trust is built socially, not by gatekeeping:
- **Reviews & ratings** front and center on every buddy profile.
- **Profile completeness** signal (foto, bio, # diensten, # afgeronde klussen).
- **Vaste buddy** kiezen — clients can favorite and rebook a trusted buddy.
- **Optional KvK** number shown as a small "ZZP" badge when present.
- **Admin moderation** — deactivate a buddy; deactivated buddies disappear from matching.
- **Report** action on a buddy profile / completed task (mock; stores a flag for admin).
- Onboarding gedragscode sets expectations. Show a one-line disclaimer: *"Buddies zijn zelfstandigen. Thuisverzorgd levert geen medische zorg."*

---

## PART 9 — PRICING & PAYMENT (DISPLAY-ONLY)

`Config` (a plain enum of static constants):
```
enum Config {
    static let enableRealPayments = false
    static let platformFeeCentsPerHour = 500     // €5/u
    static let minHourlyRateCents = 1800          // €18
    static let maxHourlyRateCents = 2500          // €25
    static let demoAutoAcceptSeconds: Int? = 5    // nil to disable
    static let demoAutoApproveVetting = true      // demo: auto-approve VOG + intake on signup so a buddy goes live instantly
}
```
Helpers compute, for a task: client total = rate × hours; buddy earns = (rate − fee) × hours; platform = fee × hours. Everywhere money appears, format with a Dutch euro formatter and, when `enableRealPayments == false`, append/disable with "Betaling volgt later in de app".

---

## PART 10 — DESIGN SYSTEM

Create a small design system folder (BCColors / BCTypography / BCComponents):
- **Palette**: warm, trustworthy. A calm primary (deep teal/navy), a friendly accent (warm green), soft neutrals, clear semantic colors. Define light-mode first; support dark mode.
- **Typography**: large, legible (Dynamic Type friendly). Generous sizes for Client screens specifically (ouderen-first).
- **Components**: `BCPrimaryButton`, `BCCard`, `BCBadge`, `BCAvatar` (SF Symbol based), `BCRatingStars`, `BCSectionHeader`, `BCEmptyState`, `BCToast`.
- **Accessibility**: every interactive element has an accessibility label; minimum 44pt targets; Client screens default to a larger text scale.

---

## PART 11 — PROJECT STRUCTURE

```
ThuisverzorgdBuddy/
├── App/
│   ├── ThuisverzorgdApp.swift        // @main, SwiftData ModelContainer, AppState
│   ├── AppState.swift                // @Observable
│   ├── Config.swift
│   ├── RootView.swift                // splash → role select → role shell
│   ├── RoleSelectionView.swift
│   └── LoginView.swift
├── Models/
│   ├── Models.swift                  // @Model classes + enums
│   ├── ServiceCatalog.swift          // BuddyService + ServiceCategory + catalog
│   └── DemoSeeder.swift              // seeds personas + tasks
├── Services/
│   ├── MatchingService.swift
│   ├── PricingService.swift
│   └── MockNotificationService.swift // mock push/SMS (prints + toasts)
├── Client/        // all Client screens
├── Buddy/         // all Buddy screens + onboarding
├── Family/        // all Family screens
├── Admin/         // all Admin screens
├── Shared/        // SplashView, reusable sheets
├── DesignSystem/  // BCColors, BCTypography, BCComponents
└── Assets.xcassets/
```

---

## PART 12 — TECH NOTES
- Use SwiftData `@Query` in views where natural; otherwise read via `AppState` helpers holding a `ModelContext`.
- `TaskTiming` needs custom `Codable` (associated values). Store it on `HelpTask` via a `Codable` wrapper or split into `timingKind` + `timingValue` columns if SwiftData balks at the enum — pick whichever compiles cleanly and note the `// DECISION:`.
- Geocoding/distance: use stored lat/long on profiles/tasks and a simple haversine in `MatchingService`. If lat/long missing, fall back to a mocked distance. `// TODO[real-integration]: CLGeocoder`.
- Maps: `Map` (iOS 17 MapKit SwiftUI) with annotations for open tasks.
- Keep everything offline-capable; the app must run fully in the simulator with no setup.

---

## PART 13 — BUILD ORDER (commit per step)

1. **Project scaffold** — Xcode SwiftUI app, folder structure, `Config`, design system stubs, app entry with SwiftData container. App launches to a placeholder.
2. **Models & catalog** — all `@Model` classes, enums, `ServiceCatalog.all`, `PricingService`. Unit-test pricing math.
3. **App shell** — Splash → RoleSelection → per-role shells (empty tabs) → simplified Login. Role persists for the session.
4. **Demo seed** — `DemoSeeder` populates personas + a few open tasks on first run.
5. **Buddy onboarding** — full low-threshold flow (PART 6) incl. VOG-aanvraag + intakegesprek-stappen, writes a `BuddyProfile` with `vogStatus`/`intakeStatus`; honors `Config.demoAutoApproveVetting`.
6. **Buddy map & jobs** — BuddyMapView + TaskDetailSheet + accept; MyJobsView; CheckInFlow (simplified); complete + note.
7. **Client home & request flow** — ClientHomeView + RequestHelpFlow + TaskTrackingView; creates `HelpTask`; wire MatchingService; demo auto-accept.
8. **Reviews & buddy profiles** — ReviewView, BuddyProfileSheet, ratings recompute, MyBuddies/favorites/vaste buddy.
9. **Earnings & payment placeholder** — EarningsView (buddy), PaymentPlaceholderView (client), all display-only.
10. **Family role** — linking via 6-digit code, dashboard (book on behalf), activity timeline.
11. **Admin role** — overview stats, buddies list + activate/deactivate + VOG/intake goedkeuren (+ "wachtend op goedkeuring" filter), tasks list + filters; report flags surface here.
12. **Polish** — accessibility pass (Dynamic Type, labels), empty states, toasts, dark mode, copy review (all Dutch, warm, ouderen-first), final disclaimers. README with how to run.

---

## PART 14 — DEFINITION OF DONE
- App compiles and runs in the iOS 17 simulator with **no** external setup.
- A reviewer can, end-to-end: pick Client → request "Boodschappen doen" → see a buddy auto-accept → watch status to completed → leave a review; then pick Buddy → onboard → see open tasks → accept → check in → complete → see earnings (display-only); then Family → link a client → book on their behalf → see it on the timeline; then Admin → see stats and deactivate a buddy.
- **Zero** references anywhere to: verzekering, in-app ID-check/KYC, selfie/QR check-in, levels, certificering, cursus, WMO, PGB, gemeente, zorginstelling, Cordaan, Zorg in Natura, BIG.  *(VOG en intakegesprek mogen er wél zijn — gemockt.)*
- No real payment is ever charged; all money is clearly labelled as display-only.
- All user-facing strings are Dutch via `String(localized:)`; all code/comments English.
- README documents the role flows and the `// TODO[real-integration]:` seams (auth, payments, push, geocoding, real photos, backend sync).

---

## PART 15 — TONE & COPY GUIDELINES
- Warm, simple, respectful. Short sentences. Avoid jargon and anything clinical.
- Client screens: extra large, reassuring, one clear action per screen.
- Buddy screens: snappy, opportunity-focused ("3 klussen bij jou in de buurt").
- Never imply medical care or guarantees. Buddies are zelfstandigen who help with daily life and welzijn.

— END OF MEGA PROMPT v3 —
