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

    // WMO contracted rates (cents per hour, municipality pays Thuisverzorgd)
    static let wmoLevel0CentsPerHour: Int = 2200     // buddy net €17,60
    static let wmoLevel1CentsPerHour: Int = 2700     // buddy net €21,60
    static let wmoLevel2CentsPerHour: Int = 3300     // buddy net €26,40
    static let wmoLevel3CentsPerHour: Int = 4000     // buddy net €32,00

    // Mock contact (replace before TestFlight)
    static let supportPhoneNumber: String = "085-XXX XXXX"
    static let supportEmail: String = "hulp@thuisverzorgd.nl"

    // Feature flags (all false for MVP)
    static let enableRealPayments: Bool = false
    static let enableKYCVerification: Bool = false
    static let enableCameraStream: Bool = false
    static let enableRealPushNotifications: Bool = false
}
