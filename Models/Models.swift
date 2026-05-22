import Foundation
import SwiftUI
import CoreLocation

// MARK: - Service levels

enum ServiceLevel: Int, CaseIterable, Identifiable, Codable {
    case zero = 0
    case one = 1
    case two = 2
    case three = 3
    case four = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .zero: return "Basis Buddy"
        case .one: return "Buddy+"
        case .two: return "Zorgondersteuning"
        case .three: return "Helpende"
        case .four: return "Verpleegkundig"
        }
    }

    var summary: String {
        switch self {
        case .zero: return "Gezelschap, boodschappen, licht huishouden, medicatie herinneren (niet toedienen)"
        case .one: return "Opstaan, toilet begeleiden, aankleden, maaltijden — geen intieme verzorging"
        case .two: return "Wassen (incl. intiem), steunkousen, medicatietoezicht, volledige persoonlijke verzorging"
        case .three: return "Volledige ADL, medicatie toedienen (Helpende Plus), stomazorg, wondverzorging"
        case .four: return "BIG-geregistreerde verpleegkundige taken"
        }
    }

    var color: Color {
        switch self {
        case .zero: return BCColors.level0
        case .one: return BCColors.level1
        case .two: return BCColors.level2
        case .three: return BCColors.level3
        case .four: return BCColors.level4
        }
    }

    var requirementText: String {
        switch self {
        case .zero: return "Onboarding + ID-verificatie + VOG"
        case .one: return "Niveau 0 + Thuisverzorgt interne training (~3u e-learning)"
        case .two: return "Niveau 1 + MBO-deelcertificaat zorg + e-learning + praktijktoets (~8u)"
        case .three: return "MBO niveau 2 diploma Helpende Zorg & Welzijn (of gelijkwaardig)"
        case .four: return "BIG-registratie verpleegkundige (V&V niveau 4/5)"
        }
    }

    var celebrationMessage: String {
        switch self {
        case .zero: return "Je bent klaar als Basis Buddy. Niveau 1 (Buddy+) is nu beschikbaar."
        case .one: return "Geweldig! Je kunt nu helpen met mobiliteit en dagelijkse ondersteuning. Niveau 2 is ontgrendeld."
        case .two: return "Top! Je bent gecertificeerd voor persoonlijke zorgondersteuning. Niveau 3 staat voor je klaar."
        case .three: return "Indrukwekkend! Je beheerst volledige Helpende-zorg. Niveau 4 is nu toegankelijk."
        case .four: return "Uitzonderlijk! Je hebt het hoogste niveau bereikt. Gefeliciteerd!"
        }
    }
}

// MARK: - Task category

enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case companionship
    case groceries
    case medicationReminder
    case bedHelp
    case lightCleaning
    case mealPrep
    case walkOutdoors
    case appointment
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .companionship: return "Gezelschap"
        case .groceries: return "Boodschappen"
        case .medicationReminder: return "Medicatie"
        case .bedHelp: return "Naar bed helpen"
        case .lightCleaning: return "Opruimen"
        case .mealPrep: return "Maaltijd"
        case .walkOutdoors: return "Wandelen"
        case .appointment: return "Begeleiding afspraak"
        case .other: return "Anders"
        }
    }

    var description: String {
        switch self {
        case .companionship: return "Een uurtje koffie, kletsen, samen tv kijken"
        case .groceries: return "Boodschappen halen en opruimen"
        case .medicationReminder: return "Even langskomen voor medicatie-toezicht"
        case .bedHelp: return "Hulp bij naar bed gaan of opstaan"
        case .lightCleaning: return "Lichte opruim- en huishoudklusjes"
        case .mealPrep: return "Maaltijd bereiden of opwarmen"
        case .walkOutdoors: return "Samen een ommetje maken"
        case .appointment: return "Begeleiding naar dokter of apotheek"
        case .other: return "Iets anders waar hulp bij nodig is"
        }
    }

    var icon: String {
        switch self {
        case .companionship: return "cup.and.saucer.fill"
        case .groceries: return "bag.fill"
        case .medicationReminder: return "pills.fill"
        case .bedHelp: return "bed.double.fill"
        case .lightCleaning: return "sparkles"
        case .mealPrep: return "fork.knife"
        case .walkOutdoors: return "figure.walk"
        case .appointment: return "calendar.badge.clock"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var minimumLevel: ServiceLevel {
        switch self {
        case .companionship, .groceries, .lightCleaning, .walkOutdoors, .appointment, .other:
            return .zero
        case .medicationReminder:
            return .zero  // herinneren aan medicatie (≠ toedienen) is Niveau 0 bevoegdheid
        case .mealPrep, .bedHelp:
            return .one
        }
    }

    var suggestedPriceCents: Int {
        switch self {
        case .companionship: return 1700
        case .groceries: return 1700
        case .lightCleaning: return 1700
        case .walkOutdoors: return 1700
        case .appointment: return 2100
        case .other: return 1700
        case .mealPrep: return 2100
        case .bedHelp: return 2100
        case .medicationReminder: return 2600
        }
    }
}

// MARK: - Buddy service preferences (mapping)

/// Gedeelde catalogus van specifieke buddy-services per niveau.
/// De namen worden 1-op-1 gebruikt in onboarding, profiel en matching.
enum BuddyServiceCatalog {

    struct Item: Hashable {
        let name: String
        let icon: String
        let subtitle: String
        let level: ServiceLevel
        /// Categorieën waaraan deze service mapt voor matching.
        let categories: Set<TaskCategory>
    }

    static let level0: [Item] = [
        Item(name: "Gezelschap",           icon: "person.2.fill",           subtitle: "Gesprek en aanwezigheid",                level: .zero, categories: [.companionship]),
        Item(name: "Wandelen",             icon: "figure.walk",             subtitle: "Buiten begeleiden",                       level: .zero, categories: [.walkOutdoors]),
        Item(name: "Boodschappen",         icon: "cart.fill",               subtitle: "Inkopen doen of begeleiden",              level: .zero, categories: [.groceries]),
        Item(name: "Lichte huishouding",   icon: "sparkles",                subtitle: "Opruimen en schoonmaken",                 level: .zero, categories: [.lightCleaning]),
        Item(name: "Maaltijd opwarmen",    icon: "fork.knife",              subtitle: "Eenvoudig eten klaarzetten",              level: .zero, categories: [.mealPrep]),
        Item(name: "Begeleiding afspraak", icon: "car.fill",                subtitle: "Meegaan naar arts of specialist",         level: .zero, categories: [.appointment]),
        Item(name: "Medicatieherinnering", icon: "bell.fill",               subtitle: "Erop wijzen dat medicatie genomen moet worden", level: .zero, categories: [.medicationReminder]),
        Item(name: "Digitale hulp",        icon: "iphone",                  subtitle: "Helpen met telefoon, tablet of computer", level: .zero, categories: [.other]),
        Item(name: "Administratie",        icon: "doc.text.fill",           subtitle: "Post sorteren en formulieren invullen",   level: .zero, categories: [.other]),
        Item(name: "Tuinieren",            icon: "leaf.fill",               subtitle: "Tuin bijhouden en planten verzorgen",     level: .zero, categories: [.other]),
        Item(name: "Huisdieren",           icon: "pawprint.fill",           subtitle: "Hond uitlaten of dier verzorgen",         level: .zero, categories: [.other]),
        Item(name: "Spelletjes",           icon: "dice.fill",               subtitle: "Gezelschapsspellen en kaarten",           level: .zero, categories: [.companionship]),
        Item(name: "Klusjes thuis",        icon: "shoppingbag.fill",        subtitle: "Kleine reparaties en ophanging",          level: .zero, categories: [.other]),
        Item(name: "Voorlezen",            icon: "book.fill",               subtitle: "Boeken, krant of brieven voorlezen",      level: .zero, categories: [.companionship]),
    ]

    static let level1: [Item] = [
        Item(name: "Opstaan / naar bed",   icon: "arrow.up.circle.fill",    subtitle: "Begeleiden bij het opstaan of naar bed gaan", level: .one, categories: [.bedHelp]),
        Item(name: "Aankleden",            icon: "tshirt.fill",             subtitle: "Helpen bij het aan- en uitkleden",        level: .one, categories: [.bedHelp]),
        Item(name: "Toiletbegeleiding",    icon: "figure.walk.motion",      subtitle: "Begeleiden naar en op het toilet",        level: .one, categories: [.bedHelp]),
        Item(name: "Transfers",            icon: "figure.stand",            subtitle: "Veilig van stoel naar bed of rolstoel",   level: .one, categories: [.bedHelp]),
        Item(name: "Rolstoelbegeleiding",  icon: "figure.seated.seatbelt",  subtitle: "Rijden met en begeleiden in rolstoel",    level: .one, categories: [.walkOutdoors, .appointment]),
        Item(name: "Maaltijdbereiding",    icon: "fork.knife.circle.fill",  subtitle: "Complete warme maaltijden bereiden",      level: .one, categories: [.mealPrep]),
        Item(name: "Vocht en voeding",     icon: "drop.fill",               subtitle: "Ondersteunen bij eten en drinken",        level: .one, categories: [.mealPrep]),
    ]

    static let level2: [Item] = [
        Item(name: "Volledig wassen",      icon: "shower.fill",             subtitle: "Douchen en wassen bij bed of stoel",      level: .two, categories: [.bedHelp]),
        Item(name: "Steunkousen",          icon: "bandage.fill",            subtitle: "Aantrekken en uittrekken van steunkousen", level: .two, categories: [.bedHelp]),
        Item(name: "Medicatietoezicht",    icon: "pills.fill",              subtitle: "Toezicht houden op medicatie-inname",     level: .two, categories: [.medicationReminder]),
        Item(name: "Volledige ADL",        icon: "cross.case.fill",         subtitle: "Complete dagelijkse lichaamsverzorging",  level: .two, categories: [.bedHelp]),
        Item(name: "Vitale meting",        icon: "waveform.path.ecg",       subtitle: "Bloeddruk en saturatie meten",            level: .two, categories: [.medicationReminder]),
    ]

    static let level3: [Item] = [
        Item(name: "Medicatie toedienen",  icon: "syringe.fill",            subtitle: "Zelf medicijnen verstrekken en documenteren", level: .three, categories: [.medicationReminder]),
        Item(name: "Stomazorg",            icon: "staroflife.fill",         subtitle: "Verzorging en wisseling van stoma",       level: .three, categories: [.other]),
        Item(name: "Wondverzorging",       icon: "cross.fill",              subtitle: "Verbanden wisselen en wonden reinigen",   level: .three, categories: [.other]),
        Item(name: "Katheter aanleggen",   icon: "drop.degreesign.fill",    subtitle: "Inbrengen en beheer van katheter",        level: .three, categories: [.other]),
        Item(name: "Insuline injecties",   icon: "heart.text.square.fill",  subtitle: "Subcutane injecties toedienen",           level: .three, categories: [.medicationReminder]),
    ]

    static func items(for level: ServiceLevel) -> [Item] {
        switch level {
        case .zero:  return level0
        case .one:   return level1
        case .two:   return level2
        case .three: return level3
        case .four:  return []
        }
    }

    static var allItems: [Item] { level0 + level1 + level2 + level3 }

    /// Geeft alle service-namen die mappen op een bepaalde categorie.
    static func serviceNames(for category: TaskCategory) -> Set<String> {
        Set(allItems.filter { $0.categories.contains(category) }.map { $0.name })
    }
}

// MARK: - Recurring schedule

enum RecurringFrequency: String, CaseIterable, Identifiable {
    case daily       = "Dagelijks"
    case everyOtherDay = "Om de dag"
    case weekly      = "Wekelijks"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .daily:         return "repeat"
        case .everyOtherDay: return "arrow.2.squarepath"
        case .weekly:        return "calendar"
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .daily:         return .day
        case .everyOtherDay: return .day
        case .weekly:        return .weekOfYear
        }
    }

    var stepValue: Int { self == .everyOtherDay ? 2 : 1 }
}

