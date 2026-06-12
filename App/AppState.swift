import SwiftUI
import Observation

struct ToastMessage: Equatable {
    let text: String
    let icon: String
}

@Observable
final class AppState {
    // Navigation
    var currentRole: UserRole? = nil
    var hasSeenSplash: Bool = false
    var isOnboardingComplete: Bool = false
    var showLogin: Bool = false

    // Auth & initialization
    var authService = AuthService()
    var isInitializing: Bool = true
    var isDemoMode: Bool = false
    var realUserId: UUID? = nil
    private let profileService = ProfileService()

    // User data (used by both demo and real mode)
    var elderlyUser: ElderlyUser = MockData.omaRiet
    var buddyUser: BuddyUser = MockData.buddyAiyla
    var familyUser: FamilyUser = MockData.familySandra
    var allElderlyUsers: [ElderlyUser] = [MockData.omaRiet, MockData.opaHenk]

    // MARK: - Familie — gekoppelde ouderen
    // Eén familielid kan meerdere ouderen beheren (bijv. moeder én vader).
    // Meerdere familieleden kunnen dezelfde oudere koppelen via dezelfde code.
    var familyLinkedElderly: [ElderlyUser] = [MockData.omaRiet, MockData.opaHenk]
    var activeFamilyElderlyIndex: Int = 0

    /// De oudere die het familielid nu beheert.
    var activeFamilyElderly: ElderlyUser {
        get {
            guard familyLinkedElderly.indices.contains(activeFamilyElderlyIndex) else {
                return familyLinkedElderly.first ?? MockData.omaRiet
            }
            return familyLinkedElderly[activeFamilyElderlyIndex]
        }
        set {
            guard familyLinkedElderly.indices.contains(activeFamilyElderlyIndex) else { return }
            familyLinkedElderly[activeFamilyElderlyIndex] = newValue
        }
    }

    /// Koppelt een oudere via een 6-cijferige code. Geeft de voornaam terug
    /// bij succes, of nil als de code onbekend is.
    func linkElderly(code: String) -> String? {
        let known: [String: ElderlyUser] = [
            "123456": MockData.omaRiet,
            "654321": MockData.opaHenk
        ]
        guard let elderly = known[code] else { return nil }
        if let existing = familyLinkedElderly.firstIndex(where: { $0.id == elderly.id }) {
            activeFamilyElderlyIndex = existing
        } else {
            familyLinkedElderly.append(elderly)
            activeFamilyElderlyIndex = familyLinkedElderly.count - 1
        }
        return elderly.firstName
    }

    // Tasks
    var openTasks: [ServiceTask] = MockData.openTasks
    var activeTaskForElderly: ServiceTask? = nil
    var activeTaskForBuddy: ServiceTask? = nil
    var taskHistory: [ServiceTask] = MockData.completedTasks

    // Alle buddies in het systeem (voor matching)
    var allBuddies: [BuddyUser] = MockData.allBuddies

    // Matching
    private let matchingService = MatchingService()
    /// Laatste matches voor activeTaskForElderly — zodat UI kan tonen wie wordt benaderd
    var lastMatches: [MatchingService.Match] = []

    // Betalingen (demo in de MVP)
    let paymentService: PaymentService = PaymentServiceFactory.make()
    /// Geschiedenis van (demo-)betalingen voor betaalde extra's.
    var purchases: [Purchase] = []

    // UI state
    var showSOS: Bool = false
    var toastMessage: ToastMessage? = nil

    // Elderly preferences (not on ElderlyUser struct to avoid breaking init)
    var largeTextEnabled: Bool = false
    var prefersFormal: Bool = true

    // Buddy availability
    var isAvailableNow: Bool = true

    // Facturatie (display-only — geen echte betaling in MVP)
    var serviceRecords: [ServiceRecord] = MockData.sampleServiceRecords

    // Elderly — favorites & ratings
    var favoriteBuddyNames: Set<String> = ["Aiyla", "Mark"]
    var taskRatings: [UUID: Int] = [:]
    var skippedReviews: Set<UUID> = []

    func toggleFavorite(buddyName: String) {
        if favoriteBuddyNames.contains(buddyName) {
            favoriteBuddyNames.remove(buddyName)
        } else {
            favoriteBuddyNames.insert(buddyName)
            showToast(text: "\(buddyName) toegevoegd aan vaste buddies", icon: "heart.fill")
        }
    }

