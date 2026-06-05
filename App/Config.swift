import Foundation

enum Config {
    static let platformCommissionPercent: Double = 0.20
    static let maxTaskRadiusKm: Double = 10.0
    static let favoriteBuddyPriorityMinutes: Int = 5
    static let vogRenewalYears: Int = 3
    static let reviewVisibilityDelayHours: Int = 48
    static let certificateValidityYears: Int = 2
    static let certificateExpiryWarningDays: Int = 60

    static let launchCities: [String] = ["Rotterdam", "Amsterdam"]
    static let launchQuarter: String = "Q3 2026"
    static let minimumBuddyAge: Int = 18

    // Pricing (cents per hour, base rate — consumer/private pay)
    static let priceLevel0CentsPerHour: Int = 1700   // buddy net €13,60 (above min wage)
    static let priceLevel1CentsPerHour: Int = 2100   // buddy net €16,80
    static let priceLevel2CentsPerHour: Int = 2600   // buddy net €20,80
    static let priceLevel3CentsPerHour: Int = 3200   // buddy net €25,60
    static let travelCostCentsPerKmAfter5: Int = 23

    // Platform fee (display-only; no real payment in MVP)
    static let platformFeeCentsPerHour: Int = 500    // €5 per uur

    // Mock contact (replace before TestFlight)
    static let supportPhoneNumber: String = "085-XXX XXXX"
    static let supportEmail: String = "hulp@thuisverzorgd.nl"

    // Feature flags (all false for MVP)
    static let enableRealPayments: Bool = false
    static let enableKYCVerification: Bool = false
    static let enableCameraStream: Bool = false
    static let enableRealPushNotifications: Bool = false
}
