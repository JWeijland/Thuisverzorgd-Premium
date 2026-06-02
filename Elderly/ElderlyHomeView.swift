import SwiftUI
import CoreImage

struct ElderlyHomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.largeTextEnabled) private var largeText
    @State private var showRequestFlow = false
    @State private var showReview = false
    @State private var selectedHistoryTask: ServiceTask? = nil
    @State private var showWMOGuide = false
    @State private var showQRCode = false
    @State private var messageSent = false
    @State private var qrFlow: QRFlowKind? = nil

    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                greetingHeader

                ScrollView {
                    VStack(spacing: BCSpacing.lg) {
                        if let active = appState.activeTaskForElderly, active.status != .completed {
                            ActiveTaskBanner(
                                task: active,
                                onCall: callBuddy,
                                onMessage: sendMessage,
                                onStartVisit: { qrFlow = .checkIn },
                                onFinishVisit: { qrFlow = .checkOut }
                            )
                            .padding(.horizontal, BCSpacing.lg)
                            .padding(.top, BCSpacing.md)
                        }

                        // Belangrijkste actie — wit & rustig (variant C)
                        BCHelpHeroCard(
                            title: appState.activeTaskForElderly == nil ? "Hulp vragen" : "Nieuwe hulp vragen",
                            subtitle: "Een vertrouwde buddy uit de buurt komt u helpen."
                        ) {
                            showRequestFlow = true
                        }
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.top, BCSpacing.md)

                        // Ook handig
                        VStack(alignment: .leading, spacing: BCSpacing.sm) {
                            Text("Ook handig")
                                .font(et.heading)
                                .foregroundStyle(BCColors.textPrimary)
                                .padding(.horizontal, BCSpacing.lg)

                            HStack(alignment: .top, spacing: BCSpacing.md) {
                                BCQuickTile(
                                    title: "Vergoeding aanvragen",
                                    subtitle: "Via de Wmo — stap voor stap",
                                    icon: "eurosign.circle.fill",
                                    color: BCColors.success
                                ) {
                                    showWMOGuide = true
                                }
                                // QR is alleen zinvol als er een buddy onderweg is naar de deur.
                                if appState.activeTaskForElderly != nil {
                                    BCQuickTile(
                                        title: "QR voor de deur",
                                        subtitle: "Toon dit aan de buddy",
                                        icon: "qrcode",
                                        color: BCColors.navy500
                                    ) {
                                        showQRCode = true
                                    }
                                }
                            }
                            .padding(.horizontal, BCSpacing.lg)
                        }

                        upcomingSection

                        // Spacer for SOS floating button
                        Color.clear.frame(height: 100)
                    }
                    .padding(.bottom, BCSpacing.lg)
                }
            }

            sosFloatingButton
                .padding(.trailing, BCSpacing.lg)
                .padding(.bottom, BCSpacing.lg)
        }
        .background(BCColors.background.ignoresSafeArea())
        .alert("Bericht verstuurd", isPresented: $messageSent) {
            Button("Oké") { }
        } message: {
            Text("We laten uw buddy weten dat u een bericht heeft gestuurd.")
        }
        .sheet(isPresented: $showRequestFlow) {
            RequestHelpFlow()
        }
        .sheet(isPresented: $showWMOGuide) {
            WMOGuideView()
        }
        .sheet(isPresented: $showQRCode) {
            ElderlyQRCodeSheet()
        }
        .sheet(item: $qrFlow) { kind in
            CheckInOutQRSheet(kind: kind, buddyName: appState.activeTaskForElderly?.assignedBuddyName) {
                switch kind {
                case .checkIn:  appState.elderlyConfirmsCheckIn()
                case .checkOut: appState.elderlyConfirmsCheckOut()
                }
            }
        }
        .sheet(item: $selectedHistoryTask) { task in
            PastVisitSheet(task: task)
        }
        .fullScreenCover(isPresented: $showReview) {
            if !appState.isCordaanElderly,
               let task = appState.taskHistory.first,
               let buddyName = task.assignedBuddyName {
                ReviewView(buddyName: buddyName) {
                    showReview = false
                }
            }
        }
        .onChange(of: appState.activeTaskForElderly?.status) { _, newStatus in
            if newStatus == .completed && !appState.isCordaanElderly {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showReview = true
                }
            }
        }
    }

    // MARK: - Greeting header

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Goedemorgen"
        case 12..<18: return "Goedemiddag"
        default:      return "Goedenavond"
        }
    }

    private var greetingHeader: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [BCColors.navy900, BCColors.navy700],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

            HStack(spacing: BCSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting + ",")
                        .font(BCTypography.body)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                    Text(appState.elderlyUser.firstName)
                        .font(BCTypography.titleEmphasized)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Spacer()
                ZStack {
                    Circle().fill(.white)
                    Text(String(appState.elderlyUser.firstName.prefix(1)))
                        .font(BCTypography.title3)
                        .foregroundStyle(BCColors.navy700)
                }
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.md)
        }
        .frame(height: 76)
    }

    private func callBuddy() {
        let digits = Config.supportPhoneNumber.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel://\(digits)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func sendMessage() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        messageSent = true
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Eerder geholpen")
                    .font(et.heading)
                    .foregroundStyle(BCColors.textPrimary)
                Text("Tik op een bezoek om te beoordelen")
                    .font(et.caption)
                    .foregroundStyle(BCColors.textTertiary)
            }
            .padding(.horizontal, BCSpacing.lg)

            if appState.taskHistory.isEmpty {
                BCCard {
                    Text("Nog geen eerdere bezoeken.")
                        .font(et.body)
                        .foregroundStyle(BCColors.textSecondary)
                }
                .padding(.horizontal, BCSpacing.lg)
            } else {
                let limit = largeText ? 2 : 5
                let tasks = Array(appState.taskHistory.prefix(limit))
                VStack(spacing: BCSpacing.sm) {
                    ForEach(tasks) { task in
                        let rated = appState.taskRatings[task.id]
                        let needsReview = rated == nil && !appState.skippedReviews.contains(task.id)
                        Button { selectedHistoryTask = task } label: {
                            BCCard {
                                HStack(spacing: BCSpacing.md) {
                                    let iconSize: CGFloat = largeText ? 52 : 44
                                    Image(systemName: task.category.icon)
                                        .font(.system(size: largeText ? 28 : 22, weight: .semibold))
                                        .foregroundStyle(BCColors.primary)
                                        .frame(width: iconSize, height: iconSize)
                                        .background(Circle().fill(BCColors.primary.opacity(0.10)))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.category.displayName)
                                            .font(et.body)
                                            .foregroundStyle(BCColors.textPrimary)
                                        if let buddy = task.assignedBuddyName {
                                            HStack(spacing: BCSpacing.xs) {
                                                Text("Met \(buddy)")
                                                    .font(et.caption)
                                                    .foregroundStyle(BCColors.textSecondary)
                                                if !appState.isCordaanElderly,
                                                   appState.favoriteBuddyNames.contains(buddy) {
                                                    Image(systemName: "heart.fill")
                                                        .font(.system(size: largeText ? 13 : 10))
                                                        .foregroundStyle(BCColors.danger)
                                                }
                                            }
                                        }
                                        if let date = task.completedAt {
                                            Text(relativeFormatter.localizedString(for: date, relativeTo: Date()))
                                                .font(et.caption)
                                                .foregroundStyle(BCColors.textTertiary)
                                        }
                                        if !appState.isCordaanElderly {
                                            HStack(spacing: 3) {
                                                ForEach(1...5, id: \.self) { star in
                                                    Image(systemName: star <= (rated ?? 0) ? "star.fill" : "star")
                                                        .font(.system(size: 10, weight: .regular))
                                                        .foregroundStyle(star <= (rated ?? 0) ? BCColors.warning : BCColors.border)
                                                }
                                            }
                                            .padding(.top, 1)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: largeText ? 18 : 13, weight: .semibold))
                                        .foregroundStyle(BCColors.textTertiary)
                                }
                            }
                            .overlay(alignment: .leading) {
                                if needsReview && !appState.isCordaanElderly {
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: BCRadius.lg,
                                        bottomLeadingRadius: BCRadius.lg,
                                        bottomTrailingRadius: 0,
                                        topTrailingRadius: 0,
                                        style: .continuous
                                    )
                                    .fill(BCColors.accent)
                                    .frame(width: 4)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, BCSpacing.lg)
            }
        }
    }

    private var sosFloatingButton: some View {
        Button {
            appState.showSOS = true
        } label: {
            VStack(spacing: 0) {
                Image(systemName: "phone.fill.arrow.up.right")
                    .font(.system(size: 22, weight: .heavy))
                Text("SOS")
                    .font(.system(size: 13, weight: .heavy))
            }
            .foregroundStyle(.white)
            .frame(width: 72, height: 72)
            .background(
                Circle().fill(BCColors.danger)
            )
            .shadow(color: BCColors.danger.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .accessibilityLabel("SOS knop, alarmeer hulp")
        .buttonStyle(.plain)
    }
}

struct ActiveTaskBanner: View {
    let task: ServiceTask
    var onCall: () -> Void = {}
    var onMessage: () -> Void = {}
    var onStartVisit: () -> Void = {}
    var onFinishVisit: () -> Void = {}

    private var isInProgress: Bool { task.status == .inProgress }

    var body: some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                HStack {
                    BCStatusPill(
                        label: task.status == .accepted ? "Onderweg naar u" : task.status.label,
                        color: task.status == .accepted ? BCColors.success : task.status.color,
                        showDot: true
                    )
                    Spacer()
                    if let eta = task.assignedBuddyEtaMinutes {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                            Text("\(eta) min")
                        }
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(BCColors.surfaceMuted))
                    }
                }

                if let buddy = task.assignedBuddyName {
                    HStack(spacing: BCSpacing.sm) {
                        ZStack {
                            if let img = buddyAvatarImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                LinearGradient(
                                    colors: [BCColors.navy700, BCColors.navy500],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.95))
                            }
                        }
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .bcSoftShadow(.subtle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isInProgress ? "\(buddy) is bij u" : "\(buddy) komt naar u toe")
                                .font(BCTypography.headline)
                                .foregroundStyle(BCColors.textPrimary)
                            HStack(spacing: 4) {
                                Text(task.category.displayName)
                                if let r = task.assignedBuddyRating {
                                    Text("· ★ \(String(format: "%.1f", r))")
                                }
                            }
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }

                    BCProgressBar(value: isInProgress ? 1.0 : 0.55, color: BCColors.accent)

                    if isInProgress {
                        // Bezoek is bezig → afronden via QR
                        ctaButton("Bezoek afronden", icon: "checkmark.seal.fill", action: onFinishVisit)
                    } else {
                        HStack(spacing: BCSpacing.sm) {
                            actionButton("Bellen", icon: "phone.fill", filled: true, action: onCall)
                            actionButton("Bericht", icon: "message.fill", filled: false, action: onMessage)
                        }
                        // Buddy is er → bezoek starten via QR
                        ctaButton("Bezoek starten — QR tonen", icon: "qrcode", action: onStartVisit)
                    }
                } else {
                    Text(task.category.displayName)
                        .font(BCTypography.elderlyHeading)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("We zoeken een buddy voor u…")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                }
            }
        }
    }

    /// Toont automatisch een echte foto zodra je een afbeelding met de buddynaam
    /// (bv. "Sanne" of "buddy-sanne") aan Assets.xcassets toevoegt; anders een nette avatar.
    private var buddyAvatarImage: UIImage? {
        guard let name = task.assignedBuddyName else { return nil }
        return UIImage(named: name) ?? UIImage(named: "buddy-\(name.lowercased())")
    }

    private func ctaButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: BCSpacing.xs) {
                Image(systemName: icon).font(.system(size: 16, weight: .bold))
                Text(title).font(BCTypography.bodyEmphasized)
            }
            .foregroundStyle(BCColors.navy900)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(BCColors.accent)
            )
        }
        .buttonStyle(.plain)
    }

    private func actionButton(_ title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: BCSpacing.xs) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                Text(title).font(BCTypography.bodyEmphasized)
            }
            .foregroundStyle(filled ? .white : BCColors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(filled ? BCColors.primary : BCColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .stroke(BCColors.primary.opacity(filled ? 0 : 0.4), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Past Visit Sheet

private struct PastVisitSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let task: ServiceTask

    @State private var selectedStars: Int = 0
    @State private var reviewText: String = ""
    @State private var submitted: Bool = false

    private var buddy: BuddyUser? {
        guard let name = task.assignedBuddyName else { return nil }
        return MockData.allBuddies.first { $0.firstName == name }
    }

    private var alreadyRated: Bool { appState.taskRatings[task.id] != nil }
    private var alreadySkipped: Bool { appState.skippedReviews.contains(task.id) }
    private var isFavorite: Bool {
        guard let name = task.assignedBuddyName else { return false }
        return appState.favoriteBuddyNames.contains(name)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BCSpacing.lg) {

                    // Buddy header
                    VStack(spacing: BCSpacing.sm) {
                        ZStack {
                            Circle().fill(BCColors.primary.opacity(0.10)).frame(width: 80, height: 80)
                            Image(systemName: buddy?.avatarSystemName ?? "person.crop.circle.fill")
                                .font(.system(size: 44, weight: .regular))
                                .foregroundStyle(BCColors.primary)
                        }
                        Text(task.assignedBuddyName ?? "Buddy")
                            .font(BCTypography.title2)
                            .foregroundStyle(BCColors.textPrimary)
                        if let b = buddy {
                            HStack(spacing: BCSpacing.sm) {
                                BCLevelBadge(level: b.level)
                                BCRatingStars(value: b.ratingAverage)
                                Text("\(b.totalTasks) bezoeken")
                                    .font(BCTypography.caption)
                                    .foregroundStyle(BCColors.textTertiary)
                            }
                        }
                    }
                    .padding(.top, BCSpacing.md)

                    // Visit summary
                    BCCard {
                        VStack(spacing: BCSpacing.sm) {
                            HStack {
                                Label(task.category.displayName, systemImage: task.category.icon)
                                    .font(BCTypography.bodyEmphasized)
                                    .foregroundStyle(BCColors.textPrimary)
                                Spacer()
                                BCStatusPill(label: "Voltooid", color: BCColors.success)
                            }
                            if let date = task.completedAt {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(BCColors.textTertiary)
                                    Text(date.formatted(date: .long, time: .shortened))
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textSecondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    // Favorite toggle
                    if let name = task.assignedBuddyName {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            appState.toggleFavorite(buddyName: name)
                        } label: {
                            HStack(spacing: BCSpacing.md) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(isFavorite ? BCColors.danger : BCColors.textSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(isFavorite ? BCColors.danger.opacity(0.10) : BCColors.surface))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isFavorite ? "Vaste buddy" : "Voeg toe aan vaste buddies")
                                        .font(BCTypography.headline)
                                        .foregroundStyle(BCColors.textPrimary)
                                    Text(isFavorite ? "\(name) krijgt voorrang bij uw volgende aanvraag" : "Dan krijgt \(name) voorrang bij uw volgende aanvraag")
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textSecondary)
                                }
                                Spacer()
                                if isFavorite {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(BCColors.success)
                                }
                            }
                            .padding(BCSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                                    .fill(BCColors.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                                            .stroke(isFavorite ? BCColors.danger.opacity(0.3) : BCColors.border, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, BCSpacing.lg)
                        .animation(.easeInOut(duration: 0.2), value: isFavorite)
                    }

                    // Rating section — niet voor zorginstelling-cliënten
                    if !appState.isCordaanElderly {
                    if alreadyRated {
                        BCCard {
                            HStack {
                                Text("Uw beoordeling")
                                    .font(BCTypography.subheadline)
                                    .foregroundStyle(BCColors.textSecondary)
                                Spacer()
                                BCRatingStars(value: Double(appState.taskRatings[task.id] ?? 0))
                            }
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    } else if submitted {
                        VStack(spacing: BCSpacing.sm) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(BCColors.warning)
                            Text("Bedankt voor uw beoordeling!")
                                .font(BCTypography.headline)
                                .foregroundStyle(BCColors.textPrimary)
                        }
                        .padding(BCSpacing.xl)
                    } else if alreadySkipped {
                        Button {
                            appState.unskipReview(taskId: task.id)
                        } label: {
                            Text("Beoordeling alsnog geven")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.primary)
                                .padding(.vertical, BCSpacing.sm)
                        }
                        .buttonStyle(.plain)
                    } else {
                        VStack(spacing: BCSpacing.md) {
                            Text("Hoe was het bezoek?")
                                .font(BCTypography.elderlyHeading)
                                .foregroundStyle(BCColors.textPrimary)

                            HStack(spacing: BCSpacing.md) {
                                ForEach(1...5, id: \.self) { star in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedStars = star
                                    } label: {
                                        Image(systemName: star <= selectedStars ? "star.fill" : "star")
                                            .font(.system(size: 36, weight: .semibold))
                                            .foregroundStyle(star <= selectedStars ? BCColors.warning : BCColors.border)
                                            .frame(width: 56, height: 56)
                                            .scaleEffect(star <= selectedStars ? 1.1 : 1.0)
                                            .animation(.spring(response: 0.2), value: selectedStars)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if selectedStars > 0 {
                                BCCard {
                                    TextField("Vertel er iets meer over (optioneel)", text: $reviewText, axis: .vertical)
                                        .lineLimit(3, reservesSpace: true)
                                        .font(BCTypography.elderlyBody)
                                        .foregroundStyle(BCColors.textPrimary)
                                }
                                .padding(.horizontal, BCSpacing.lg)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))

                                BCPrimaryButton(title: "Verstuur beoordeling", icon: "star.fill") {
                                    appState.rateTask(taskId: task.id, stars: selectedStars, body: reviewText)
                                    withAnimation { submitted = true }
                                }
                                .padding(.horizontal, BCSpacing.lg)
                                .transition(.opacity)
                            }

                            Button {
                                appState.skipReview(taskId: task.id)
                                dismiss()
                            } label: {
                                Text("Beoordeling overslaan")
                                    .font(BCTypography.caption)
                                    .foregroundStyle(BCColors.textTertiary)
                                    .padding(.vertical, BCSpacing.sm)
                            }
                            .buttonStyle(.plain)
                        }
                        .animation(.easeInOut(duration: 0.2), value: selectedStars)
                    }
                    } // einde rating section (niet-Cordaan)

                    Spacer(minLength: BCSpacing.xl)
                }
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Bezoek details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
        .onAppear {
            selectedStars = appState.taskRatings[task.id] ?? 0
        }
    }
}

// MARK: - QR code sheet (for buddy to scan at door)

private struct ElderlyQRCodeSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private var qrPayload: String {
        if let task = appState.activeTaskForElderly {
            return "buddycare://task/\(task.id.uuidString)"
        }
        return "buddycare://checkin/\(UUID().uuidString)"
    }

    private var buddyName: String? {
        appState.activeTaskForElderly?.assignedBuddyName
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: BCSpacing.xl) {
                Spacer()

                VStack(spacing: BCSpacing.sm) {
                    Text("Laat de buddy dit scannen")
                        .font(BCTypography.title3)
                        .foregroundStyle(BCColors.textPrimary)
                    if let name = buddyName {
                        Text("Houd uw telefoon voor \(name) zodat hij/zij de QR-code kan inscannen.")
                            .font(BCTypography.body)
                            .foregroundStyle(BCColors.textSecondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Houd uw telefoon voor de buddy zodat hij/zij de QR-code kan inscannen.")
                            .font(BCTypography.body)
                            .foregroundStyle(BCColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                if let qrImage = makeQRImage(payload: qrPayload) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                        .padding(BCSpacing.lg)
                        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(.white))
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                }

                Spacer()
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("QR-code voor buddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
    }

    private func makeQRImage(payload: String) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(payload.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Check-in / uitcheck QR-flow (demo)

enum QRFlowKind: Identifiable {
    case checkIn, checkOut
    var id: Int { self == .checkIn ? 0 : 1 }
}

private struct CheckInOutQRSheet: View {
    let kind: QRFlowKind
    let buddyName: String?
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var title: String { kind == .checkIn ? "Bezoek starten" : "Bezoek afronden" }
    private var instruction: String {
        let name = buddyName ?? "de buddy"
        return kind == .checkIn
            ? "Laat \(name) deze QR-code scannen om het bezoek te starten."
            : "Laat \(name) deze QR-code scannen om uit te checken en het bezoek af te ronden."
    }
    private var skipLabel: String {
        kind == .checkIn ? "Demo: buddy heeft gescand" : "Demo: buddy heeft uitgecheckt"
    }
    private var payload: String {
        kind == .checkIn
            ? "thuisverzorgd://checkin/\(UUID().uuidString)"
            : "thuisverzorgd://checkout/\(UUID().uuidString)"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: BCSpacing.lg) {
                Spacer()
                VStack(spacing: BCSpacing.sm) {
                    Text(title)
                        .font(BCTypography.title3)
                        .foregroundStyle(BCColors.textPrimary)
                    Text(instruction)
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, BCSpacing.lg)

                if let qr = bcMakeQRImage(payload: payload) {
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                        .padding(BCSpacing.lg)
                        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(.white))
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                }

                Spacer()

                BCCTAButton(title: skipLabel, icon: "checkmark", iconLeading: true) {
                    onConfirm()
                    dismiss()
                }
                .padding(.horizontal, BCSpacing.lg)
                .padding(.bottom, BCSpacing.lg)
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle(kind == .checkIn ? "Inchecken" : "Uitchecken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
    }
}

private func bcMakeQRImage(payload: String) -> UIImage? {
    guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
    filter.setValue(Data(payload.utf8), forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")
    guard let ciImage = filter.outputImage else { return nil }
    let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
    let context = CIContext()
    guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
    return UIImage(cgImage: cgImage)
}

private let relativeFormatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.locale = Locale(identifier: "nl_NL")
    f.unitsStyle = .full
    return f
}()
