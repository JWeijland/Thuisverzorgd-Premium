import SwiftUI
import Observation
import CoreLocation

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
    private let preferencesService = PreferencesService()
    private let adminService = AdminService()
    private let geocoder = GeocodingService()

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

    // Voorkeuren — meldingen + privacy/consent (Fase B).
    // In demo-modus blijven deze puur lokaal; in live-modus laden/opslaan ze
    // via PreferencesService (notification_preferences / analytics_consent).
    var notificationPrefs = NotificationPreferences()
    var analyticsConsentGiven: Bool = false

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
        await loadPreferences()
    }

    // MARK: - Voorkeuren (meldingen + privacy/consent)

    /// Laadt opgeslagen voorkeuren uit Supabase (alleen in live-modus).
    func loadPreferences() async {
        guard let uid = realUserId, !isDemoMode else { return }
        if let prefs = (try? await preferencesService.fetchNotificationPrefs(userId: uid)) ?? nil {
            notificationPrefs = NotificationPreferences(
                pushEnabled: prefs.pushEnabled,
                visitUpdates: prefs.visitUpdates,
                newTasksNearby: prefs.newTasksNearby,
                sosAlerts: prefs.sosAlerts,
                monthlyReport: prefs.monthlyReport
            )
        }
        if let consent = (try? await preferencesService.fetchConsent(userId: uid)) ?? nil {
            analyticsConsentGiven = consent
        }
    }

    /// Muteert de meldingsvoorkeuren en bewaart ze direct.
    func updateNotificationPrefs(_ mutate: (inout NotificationPreferences) -> Void) {
        mutate(&notificationPrefs)
        persistPreferences()
    }

    func setAnalyticsConsent(_ value: Bool) {
        analyticsConsentGiven = value
        persistPreferences()
    }

    /// Binding-fabriek zodat profielpagina's een toggle rechtstreeks kunnen
    /// koppelen; elke wijziging persisteert automatisch.
    func notificationBinding(_ keyPath: WritableKeyPath<NotificationPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { self.notificationPrefs[keyPath: keyPath] },
            set: { newValue in self.updateNotificationPrefs { $0[keyPath: keyPath] = newValue } }
        )
    }

    var analyticsConsentBinding: Binding<Bool> {
        Binding(get: { self.analyticsConsentGiven }, set: { self.setAnalyticsConsent($0) })
    }

    private func persistPreferences() {
        guard let uid = realUserId, !isDemoMode else { return }
        let prefs = notificationPrefs
        let consent = analyticsConsentGiven
        Task {
            try? await preferencesService.upsertNotificationPrefs(
                DBNotificationPreferences(
                    userId: uid,
                    pushEnabled: prefs.pushEnabled,
                    visitUpdates: prefs.visitUpdates,
                    newTasksNearby: prefs.newTasksNearby,
                    sosAlerts: prefs.sosAlerts,
                    monthlyReport: prefs.monthlyReport
                )
            )
            try? await preferencesService.upsertConsent(userId: uid, consented: consent)
        }
    }

    /// Stuurt een (mock-)push uitsluitend als de gebruikersvoorkeur dit toestaat.
    /// De Config-feature-flag voor echte pushes blijft de hoofd-schakelaar.
    /// SOS gaat altijd door (veiligheid).
    func deliverPush(_ notification: BuddieNotification) {
        guard notificationPrefs.pushEnabled else { return }
        let allowed: Bool
        switch notification {
        case .newTaskInArea: allowed = notificationPrefs.newTasksNearby
        case .sosTriggered:  allowed = true
        default:             allowed = notificationPrefs.visitUpdates
        }
        guard allowed else { return }
        MockPushService().send(notification: notification)
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
        persistNewTaskIfLive(task)

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
        deliverPush(.taskAccepted(
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
        deliverPush(.taskReassigned(elderlyName: task.elderlyName))
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
        deliverPush(.buddyArrived(buddyName: buddyUser.firstName))
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
        deliverPush(.taskCompleted)
        // Simulate: after 24h without elderly review, remind family
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self, self.taskRatings[task.id] == nil else { return }
            self.deliverPush(.familyReviewReminder(elderlyName: self.elderlyUser.firstName))
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


    // MARK: - Live persistentie (Fase F)
    // Flows blijven lokaal werken (demo + directe UI); in live-modus schrijven
    // ze daarnaast naar Supabase. Mock-data blijft zichtbaar (§1.3).

    /// Buddy-beschikbaarheid — lokaal + (live) naar buddy_profiles.
    func setBuddyAvailable(_ value: Bool) {
        isAvailableNow = value
        buddyUser.isAvailableNow = value
        if let idx = allBuddies.firstIndex(where: { $0.id == buddyUser.id }) {
            allBuddies[idx].isAvailableNow = value
        }
        guard let uid = realUserId, !isDemoMode else { return }
        Task { try? await profileService.updateBuddyAvailability(buddyId: uid, isAvailable: value) }
    }

    /// Telefoonnummer op het eigen profiel — (live) naar profiles.
    func persistElderlyContactIfLive(phone: String?) {
        guard let uid = realUserId, !isDemoMode else { return }
        Task { try? await profileService.updateProfilePhone(userId: uid, phone: phone) }
    }

    /// Schrijft een zojuist lokaal aangemaakte aanvraag echt naar Supabase
    /// (alleen als de ingelogde oudere het zelf is) en koppelt de DB-id terug.
    private func persistNewTaskIfLive(_ task: ServiceTask) {
        guard let uid = realUserId, !isDemoMode, currentRole == .elderly else { return }
        let timing = task.timing.dbValues
        let coord = task.coordinate
        let localId = task.id
        Task {
            guard let db = try? await taskService.createTask(
                elderlyId: uid,
                category: task.category.dbValue,
                timingType: timing.type,
                scheduledAt: timing.scheduledAt,
                note: task.note,
                priceCents: task.priceCents,
                latitude: coord.latitude,
                longitude: coord.longitude
            ) else { return }
            await MainActor.run {
                if let idx = openTasks.firstIndex(where: { $0.id == localId }) { openTasks[idx].dbId = db.id }
                if activeTaskForElderly?.id == localId { activeTaskForElderly?.dbId = db.id }
            }
        }
    }

    // MARK: - Locatie (Fase D)

    /// Geocodeert het adres en werkt de coördinaat van de juiste oudere bij,
    /// zodat aanvragen op het echte adres op de buddy-kaart komen (en niet op
    /// één gedeeld default-punt stapelen). Persisteert in live-modus voor het
    /// eigen elderly-profiel (familie-namens kan dit niet schrijven onder RLS).
    func updateCoordinateFromAddress(_ address: String, forFamilyElderly: Bool) {
        Task {
            guard let coord = await geocoder.coordinate(for: address) else { return }
            await MainActor.run {
                if forFamilyElderly {
                    var updated = activeFamilyElderly
                    updated.coordinate = coord
                    activeFamilyElderly = updated
                } else {
                    elderlyUser.coordinate = coord
                }
            }
            if !forFamilyElderly, let uid = realUserId, !isDemoMode {
                try? await profileService.updateElderlyAddress(
                    userId: uid, address: address,
                    latitude: coord.latitude, longitude: coord.longitude
                )
            }
        }
    }

    // MARK: - Admin-beheeracties (Fase C)
    // Werken lokaal (zodat de demo direct reageert) en persisteren in
    // live-modus via SECURITY DEFINER-RPC's.

    private var isLiveAdmin: Bool { !isDemoMode && realUserId != nil }

    func adminSetVOG(buddyId: UUID, valid: Bool) {
        if let idx = allBuddies.firstIndex(where: { $0.id == buddyId }) { allBuddies[idx].vogValid = valid }
        if buddyUser.id == buddyId { buddyUser.vogValid = valid }
        showToast(text: valid ? "VOG goedgekeurd" : "VOG afgewezen",
                  icon: valid ? "checkmark.shield.fill" : "xmark.shield.fill")
        guard isLiveAdmin else { return }
        Task { try? await adminService.setVOG(buddyId: buddyId, valid: valid) }
    }

    func adminSetIntake(buddyId: UUID, done: Bool) {
        if let idx = allBuddies.firstIndex(where: { $0.id == buddyId }) { allBuddies[idx].intakeDone = done }
        if buddyUser.id == buddyId { buddyUser.intakeDone = done }
        showToast(text: done ? "Intake goedgekeurd" : "Intake heropend",
                  icon: "person.fill.checkmark")
        guard isLiveAdmin else { return }
        Task { try? await adminService.setIntake(buddyId: buddyId, done: done) }
    }

    func adminSetRole(userId: UUID, role: UserRole) {
        guard isLiveAdmin else {
            showToast(text: "Rolbeheer werkt in live-modus", icon: "info.circle.fill")
            return
        }
        showToast(text: "Rol bijgewerkt", icon: "person.2.badge.gearshape")
        Task { try? await adminService.setRole(userId: userId, role: role.rawValue) }
    }

    /// Maakt een 6-cijferige koppelcode aan voor een oudere en geeft die terug.
    @discardableResult
    func adminCreateLinkingCode(for elderly: ElderlyUser) -> String {
        let code = String(format: "%06d", Int.random(in: 0...999_999))
        if isLiveAdmin {
            Task { try? await adminService.createLinkingCode(elderlyId: elderly.id, code: code) }
        }
        showToast(text: "Koppelcode \(code) voor \(elderly.firstName)", icon: "key.fill")
        return code
    }

    /// Persisteert een telefonische aanvraag in live-modus (lokale weergave
    /// loopt al via requestHelpOnBehalf).
    func persistTaskOnBehalf(for elderly: ElderlyUser, category: TaskCategory,
                             timing: TaskTiming, note: String) {
        guard isLiveAdmin else { return }
        Task {
            try? await adminService.createTaskOnBehalf(
                elderlyId: elderly.id, category: category, timing: timing,
                note: note, priceCents: category.suggestedPriceCents,
                latitude: elderly.coordinate.latitude, longitude: elderly.coordinate.longitude
            )
        }
    }

    // MARK: - SOS

    func triggerSOS() {
        showSOS = true
        MockSMSService().sendSMS(
            to: "06-00000000",
            message: BuddieNotification.sosTriggered(elderlyName: elderlyUser.firstName).title
        )
        deliverPush(.sosTriggered(elderlyName: elderlyUser.firstName))
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