struct RecurringSchedule: Hashable {
    let frequency: RecurringFrequency
    let endDate: Date

    var displayName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "d MMM"
        return "\(frequency.rawValue) t/m \(f.string(from: endDate))"
    }
}

// MARK: - Task timing

enum TaskTiming: Hashable {
    case now
    case today(hour: Int)
    case scheduled(date: Date)

    var displayName: String {
        switch self {
        case .now: return "Zo snel mogelijk"
        case .today(let h): return String(format: "Vandaag om %02d:00", h)
        case .scheduled(let d):
            let f = DateFormatter()
            f.locale = Locale(identifier: "nl_NL")
            f.dateFormat = "EEEE d MMM 'om' HH:mm"
            return f.string(from: d).capitalized
        }
    }
}

// MARK: - Task status

enum TaskStatus: String, Codable {
    case open
    case accepted
    case arrived
    case inProgress
    case completed
    case cancelled

    var label: String {
        switch self {
        case .open: return "Open"
        case .accepted: return "Buddy onderweg"
        case .arrived: return "Buddy is aangekomen"
        case .inProgress: return "Bezig"
        case .completed: return "Afgerond"
        case .cancelled: return "Geannuleerd"
        }
    }

    var color: Color {
        switch self {
        case .open: return BCColors.warning
        case .accepted: return BCColors.primary
        case .arrived: return BCColors.accent
        case .inProgress: return BCColors.primary
        case .completed: return BCColors.success
        case .cancelled: return BCColors.danger
        }
    }
}

