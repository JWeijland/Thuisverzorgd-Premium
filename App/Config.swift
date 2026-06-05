import Foundation

enum Config {
    /// Platformkosten als percentage van het uurtarief (display-only in de MVP).
    static let platformCommissionPercent: Double = 0.20

    /// Hoe vaak een VOG vernieuwd/gecontroleerd wordt (jaren).
    static let vogRenewalYears: Int = 3

    // Mock contact (replace before TestFlight)
    static let supportPhoneNumber: String = "085-XXX XXXX"
    static let supportEmail: String = "hulp@thuisverzorgd.nl"

    // Feature flags (MVP)
    static let enableRealPayments: Bool = false
    static let enableRealPushNotifications: Bool = false
}