    func rateTask(taskId: UUID, stars: Int, body: String) {
        taskRatings[taskId] = stars
        skippedReviews.remove(taskId)
        elderlySubmitsReview(stars: stars, body: body)
    }

    func skipReview(taskId: UUID) {
        skippedReviews.insert(taskId)
    }

    func unskipReview(taskId: UUID) {
        skippedReviews.remove(taskId)
    }

    var familyHasUnreviewedVisits: Bool {
        let name = activeFamilyElderly.firstName
        return taskHistory.contains { task in
            task.elderlyName == name && taskRatings[task.id] == nil && !skippedReviews.contains(task.id)
        }
    }

    private let taskService = TaskService()

    /// Update de diensten die de buddy aanbiedt. Persists naar buddyUser én allBuddies.
    func setBuddyServices(_ services: Set<String>) {
        buddyUser.offeredServices = services
        if let idx = allBuddies.firstIndex(where: { $0.id == buddyUser.id }) {
            allBuddies[idx].offeredServices = services
        }
    }

    // MARK: - Initialization (called on app start)

    func initialize() async {
        await authService.restoreSession()
        if let userId = authService.currentUserId {
            await handleAuthSuccess(userId: userId)
        }
        isInitializing = false
    }

    // MARK: - Auth success handler

    func handleAuthSuccess(userId: UUID, role: UserRole? = nil) async {
        realUserId = userId
        if let role = role {
            currentRole = role
        } else {
            do {
                let profile = try await profileService.fetchProfile(userId: userId)
                switch profile.role {
                case "elderly": currentRole = .elderly
                case "buddy":   currentRole = .buddy
                case "family":  currentRole = .family
                default: break
                }
            } catch {
                // Profile not loaded — user stays on auth screen
                return
            }
        }
        showLogin = false
        // hasSeenSplash niet hier zetten — de SplashView beheert die vlag,
        // anders verdwijnt de openingsanimatie meteen bij sessieherstel.
        isOnboardingComplete = true
    }

    // MARK: - Sign out

    func signOut() async {
        try? await authService.signOut()
        realUserId = nil
        currentRole = nil
        hasSeenSplash = false
        isDemoMode = false
        showLogin = false
        isOnboardingComplete = false
    }

    // MARK: - Navigation

    func resetToRoleSelection() {
        currentRole = nil
        activeTaskForElderly = nil
        activeTaskForBuddy = nil
        showSOS = false
        isDemoMode = false
    }

    // MARK: - Task actions

    func requestHelp(category: TaskCategory, timing: TaskTiming, note: String,
                     recurringSchedule: RecurringSchedule? = nil,
                     extras: Set<RequestExtra> = [], purchase: Purchase? = nil) {
        var task = ServiceTask(
            id: UUID(),
            elderlyName: elderlyUser.firstName,
            elderlyAddress: elderlyUser.address,
            coordinate: elderlyUser.coordinate,
            category: category,
            timing: timing,
            note: note,
            priceCents: category.suggestedPriceCents,
            status: .open,
            createdAt: Date(),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        )
        task.recurringSchedule = recurringSchedule
        task.extras = extras
        task.purchase = purchase
        if let purchase { purchases.insert(purchase, at: 0) }
        openTasks.insert(task, at: 0)
        activeTaskForElderly = task

        // Matching: vind buddies en stuur hen een notificatie
        let matches = matchingService.rankBuddies(for: task, from: allBuddies)
        lastMatches = matches
        matchingService.notifyMatchedBuddies(matches: matches, task: task)
    }

    func requestHelpOnBehalf(
        for elderly: ElderlyUser,
        category: TaskCategory,
        timing: TaskTiming,
        note: String,
        recurringSchedule: RecurringSchedule? = nil,
        extras: Set<RequestExtra> = [],
        purchase: Purchase? = nil
    ) {
        var task = ServiceTask(
            id: UUID(),
            elderlyName: "\(elderly.firstName) \(elderly.lastName)",
            elderlyAddress: elderly.address,
            coordinate: elderly.coordinate,
            category: category,
            timing: timing,
            note: note,
            priceCents: category.suggestedPriceCents,
            status: .open,
            createdAt: Date(),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        )
        task.recurringSchedule = recurringSchedule
        task.extras = extras
        task.purchase = purchase
        if let purchase { purchases.insert(purchase, at: 0) }
        openTasks.insert(task, at: 0)
        activeTaskForElderly = task
        showToast(text: "Aanvraag ingezet voor \(elderly.firstName)", icon: "phone.fill")

        // Matching: vind buddies en stuur hen een notificatie
        let matches = matchingService.rankBuddies(for: task, from: allBuddies)
        lastMatches = matches
        matchingService.notifyMatchedBuddies(matches: matches, task: task)
    }