// MARK: - Service Task (avoid name clash with Swift Task)

struct ServiceTask: Identifiable, Hashable {
    let id: UUID
    let elderlyName: String
    let elderlyAddress: String
    let coordinate: CLLocationCoordinate2D
    let category: TaskCategory
    let requiredLevel: ServiceLevel
    let timing: TaskTiming
    let note: String
    let priceCents: Int
    var status: TaskStatus
    let createdAt: Date

    var assignedBuddyName: String?
    var assignedBuddyRating: Double?
    var assignedBuddyEtaMinutes: Int?

    var completionNote: String? = nil
    var completedAt: Date? = nil
    var recurringSchedule: RecurringSchedule? = nil
    var checkInRecord: CheckInRecord? = nil

    var priceFormatted: String {
        String(format: "€ %.2f", Double(priceCents) / 100).replacingOccurrences(of: ".", with: ",")
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ServiceTask, rhs: ServiceTask) -> Bool { lhs.id == rhs.id }
}

// MARK: - Check-in record

struct CheckInRecord {
    let timestamp: Date
    let latitude: Double?
    let longitude: Double?
    let qrPayload: String
    let hasSelfie: Bool
    let distanceMeters: Double?
    var selfieStorageUrl: String? = nil

    var timestampFormatted: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.timeStyle = .short
        return f.string(from: timestamp)
    }

    var distanceFormatted: String {
        guard let d = distanceMeters else { return "Onbekend" }
        return d < 1000 ? "\(Int(d.rounded())) m" : String(format: "%.1f km", d / 1000)
    }

    var isWithinRange: Bool {
        guard let d = distanceMeters else { return true }
        return d <= 500
    }
}

// MARK: - Users

struct ElderlyUser: Identifiable, Hashable {
    let id: UUID
    let firstName: String
    let lastName: String
    var address: String
    let coordinate: CLLocationCoordinate2D
    let dateOfBirth: Date
    var phoneNumber: String?
    var allergies: [String]
    var medicationNotes: String
    var favoriteBuddyIDs: [UUID]
    var familyMemberIDs: [UUID]
    var creditEuros: Double

    var fullName: String { "\(firstName) \(lastName)" }
    var age: Int { Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0 }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ElderlyUser, rhs: ElderlyUser) -> Bool { lhs.id == rhs.id }
}

struct BuddyUser: Identifiable, Hashable {
    let id: UUID
    let firstName: String
    let lastName: String
    let avatarSystemName: String
    let level: ServiceLevel
    let certifications: [Certification]
    let ratingAverage: Double
    let totalTasks: Int
    let bio: String
    let study: String
    let kycVerified: Bool
    let vogValid: Bool
    let vogExpiresAt: Date
    var ibanLast4: String = "****"
    var isAvailableNow: Bool = true
    /// Locatie van de buddy — gebruikt voor proximity matching.
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)
    /// Maximale afstand in km die de buddy bereid is af te leggen.
    var maxDistanceKm: Int = 10
    /// Aantal voltooide taken per categorie — bron voor "ervaren buddy" matching.
    var completedTasksByCategory: [TaskCategory: Int] = [:]
    /// Voorkeuren per niveau: welke specifieke services (ServiceOption-namen) wil de buddy doen.
    var servicePreferences: [ServiceLevel: Set<String>] = [:]

    var fullName: String { "\(firstName) \(lastName)" }
    /// True als de buddy 3+ taken in deze categorie heeft afgerond.
    func isExperiencedIn(_ category: TaskCategory) -> Bool {
        (completedTasksByCategory[category] ?? 0) >= 3
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: BuddyUser, rhs: BuddyUser) -> Bool { lhs.id == rhs.id }
}

struct FamilyUser: Identifiable, Hashable {
    let id: UUID
    let firstName: String
    let lastName: String
    let relationship: String
    let linkedElderlyIDs: [UUID]

    var fullName: String { "\(firstName) \(lastName)" }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: FamilyUser, rhs: FamilyUser) -> Bool { lhs.id == rhs.id }
}

// MARK: - Reviews & certificates & courses

struct Review: Identifiable, Hashable {
    let id: UUID
    let stars: Int
    let body: String
    let authorName: String
    let date: Date
}

struct Certification: Identifiable, Hashable {
    let id: UUID
    let level: ServiceLevel
    let issuedAt: Date
    let expiresAt: Date
}

// MARK: - Course content types

