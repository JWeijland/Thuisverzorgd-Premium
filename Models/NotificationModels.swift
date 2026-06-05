import Foundation

enum BuddieNotification {
    case newTaskInArea(elderlyName: String, distanceKm: Double, priceEuros: Double)
    case priorityFavorite(elderlyName: String)
    case taskAccepted(buddyName: String, etaMinutes: Int)
    case taskReassigned(elderlyName: String)
    case buddyArrived(buddyName: String)
    case taskCompleted
    case sosTriggered(elderlyName: String)
    case kycApproved
    case kycRejected
    case payoutSent(amountEuros: Double)
    case courseExamAvailable(level: Int)
    case certificateExpiringSoon(level: Int)
    case familyReviewReminder(elderlyName: String)

    var title: String {
        switch self {
        case .newTaskInArea(let name, let dist, let price):
            return "\(name) zoekt hulp — \(String(format: "%.1f", dist)) km, €\(Int(price))"
        case .priorityFavorite(let name):
            return "\(name) vraagt hulp! Jij hebt 5 min voorrang."
        case .taskAccepted(let buddy, let eta):
            return "\(buddy) komt over \(eta) min."
        case .taskReassigned(let name):
            return "De buddy van \(name) is verhinderd — we zoeken iemand anders."
        case .buddyArrived(let buddy):
            return "\(buddy) staat voor de deur."
        case .taskCompleted:
            return "Bezoek afgerond. Bekijk het verslag."
        case .sosTriggered(let name):
            return "🚨 SOS van \(name) — bel direct."
        case .kycApproved:
            return "Uw identiteit is geverifieerd. Welkom!"
        case .kycRejected:
            return "Verificatie niet gelukt — neem contact op."
        case .payoutSent(let amount):
            return String(format: "€ %.2f is onderweg naar uw rekening.", amount).replacingOccurrences(of: ".", with: ",")
        case .courseExamAvailable(let level):
            return "Niveau \(level) examen is klaar voor u."
        case .certificateExpiringSoon(let level):
            return "Uw Level \(level) certificaat verloopt over \(Config.certificateExpiryWarningDays) dagen."
        case .familyReviewReminder(let name):
            return "\(name) heeft haar bezoek nog niet beoordeeld — wil jij even een beoordeling achterlaten?"
        }
    }

    var icon: String {
        switch self {
        case .newTaskInArea: return "mappin.circle.fill"
        case .priorityFavorite: return "heart.fill"
        case .taskAccepted: return "person.fill.checkmark"
        case .taskReassigned: return "arrow.triangle.2.circlepath"
        case .buddyArrived: return "door.sliding.open"
        case .taskCompleted: return "checkmark.seal.fill"
        case .sosTriggered: return "exclamationmark.triangle.fill"
        case .kycApproved: return "checkmark.shield.fill"
        case .kycRejected: return "xmark.shield.fill"
        case .payoutSent: return "eurosign.circle.fill"
        case .courseExamAvailable: return "graduationcap.fill"
        case .certificateExpiringSoon: return "clock.badge.exclamationmark"
        case .familyReviewReminder: return "star.bubble.fill"
        }
    }
}
