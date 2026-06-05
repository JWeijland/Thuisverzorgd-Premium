import Foundation
import Supabase

// ============================================================
// Supabase client — singleton, beschikbaar door de hele app
// ============================================================

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://oopmfcymxjataisfhryq.supabase.co")!,
    supabaseKey: "sb_publishable_L8AP2lH8HOx99pHTSTZDHA_KzoW2qbC"
)

// ============================================================
// DATABASE MODELLEN
// Komen 1-op-1 overeen met de tabellen in schema.sql
// ============================================================

struct DBProfile: Codable, Identifiable {
    let id: UUID
    let role: String
    let firstName: String
    let lastName: String
    let phoneNumber: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, role
        case firstName   = "first_name"
        case lastName    = "last_name"
        case phoneNumber = "phone_number"
        case createdAt   = "created_at"
    }
}

struct DBElderlyProfile: Codable, Identifiable {
    let id: UUID
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var allergies: [String]?
    var medicationNotes: String?
    var creditEuros: Double?

    enum CodingKeys: String, CodingKey {
        case id, address, latitude, longitude, allergies
        case medicationNotes = "medication_notes"
        case creditEuros     = "credit_euros"
    }
}

struct DBBuddyProfile: Codable, Identifiable {
    let id: UUID
    var bio: String?
    var study: String?
    var ratingAverage: Double?
    var totalTasks: Int?
    var vogValid: Bool?
    var vogExpiresAt: String?
    var ibanLast4: String?
    var isAvailableNow: Bool?
    var isOnboardingComplete: Bool?

    enum CodingKeys: String, CodingKey {
        case id, bio, study
        case ratingAverage        = "rating_average"
        case totalTasks           = "total_tasks"
        case vogValid             = "vog_valid"
        case vogExpiresAt         = "vog_expires_at"
        case ibanLast4            = "iban_last4"
        case isAvailableNow       = "is_available_now"
        case isOnboardingComplete = "is_onboarding_complete"
    }
}

struct DBTask: Codable, Identifiable {
    let id: UUID
    let elderlyId: UUID
    var assignedBuddyId: UUID?
    let category: String
    let timingType: String
    var scheduledAt: String?
    let note: String
    let priceCents: Int
    var status: String
    let createdAt: String
    var acceptedAt: String?
    var arrivedAt: String?
    var completedAt: String?
    var completionNote: String?
    var buddyEtaMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case id, note, status, category
        case elderlyId        = "elderly_id"
        case assignedBuddyId  = "assigned_buddy_id"
        case timingType       = "timing_type"
        case scheduledAt      = "scheduled_at"
        case priceCents       = "price_cents"
        case createdAt        = "created_at"
        case acceptedAt       = "accepted_at"
        case arrivedAt        = "arrived_at"
        case completedAt      = "completed_at"
        case completionNote   = "completion_note"
        case buddyEtaMinutes  = "buddy_eta_minutes"
    }
}

struct DBReview: Codable, Identifiable {
    let id: UUID
    let taskId: UUID
    let reviewerId: UUID
    let revieweeId: UUID
    let stars: Int
    let body: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, stars, body
        case taskId      = "task_id"
        case reviewerId  = "reviewer_id"
        case revieweeId  = "reviewee_id"
        case createdAt   = "created_at"
    }
}

struct DBEarning: Codable, Identifiable {
    let id: UUID
    let buddyId: UUID
    let taskId: UUID
    let elderlyName: String
    let category: String
    let amountCents: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, category
        case buddyId     = "buddy_id"
        case taskId      = "task_id"
        case elderlyName = "elderly_name"
        case amountCents = "amount_cents"
        case createdAt   = "created_at"
    }
}

struct DBLinkingCode: Codable {
    let code: String
    let elderlyId: UUID
    let expiresAt: String
    var usedAt: String?

    enum CodingKeys: String, CodingKey {
        case code
        case elderlyId = "elderly_id"
        case expiresAt = "expires_at"
        case usedAt    = "used_at"
    }
}