    func simulateBuddyAccepts(taskID: UUID) {
        guard let idx = openTasks.firstIndex(where: { $0.id == taskID }) else { return }
        var task = openTasks[idx]

        // Kies de beste match (eerst meest ervaren, dan dichtstbij). Fallback op Aiyla.
        let chosenBuddy: BuddyUser = lastMatches.first?.buddy ?? MockData.buddyAiyla

        task.status = .accepted
        task.assignedBuddyName = chosenBuddy.firstName
        task.assignedBuddyRating = chosenBuddy.ratingAverage
        task.assignedBuddyEtaMinutes = Int.random(in: 8...18)
        openTasks[idx] = task
        // Werk het cliëntscherm bij als dit bezoek bij de actieve cliënt hoort.
        // (Niet alleen op id matchen — de actieve taak kan een kopie zijn.)
        if activeTaskForElderly?.id == taskID
            || task.elderlyName == elderlyUser.firstName
            || task.elderlyName == elderlyUser.fullName {
            activeTaskForElderly = task
        }
        MockPushService().send(notification: .taskAccepted(
            buddyName: chosenBuddy.firstName,
            etaMinutes: task.assignedBuddyEtaMinutes ?? 12
        ))
        MockSMSService().sendSMS(
            to: elderlyUser.phoneNumber ?? "",
            message: BuddieNotification.taskAccepted(buddyName: chosenBuddy.firstName, etaMinutes: task.assignedBuddyEtaMinutes ?? 12).title
        )
    }

    func buddyAcceptsTask(_ task: ServiceTask) {
        guard let idx = openTasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updated = openTasks[idx]
        updated.status = .accepted
        updated.assignedBuddyName = buddyUser.firstName
        updated.assignedBuddyRating = buddyUser.ratingAverage
        updated.assignedBuddyEtaMinutes = Int.random(in: 6...15)
        openTasks[idx] = updated
        activeTaskForBuddy = updated
    }