enum ModuleType: String, Hashable { case video, quiz, reading }

struct QuizQuestionData: Identifiable, Hashable {
    let id: UUID
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct ReadingSection: Identifiable, Hashable {
    let id: UUID
    let heading: String
    let body: String
    let symbol: String
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct CourseModuleData: Identifiable, Hashable {
    let id: UUID
    let title: String
    let type: ModuleType
    let durationMinutes: Int
    let illustrationSymbol: String
    var isCompleted: Bool = false
    var videoDescription: String = ""
    var readingSections: [ReadingSection] = []
    var quizQuestions: [QuizQuestionData] = []
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct Course: Identifiable, Hashable {
    let id: UUID
    let level: ServiceLevel
    let title: String
    let durationMinutes: Int
    var progressPercent: Int
    var unlocked: Bool
    let summary: String
    var requiresPhysicalCertification: Bool = false
    var modules: [CourseModuleData] = []
    var modulesCount: Int { modules.count }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Earnings

struct EarningEntry: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let elderlyName: String
    let category: TaskCategory
    let amountCents: Int
}

// MARK: - Activity items (family timeline)

struct ActivityItem: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let icon: String
    let color: Color
    let title: String
    let detail: String

    static func == (lhs: ActivityItem, rhs: ActivityItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Organizations ("Takken")

struct Organization: Identifiable, Hashable {
    let id: UUID
    let name: String
    let shortName: String
    let logoSymbol: String
    let buddyHourlyRateCents: Int  // wat de buddy per uur ontvangt
    let markupPercent: Double      // Thuisverzorgt winstopslag (%)
    let isActive: Bool

    var clientHourlyRateCents: Int {
        Int(Double(buddyHourlyRateCents) * (1.0 + markupPercent / 100.0))
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Organization, rhs: Organization) -> Bool { lhs.id == rhs.id }
}

enum MembershipStatus: String, Equatable {
    case none, pending, approved, rejected

    var displayLabel: String {
        switch self {
        case .none:     return "Geen"
        case .pending:  return "In behandeling"
        case .approved: return "Goedgekeurd"
        case .rejected: return "Afgewezen"
        }
    }

    var color: Color {
        switch self {
        case .none:     return BCColors.textTertiary
        case .pending:  return BCColors.warning
        case .approved: return BCColors.success
        case .rejected: return BCColors.danger
        }
    }
}

enum PaymentType: String, CaseIterable, Identifiable {
    case particulier
    case zinNatura

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .particulier: return "Particulier"
        case .zinNatura:   return "Zorg in natura"
        }
    }

    var icon: String {
        switch self {
        case .particulier: return "creditcard.fill"
        case .zinNatura:   return "building.columns.fill"
        }
    }

    var description: String {
        switch self {
        case .particulier: return "U betaalt zelf voor de zorg"
        case .zinNatura:   return "De gemeente betaalt via de organisatie"
        }
    }
}

struct OrganizationMembership: Identifiable {
    let id: UUID
    let userId: UUID
    let userName: String
    let userRole: UserRole
    let organizationId: UUID
    var status: MembershipStatus
    let proofNote: String
    let submittedAt: Date
    var reviewedAt: Date?
    var adminNote: String?
}

// MARK: - Facturatie / Service records

struct ServiceRecord: Identifiable, Hashable {
    let id: UUID
    let buddyName: String
    let elderlyName: String
    let organizationId: UUID
    let taskCategory: TaskCategory
    let hours: Double
    let buddyHourlyRateCents: Int
    let clientHourlyRateCents: Int
    let paymentType: PaymentType
    let municipality: String?
    let month: String              // "2026-05"
    let completedAt: Date
    var isFinalized: Bool

    var buddyEarningsCents: Int { Int(hours * Double(buddyHourlyRateCents)) }
    var clientChargeCents: Int  { Int(hours * Double(clientHourlyRateCents)) }
    var profitCents: Int        { clientChargeCents - buddyEarningsCents }

    var monthDisplayLabel: String {
        let parts = month.split(separator: "-")
        guard parts.count == 2, let m = Int(parts[1]) else { return month }
        let names = ["", "jan", "feb", "mrt", "apr", "mei", "jun",
                     "jul", "aug", "sep", "okt", "nov", "dec"]
        return m < names.count ? "\(names[m]) \(parts[0])" : month
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ServiceRecord, rhs: ServiceRecord) -> Bool { lhs.id == rhs.id }
}

// CLLocationCoordinate2D Hashable conformance
extension CLLocationCoordinate2D: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }

    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
