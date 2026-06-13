import Foundation
import Supabase
import CoreLocation

// ============================================================
// GeocodingService — adres → coördinaat via CLGeocoder (geen API-key)
// Forward geocoding vraagt geen locatierechten; we voegen "Nederland" toe
// zodat dubbelzinnige straatnamen in NL landen.
// ============================================================

final class GeocodingService {
    private let geocoder = CLGeocoder()

    func coordinate(for address: String) async -> CLLocationCoordinate2D? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let query = trimmed.lowercased().contains("nederland") ? trimmed : "\(trimmed), Nederland"
        let placemarks = try? await geocoder.geocodeAddressString(query)
        return placemarks?.first?.location?.coordinate
    }
}

final class ProfileService {

    func fetchProfile(userId: UUID) async throws -> DBProfile {
        try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func fetchBuddyProfile(userId: UUID) async throws -> DBBuddyProfile {
        try await supabase
            .from("buddy_profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func fetchElderlyProfile(userId: UUID) async throws -> DBElderlyProfile {
        try await supabase
            .from("elderly_profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func updateBuddyAvailability(buddyId: UUID, isAvailable: Bool) async throws {
        try await supabase
            .from("buddy_profiles")
            .update(["is_available_now": isAvailable])
            .eq("id", value: buddyId.uuidString)
            .execute()
    }

    /// Werkt het telefoonnummer op het basisprofiel bij (`.update()`, rij
    /// bestaat al via de signup-trigger).
    func updateProfilePhone(userId: UUID, phone: String?) async throws {
        struct Update: Encodable { let phoneNumber: String?
            enum CodingKeys: String, CodingKey { case phoneNumber = "phone_number" } }
        try await supabase
            .from("profiles")
            .update(Update(phoneNumber: phone))
            .eq("id", value: userId.uuidString)
            .execute()
    }

    /// Werkt het elderly-adres (+ gegeocodeerde coördinaat) bij. Gebruikt
    /// `.update()` (niet upsert): de rij bestaat al via de signup-trigger.
    func updateElderlyAddress(userId: UUID, address: String,
                              latitude: Double?, longitude: Double?) async throws {
        struct Update: Encodable {
            let address: String
            let latitude: Double?
            let longitude: Double?
        }
        try await supabase
            .from("elderly_profiles")
            .update(Update(address: address, latitude: latitude, longitude: longitude))
            .eq("id", value: userId.uuidString)
            .execute()
    }
}

// ============================================================
// Voorkeuren — meldingen + privacy/consent (Fase B)
// Aparte tabellen; upsert op user_id zodat het werkt of de rij nu wel of
// niet bestaat (RLS staat zowel INSERT als UPDATE op de eigen rij toe).
// ============================================================

final class PreferencesService {

    func fetchNotificationPrefs(userId: UUID) async throws -> DBNotificationPreferences? {
        let rows: [DBNotificationPreferences] = try await supabase
            .from("notification_preferences")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func upsertNotificationPrefs(_ prefs: DBNotificationPreferences) async throws {
        try await supabase
            .from("notification_preferences")
            .upsert(prefs, onConflict: "user_id")
            .execute()
    }

    func fetchConsent(userId: UUID) async throws -> Bool? {
        let rows: [DBAnalyticsConsent] = try await supabase
            .from("analytics_consent")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first?.consented
    }

    func upsertConsent(userId: UUID, consented: Bool) async throws {
        try await supabase
            .from("analytics_consent")
            .upsert(DBAnalyticsConsent(userId: userId, consented: consented), onConflict: "user_id")
            .execute()
    }
}
