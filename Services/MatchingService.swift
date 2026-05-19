import Foundation
import CoreLocation

/// Bepaalt welke buddies in aanmerking komen voor een nieuwe taakaanvraag,
/// en in welke volgorde ze gevraagd moeten worden.
///
/// Volgorde-criteria (in deze prioriteit):
/// 1. Ervaring met de gevraagde TaskCategory (meer voltooide taken = hoger)
/// 2. Afstand tot het adres van de oudere (dichterbij = hoger)
/// 3. Gemiddelde rating (hoger = hoger)
struct MatchingService {

    struct Match: Identifiable {
        let buddy: BuddyUser
        let distanceMeters: Double
        let experienceCount: Int
        let isExperienced: Bool
        var id: UUID { buddy.id }
    }

    /// Vindt en rankt buddies die geschikt zijn voor de taak.
    ///
    /// - Parameters:
    ///   - task: de openstaande taak
    ///   - buddies: alle buddies in het systeem
    ///   - cordaanBuddyIDs: IDs van Cordaan-buddies — die hebben geen voorkeuren-filter
    func rankBuddies(
        for task: ServiceTask,
        from buddies: [BuddyUser],
        cordaanBuddyIDs: Set<UUID> = []
    ) -> [Match] {
        let targetLoc = CLLocation(latitude: task.coordinate.latitude, longitude: task.coordinate.longitude)
        let allowedServiceNames = BuddyServiceCatalog.serviceNames(for: task.category)

        let matches: [Match] = buddies.compactMap { buddy in
            // 1. Moet beschikbaar zijn
            guard buddy.isAvailableNow else { return nil }

            // 2. Moet voldoende niveau hebben
            guard buddy.level.rawValue >= task.requiredLevel.rawValue else { return nil }

            // 3. Voorkeuren-filter — Cordaan-buddies overslaan (gecertificeerd, accepteren alles)
            if !cordaanBuddyIDs.contains(buddy.id) {
                let allBuddyPreferences = buddy.servicePreferences.values.reduce(into: Set<String>()) { $0.formUnion($1) }
                let overlap = allBuddyPreferences.intersection(allowedServiceNames)
                guard !overlap.isEmpty else { return nil }
            }

            // 4. Afstand-filter (eigen maxDistanceKm van de buddy)
            let buddyLoc = CLLocation(latitude: buddy.coordinate.latitude, longitude: buddy.coordinate.longitude)
            let distance = targetLoc.distance(from: buddyLoc)
            let maxMeters = Double(buddy.maxDistanceKm) * 1000.0
            guard distance <= maxMeters else { return nil }

            let exp = buddy.completedTasksByCategory[task.category] ?? 0
            return Match(
                buddy: buddy,
                distanceMeters: distance,
                experienceCount: exp,
                isExperienced: exp >= 3
            )
        }

        // Sorteer: ervaring desc → afstand asc → rating desc
        return matches.sorted { a, b in
            if a.experienceCount != b.experienceCount {
                return a.experienceCount > b.experienceCount
            }
            if a.distanceMeters != b.distanceMeters {
                return a.distanceMeters < b.distanceMeters
            }
            return a.buddy.ratingAverage > b.buddy.ratingAverage
        }
    }

    /// Stuurt mock-push aan alle matchende buddies wanneer een taak wordt aangemaakt.
    func notifyMatchedBuddies(
        matches: [Match],
        task: ServiceTask,
        push: PushService = MockPushService()
    ) {
        for match in matches {
            let distKm = match.distanceMeters / 1000.0
            push.send(notification: .newTaskInArea(
                elderlyName: task.elderlyName,
                distanceKm: distKm,
                level: task.requiredLevel.rawValue,
                priceEuros: Double(task.priceCents) / 100.0
            ))
        }
    }
}
