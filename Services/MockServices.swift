import Foundation

// MARK: - Payment

enum PaymentResult: Equatable {
    case success(Purchase)
    case failure(String)
}

protocol PaymentService {
    /// Reken de gekozen betaalde extra's af en geef een Purchase terug.
    func charge(extras: [RequestExtra], taskID: UUID?) async -> PaymentResult
}

/// Demo-betaalprovider: simuleert een betaling met een korte vertraging.
/// Slaagt altijd. Vervang door een echte provider (bijv. Mollie) door
/// `enableRealPayments` aan te zetten en hier een echte implementatie te kiezen.
struct DemoPaymentService: PaymentService {
    func charge(extras: [RequestExtra], taskID: UUID?) async -> PaymentResult {
        let cents = extras.reduce(0) { $0 + $1.priceCents }
        guard cents > 0 else {
            return .failure("Geen extra's geselecteerd om af te rekenen.")
        }
        // Simuleer betaal-/netwerkvertraging.
        try? await Task.sleep(nanoseconds: 1_400_000_000)
        let purchase = Purchase(
            id: UUID(),
            taskID: taskID,
            items: extras,
            amountCents: cents,
            status: .paid,
            createdAt: Date(),
            method: "demo"
        )
        return .success(purchase)
    }
}

// TODO[real-integration]: vervang DemoPaymentService door een echte provider (Mollie SDK).
enum PaymentServiceFactory {
    static func make() -> PaymentService {
        // if Config.enableRealPayments { return MolliePaymentService() }
        DemoPaymentService()
    }
}

// MARK: - SMS

protocol SMSService {
    func sendSMS(to phoneNumber: String, message: String)
}

// TODO[real-integration]: Replace with Twilio SMS API
struct MockSMSService: SMSService {
    func sendSMS(to phoneNumber: String, message: String) {
        #if DEBUG
        print("[MockSMS] To: \(phoneNumber) — \(message)")
        #endif
    }
}

// MARK: - Push

protocol PushService {
    func send(notification: BuddieNotification)
}

// TODO[real-integration]: Replace with APNs/OneSignal
struct MockPushService: PushService {
    func send(notification: BuddieNotification) {
        #if DEBUG
        print("[MockPush] \(notification.title)")
        #endif
    }
}

// MARK: - VOG tracking

enum VOGResult { case submitted, approved, expired }

protocol VOGService {
    func submitVOG(userID: UUID) async -> VOGResult
}

// TODO[real-integration]: VOG required every 3 years, track expiry
// COMPLIANCE: VOG required every 3 years, track expiry
struct MockVOGService: VOGService {
    func submitVOG(userID: UUID) async -> VOGResult {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return .submitted
    }
}
