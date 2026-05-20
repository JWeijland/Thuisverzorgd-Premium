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
    /// Welke buddies zijn lid van een organisatie (Cordaan) — die negeren voorkeuren-filter
    var cordaanBuddyIDs: Set<UUID> = []

    /// Level-up trigger: zodra dit niet-nil wordt verschijnt de voorkeuren-sheet automatisch.
    var newlyUnlockedLevel: ServiceLevel? = nil
    /// Houdt bij welke niveaus al gevierd zijn, voorkomt herhaalde prompts.
    private var celebratedLevels: Set<ServiceLevel> = []

    // UI state
    var showSOS: Bool = false
    var toastMessage: ToastMessage? = nil

    // Elderly preferences (not on ElderlyUser struct to avoid breaking init)
    var largeTextEnabled: Bool = false
    var prefersFormal: Bool = true

    // Buddy availability
    var isAvailableNow: Bool = true

    // MARK: - Organisatie ("Tak") state
    var availableOrganizations: [Organization] = [MockData.cordaan]
    var pendingRole: UserRole? = nil
    var selectedOrganization: Organization? = nil
    var currentUserMembership: OrganizationMembership? = nil
    var allMemberships: [OrganizationMembership] = MockData.sampleMemberships

    // Facturatie
    var elderlyPaymentType: PaymentType = .particulier
    var elderlyMunicipality: String = ""
    var serviceRecords: [ServiceRecord] = MockData.sampleServiceRecords

    var isOrganizationMember: Bool {
        currentUserMembership?.status == .approved
    }
    var isCordaanBuddy: Bool {
        isOrganizationMember && currentRole == .buddy
    }
    var isCordaanElderly: Bool {
        isOrganizationMember && currentRole == .elderly
    }

    // Diploma
    var diplomaStatus: DiplomaStatus = .none

    var effectiveBuddyLevel: ServiceLevel {
        // Buddies via een zorginstelling zijn gediplomeerd en bevoegd voor alles.
        if isCordaanBuddy { return .three }
        guard case .verified = diplomaStatus else { return buddyUser.level }
        let kort = CourseContent.course_basisWelkom_kort
        let done = completedModules[kort.id] ?? []
        return done.count >= kort.modules.count ? .three : .zero
    }

    var shortCourseComplete: Bool {
        let kort = CourseContent.course_basisWelkom_kort
        let done = completedModules[kort.id] ?? []
        return done.count >= kort.modules.count
    }

    func submitDiploma(type: String) {
        diplomaStatus = .pending(type: type)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.diplomaStatus = .verified(type: type)
            self?.showToast(text: "Diploma geverifieerd! Voltooi de verkorte Basis Buddy cursus.", icon: "checkmark.shield.fill")
        }
    }

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
        taskHistory.contains { task in
            taskRatings[task.id] == nil && !skippedReviews.contains(task.id)
        }
    }

    // Course progress: courseId → set of completed moduleIds
    var completedModules: [UUID: Set<UUID>] = [:]

    private let taskService = TaskService()

    func debugCompleteLevel(_ level: ServiceLevel) {
        for course in MockData.courses where course.level == level {
            for module in course.modules {
                completedModules[course.id, default: []].insert(module.id)
            }
        }
    }

    func recordModuleComplete(courseId: UUID, moduleId: UUID) {
        completedModules[courseId, default: []].insert(moduleId)
        if !isDemoMode, let userId = realUserId {
            Task {
                try? await taskService.markModuleComplete(
                    buddyId: userId,
                    courseId: courseId.uuidString,
                    moduleId: moduleId.uuidString
                )
            }
        }
        checkForLevelUnlock(after: courseId)
    }

    /// Detecteert of voltooien van deze cursus een nieuw niveau ontgrendelt.
    /// Triggert dan de voorkeuren-sheet via `newlyUnlockedLevel`.
    /// Cordaan-buddies worden overgeslagen — zij hebben geen voorkeuren-flow.
    private func checkForLevelUnlock(after courseId: UUID) {
        guard !isCordaanBuddy else { return }
        guard let course = MockData.courses.first(where: { $0.id == courseId }) else { return }
        let allModuleIds = Set(course.modules.map { $0.id })
        let done = completedModules[courseId] ?? []
        guard !allModuleIds.isEmpty, allModuleIds.isSubset(of: done) else { return }

        let unlockedLevel = course.level
        guard !celebratedLevels.contains(unlockedLevel) else { return }
        celebratedLevels.insert(unlockedLevel)
        newlyUnlockedLevel = unlockedLevel
    }

    /// Update buddy-voorkeuren voor een niveau. Persists naar zowel buddyUser als allBuddies.
    func setBuddyPreferences(level: ServiceLevel, services: Set<String>) {
        buddyUser.servicePreferences[level] = services
        if let idx = allBuddies.firstIndex(where: { $0.id == buddyUser.id }) {
            allBuddies[idx].servicePreferences[level] = services
        }
    }

    func dismissLevelUnlock() {
        newlyUnlockedLevel = nil
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
        hasSeenSplash = true
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
    }

    // MARK: - Task actions

    func requestHelp(category: TaskCategory, timing: TaskTiming, note: String,
                     recurringSchedule: RecurringSchedule? = nil, levelOverride: ServiceLevel? = nil) {
        var task = ServiceTask(
            id: UUID(),
            elderlyName: elderlyUser.firstName,
            elderlyAddress: elderlyUser.address,
            coordinate: elderlyUser.coordinate,
            category: category,
            requiredLevel: levelOverride ?? category.minimumLevel,
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
        openTasks.insert(task, at: 0)
        activeTaskForElderly = task

        // Matching: vind buddies en stuur hen een notificatie
        let matches = matchingService.rankBuddies(for: task, from: allBuddies, cordaanBuddyIDs: cordaanBuddyIDs)
        lastMatches = matches
        matchingService.notifyMatchedBuddies(matches: matches, task: task)
    }

    func requestHelpOnBehalf(
        for elderly: ElderlyUser,
        category: TaskCategory,
        timing: TaskTiming,
        note: String,
        recurringSchedule: RecurringSchedule? = nil,
        levelOverride: ServiceLevel? = nil
    ) {
        var task = ServiceTask(
            id: UUID(),
            elderlyName: "\(elderly.firstName) \(elderly.lastName)",
            elderlyAddress: elderly.address,
            coordinate: elderly.coordinate,
            category: category,
            requiredLevel: levelOverride ?? category.minimumLevel,
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
        openTasks.insert(task, at: 0)
        showToast(text: "Aanvraag ingezet voor \(elderly.firstName)", icon: "phone.fill")
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
        if activeTaskForElderly?.id == taskID {
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
        let matches = matchingService.rankBuddies(for: task, from: remaining, cordaanBuddyIDs: cordaanBuddyIDs)
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

    // MARK: - Organisatie methoden

    func submitMembershipRequest(organization: Organization, proofNote: String) {
        let role = pendingRole ?? currentRole ?? .buddy
        let name = role == .buddy ? buddyUser.fullName : elderlyUser.fullName
        let membership = OrganizationMembership(
            id: UUID(),
            userId: realUserId ?? UUID(),
            userName: name,
            userRole: role,
            organizationId: organization.id,
            status: .pending,
            proofNote: proofNote,
            submittedAt: Date()
        )
        currentUserMembership = membership
        allMemberships.append(membership)
        selectedOrganization = organization
    }

    func approveMembership(id: UUID) {
        guard let idx = allMemberships.firstIndex(where: { $0.id == id }) else { return }
        allMemberships[idx].status = .approved
        allMemberships[idx].reviewedAt = Date()
        if currentUserMembership?.id == id {
            currentUserMembership = allMemberships[idx]
        }
        showToast(text: "Aanvraag goedgekeurd", icon: "checkmark.seal.fill")
    }

    func rejectMembership(id: UUID, reason: String = "") {
        guard let idx = allMemberships.firstIndex(where: { $0.id == id }) else { return }
        allMemberships[idx].status = .rejected
        allMemberships[idx].reviewedAt = Date()
        allMemberships[idx].adminNote = reason.isEmpty ? nil : reason
        if currentUserMembership?.id == id {
            currentUserMembership = allMemberships[idx]
        }
        showToast(text: "Aanvraag afgewezen", icon: "xmark.circle.fill")
    }

    func activateCordaanDemo(role: UserRole) {
        let org = MockData.cordaan
        selectedOrganization = org
        let name = role == .buddy ? "Demo Cordaan Buddy" : "Demo Cordaan Cliënt"
        let membership = OrganizationMembership(
            id: UUID(),
            userId: UUID(),
            userName: name,
            userRole: role,
            organizationId: org.id,
            status: .approved,
            proofNote: "Demo — automatisch goedgekeurd",
            submittedAt: Date(),
            reviewedAt: Date()
        )
        currentUserMembership = membership
        isDemoMode = true
        isOnboardingComplete = true
        hasSeenSplash = true
        currentRole = role
    }

    func finalizeMonth(_ month: String) {
        for i in serviceRecords.indices where serviceRecords[i].month == month {
            serviceRecords[i].isFinalized = true
        }
        showToast(text: "Maand \(month) afgesloten", icon: "checkmark.seal.fill")
    }

    func csvExport(month: String? = nil) -> String {
        let records = month.map { m in serviceRecords.filter { $0.month == m } } ?? serviceRecords
        var rows = ["Maand,Buddy,Ouder,Categorie,Uren,Uurtarief buddy,Uurtarief klant,Betalingstype,Gemeente,Buddy verdienste,Klant bedrag,Winst,Definitief"]
        for r in records {
            let cols = [
                r.month,
                r.buddyName,
                r.elderlyName,
                r.taskCategory.displayName,
                String(format: "%.2f", r.hours),
                String(format: "%.2f", Double(r.buddyHourlyRateCents) / 100),
                String(format: "%.2f", Double(r.clientHourlyRateCents) / 100),
                r.paymentType.displayName,
                r.municipality ?? "-",
                String(format: "%.2f", Double(r.buddyEarningsCents) / 100),
                String(format: "%.2f", Double(r.clientChargeCents) / 100),
                String(format: "%.2f", Double(r.profitCents) / 100),
                r.isFinalized ? "Ja" : "Nee"
            ]
            rows.append(cols.joined(separator: ","))
        }
        return rows.joined(separator: "\n")
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

enum DiplomaStatus: Equatable {
    case none
    case pending(type: String)
    case verified(type: String)

    var diplomaType: String? {
        switch self {
        case .pending(let t), .verified(let t): return t
        case .none: return nil
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
        case .elderly: return "Ik ben oudere"
        case .buddy:   return "Ik ben buddy"
        case .family:  return "Ik ben familielid"
        case .admin:   return "Admin"
        }
    }

    var subtitle: String {
        switch self {
        case .elderly: return "Vraag hulp aan een buddy in de buurt"
        case .buddy:   return "Verdien geld met zorgtaken bij jou in de buurt"
        case .family:  return "Regel hulp voor je vader, moeder of opa/oma"
        case .admin:   return "Beheer aanvragen en facturatie"
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
