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

    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                BCNavBar(title: "Hallo \(appState.elderlyUser.firstName)", subtitle: "Thuisverzorgd")

                ScrollView {
                    VStack(spacing: BCSpacing.lg) {
                        if let active = appState.activeTaskForElderly {
                            ActiveTaskBanner(task: active)
                                .padding(.horizontal, BCSpacing.lg)
                                .padding(.top, BCSpacing.md)
                        }

                        VStack(alignment: .leading, spacing: largeText ? BCSpacing.lg : BCSpacing.md) {
                            Text("Waar kan ik u mee helpen?")
                                .font(et.heading)
                                .foregroundStyle(BCColors.textPrimary)
                                .padding(.horizontal, BCSpacing.lg)

                            VStack(spacing: largeText ? BCSpacing.md : BCSpacing.sm) {
                                BCBigTile(
                                    title: "Hulp vragen",
                                    subtitle: largeText ? nil : "Iemand komt u zo helpen",
                                    icon: "hand.raised.fill",
                                    color: BCColors.primary
                                ) {
                                    showRequestFlow = true
                                }

                                BCBigTile(
                                    title: "Vergoeding aanvragen",
                                    subtitle: largeText ? nil : "Laat hulpkosten vergoeden via de Wmo",
                                    icon: "eurosign.circle.fill",
                                    color: BCColors.success
                                ) {
                                    showWMOGuide = true
                                }

                                if !largeText {
                                    BCBigTile(
                                        title: "Bezoek aan de deur",
                                        subtitle: "Toon QR-code voor de buddy",
                                        icon: "qrcode",
                                        color: BCColors.level1
                                    ) {
                                        showQRCode = true
                                    }
                                }
                            }
                            .padding(.horizontal, BCSpacing.lg)
                        }
                        .padding(.top, BCSpacing.md)

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
        .sheet(isPresented: $showRequestFlow) {
            RequestHelpFlow()
        }
        .sheet(isPresented: $showWMOGuide) {
            WMOGuideView()
        }
        .sheet(isPresented: $showQRCode) {
            ElderlyQRCodeSheet()
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
                                    .fill(BCColors.primary)
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

    var body: some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                HStack {
                    BCStatusPill(label: task.status.label, color: task.status.color)
                    Spacer()
                    if let eta = task.assignedBuddyEtaMinutes {
                        Label("\(eta) min", systemImage: "clock.fill")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                }
                Text(task.category.displayName)
                    .font(BCTypography.elderlyHeading)
                    .foregroundStyle(BCColors.textPrimary)
                if let buddy = task.assignedBuddyName {
                    HStack(spacing: BCSpacing.sm) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(BCColors.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(buddy) komt naar u toe")
                                .font(BCTypography.headline)
                                .foregroundStyle(BCColors.textPrimary)
                            if let r = task.assignedBuddyRating {
                                BCRatingStars(value: r)
                            }
                        }
                    }
                } else {
                    Text("We zoeken een buddy voor u…")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                }
            }
        }
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

private let relativeFormatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.locale = Locale(identifier: "nl_NL")
    f.unitsStyle = .full
    return f
}()
