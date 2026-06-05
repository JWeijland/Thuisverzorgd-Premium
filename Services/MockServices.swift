import Foundation

// MARK: - Payment

protocol PaymentService {
    func processPayment(taskID: UUID, amountCents: Int) async -> Bool
}

// TODO[real-integration]: Replace with Mollie SDK
struct MockPaymentService: PaymentService {
    func processPayment(taskID: UUID, amountCents: Int) async -> Bool {
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        return true
    }
}

// MARK: - SMS

protocol SMSService {
    func sendSMS(to phoneNumber: String, message: String)
}

// TODO[real-integration]: Replace with Twilio SMS API
struct MockSMSService: SMSService {
    func sendSMS(to phoneNumber: String, message: String) {
        print("[MockSMS] To: \(phoneNumber) — \(message)")
    }
}

// MARK: - Push

protocol PushService {
    func send(notification: BuddieNotification)
}

// TODO[real-integration]: Replace with APNs/OneSignal
struct MockPushService: PushService {
    func send(notification: BuddieNotification) {
        print("[MockPush] \(notification.title)")
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
