import Foundation
import SwiftUI
import CoreLocation

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

    var suggestedPriceCents: Int {
        switch self {
        case .companionship: return 1800
        case .groceries: return 1900
        case .lightCleaning: return 2000
        case .walkOutdoors: return 1800
        case .appointment: return 2200
        case .other: return 2000
        case .mealPrep: return 2000
        case .bedHelp: return 2100
        case .medicationReminder: return 2000
        }
    }
}

// MARK: - Buddy service catalog (flat — geen niveaus, geen medische handelingen)

/// Platte catalogus van buddy-diensten gericht op het dagelijks leven.
/// De namen worden 1-op-1 gebruikt in onboarding, profiel en matching.
enum BuddyServiceCatalog {

    struct Item: Hashable {
        let name: String
        let icon: String
        let subtitle: String
        /// Categorieën waaraan deze dienst mapt voor matching.
        let categories: Set<TaskCategory>
    }

    static let allItems: [Item] = [
        Item(name: "Gezelschap",           icon: "person.2.fill",           subtitle: "Gesprek en aanwezigheid",                 categories: [.companionship]),
        Item(name: "Wandelen",             icon: "figure.walk",             subtitle: "Samen een ommetje maken",                 categories: [.walkOutdoors]),
        Item(name: "Boodschappen",         icon: "cart.fill",               subtitle: "Inkopen doen of begeleiden",              categories: [.groceries]),
        Item(name: "Lichte huishouding",   icon: "sparkles",                subtitle: "Opruimen en schoonmaken",                 categories: [.lightCleaning]),
        Item(name: "Samen koken",          icon: "fork.knife",              subtitle: "Maaltijd bereiden of opwarmen",           categories: [.mealPrep]),
        Item(name: "Begeleiding afspraak", icon: "car.fill",                subtitle: "Meegaan naar arts of afspraak",           categories: [.appointment]),
        Item(name: "Vervoer",              icon: "car.fill",                subtitle: "Rijden naar familie, winkel of activiteit", categories: [.appointment]),
        Item(name: "Medicatieherinnering", icon: "bell.fill",               subtitle: "Eraan herinneren — niet toedienen",       categories: [.medicationReminder]),
        Item(name: "Digitale hulp",        icon: "iphone",                  subtitle: "Helpen met telefoon, tablet of computer", categories: [.other]),
        Item(name: "Administratie",        icon: "doc.text.fill",           subtitle: "Post sorteren en formulieren invullen",   categories: [.other]),
        Item(name: "Tuinieren",            icon: "leaf.fill",               subtitle: "Tuin bijhouden en planten verzorgen",     categories: [.other]),
        Item(name: "Huisdieren",           icon: "pawprint.fill",           subtitle: "Hond uitlaten of dier verzorgen",         categories: [.other]),
        Item(name: "Spelletjes",           icon: "dice.fill",               subtitle: "Gezelschapsspellen en kaarten",           categories: [.companionship]),
        Item(name: "Klusjes thuis",        icon: "shoppingbag.fill",        subtitle: "Kleine reparaties en ophanging",          categories: [.other]),
        Item(name: "Voorlezen",            icon: "book.fill",               subtitle: "Boeken, krant of brieven voorlezen",      categories: [.companionship]),
    ]

    /// Geeft alle dienst-namen die mappen op een bepaalde categorie.
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
    /// Welke diensten de buddy aanbiedt (namen uit BuddyServiceCatalog).
    var offeredServices: Set<String> = []

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

// MARK: - Reviews

struct Review: Identifiable, Hashable {
    let id: UUID
    let stars: Int
    let body: String
    let authorName: String
    let date: Date
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

// MARK: - Facturatie / Service records

struct ServiceRecord: Identifiable, Hashable {
    let id: UUID
    let buddyName: String
    let elderlyName: String
    let taskCategory: TaskCategory
    let hours: Double
    let buddyHourlyRateCents: Int
    let clientHourlyRateCents: Int
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