    /// De toegewezen buddy annuleert vóór de check-in. De taak gaat terug
    /// naar 'open', wordt opnieuw gematcht en de andere buddies krijgen
    /// opnieuw een melding. De oudere wordt geïnformeerd.
    func buddyCancelsAcceptedTask() {
        guard var task = activeTaskForBuddy else { return }
        let cancellingBuddyName = task.assignedBuddyName ?? buddyUser.firstName

        // Taak terugzetten naar open
        task.status = .open
        task.assignedBuddyName = nil
        task.assignedBuddyRating = nil
        task.assignedBuddyEtaMinutes = nil
        task.checkInRecord = nil

        if let idx = openTasks.firstIndex(where: { $0.id == task.id }) {
            openTasks[idx] = task
        } else {
            openTasks.insert(task, at: 0)
        }
        activeTaskForBuddy = nil
        if activeTaskForElderly?.id == task.id {
            activeTaskForElderly = task
        }

        // Opnieuw matchen, exclusief de buddy die net annuleerde
        let remaining = allBuddies.filter { $0.firstName != cancellingBuddyName }
        let matches = matchingService.rankBuddies(for: task, from: remaining)
        lastMatches = matches
        matchingService.notifyMatchedBuddies(matches: matches, task: task)

        // Oudere informeren
        MockPushService().send(notification: .taskReassigned(elderlyName: task.elderlyName))
        MockSMSService().sendSMS(
            to: elderlyUser.phoneNumber ?? "",
            message: BuddieNotification.taskReassigned(elderlyName: task.elderlyName).title
        )
        showToast(text: "Taak geannuleerd — we zoeken een andere buddy", icon: "arrow.triangle.2.circlepath")

        // Simuleer dat een andere buddy de taak weer oppakt
        let taskID = task.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.simulateBuddyAccepts(taskID: taskID)
        }
    }

    func buddyArrives(checkIn: CheckInRecord) {
        guard var task = activeTaskForBuddy else { return }
        task.status = .arrived
        task.checkInRecord = checkIn
        activeTaskForBuddy = task
        if let idx = openTasks.firstIndex(where: { $0.id == task.id }) {
            openTasks[idx] = task
        }
        if activeTaskForElderly?.id == task.id {
            activeTaskForElderly = task
        }
        MockPushService().send(notification: .buddyArrived(buddyName: buddyUser.firstName))
        MockSMSService().sendSMS(
            to: elderlyUser.phoneNumber ?? "",
            message: BuddieNotification.buddyArrived(buddyName: buddyUser.firstName).title
        )
    }

    func buddyCompletes(notes: String) {
        guard var task = activeTaskForBuddy else { return }
        task.status = .completed
        task.completionNote = notes
        task.completedAt = Date()
        if let idx = openTasks.firstIndex(where: { $0.id == task.id }) {
            openTasks.remove(at: idx)
        }
        taskHistory.insert(task, at: 0)
        activeTaskForBuddy = nil

        // Verhoog ervaringsteller voor matching-rangschikking
        let current = buddyUser.completedTasksByCategory[task.category] ?? 0
        buddyUser.completedTasksByCategory[task.category] = current + 1
        if let idx = allBuddies.firstIndex(where: { $0.id == buddyUser.id }) {
            allBuddies[idx].completedTasksByCategory[task.category] = current + 1
        }
        // Update elderly so they see the completed state and review prompt
        if activeTaskForElderly?.id == task.id {
            activeTaskForElderly = task
        }
        MockPushService().send(notification: .taskCompleted)
        // Simulate: after 24h without elderly review, remind family
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self, self.taskRatings[task.id] == nil else { return }
            MockPushService().send(notification: .familyReviewReminder(elderlyName: self.elderlyUser.firstName))
        }
    }

    func elderlySubmitsReview(stars: Int, body: String) {
        activeTaskForElderly = nil
        showToast(text: "Bedankt voor uw beoordeling!", icon: "star.fill")
    }

    /// Demo: de oudere bevestigt de check-in (QR gescand of overgeslagen) → het bezoek start.
    func elderlyConfirmsCheckIn() {
        guard var task = activeTaskForElderly else { return }
        task.status = .inProgress
        if let idx = openTasks.firstIndex(where: { $0.id == task.id }) { openTasks[idx] = task }
        activeTaskForElderly = task
        if activeTaskForBuddy?.id == task.id { activeTaskForBuddy = task }
        showToast(text: "Bezoek gestart", icon: "checkmark.circle.fill")
    }

    /// Demo: de oudere bevestigt de uitcheck (QR gescand of overgeslagen) → het bezoek wordt voltooid.
    func elderlyConfirmsCheckOut() {
        guard var task = activeTaskForElderly else { return }
        task.status = .completed
        task.completedAt = Date()
        if task.completionNote == nil { task.completionNote = "Bezoek afgerond." }
        if let idx = openTasks.firstIndex(where: { $0.id == task.id }) { openTasks.remove(at: idx) }
        taskHistory.insert(task, at: 0)
        activeTaskForBuddy = nil
        activeTaskForElderly = task   // status .completed → cliëntscherm toont de beoordeling
    }


    // MARK: - SOS

    func triggerSOS() {
        showSOS = true
        MockSMSService().sendSMS(
            to: "06-00000000",
            message: BuddieNotification.sosTriggered(elderlyName: elderlyUser.firstName).title
        )
        MockPushService().send(notification: .sosTriggered(elderlyName: elderlyUser.firstName))
    }

    // MARK: - Toast

    func showToast(text: String, icon: String = "checkmark.circle.fill") {
        toastMessage = ToastMessage(text: text, icon: icon)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if self?.toastMessage?.text == text {
                self?.toastMessage = nil
            }
        }
    }
}

enum UserRole: String, CaseIterable, Identifiable {
    case elderly
    case buddy
    case family
    case admin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .elderly: return "Ik zoek hulp"
        case .buddy:   return "Ik ben buddy"
        case .family:  return "Ik ben familielid"
        case .admin:   return "Admin"
        }
    }

    var subtitle: String {
        switch self {
        case .elderly: return "Vraag hulp aan een buddy in de buurt"
        case .buddy:   return "Verdien bij met klusjes en gezelschap in de buurt"
        case .family:  return "Regel hulp voor je vader, moeder of opa/oma"
        case .admin:   return "Beheer buddies en aanvragen"
        }
    }

    var icon: String {
        switch self {
        case .elderly: return "figure.wave"
        case .buddy:   return "person.2.fill"
        case .family:  return "house.and.flag.fill"
        case .admin:   return "gearshape.2.fill"
        }
    }
}
