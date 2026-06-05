import SwiftUI

struct FamilyDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var showRequestFlow = false
    @State private var showEditProfile = false
    @State private var showRecentVisits = false
    @Binding var showLinking: Bool

    init(showLinking: Binding<Bool> = .constant(false)) {
        _showLinking = showLinking
    }

    // Cijfers afgeleid uit de bezoeken van de oudere die je nu beheert,
    // zodat wisselen van naaste zichtbaar andere data toont.
    private var elderlyVisits: [ServiceTask] {
        appState.taskHistory.filter { $0.elderlyName == appState.activeFamilyElderly.firstName }
    }
    private var satisfactionText: String {
        let ratings = elderlyVisits.compactMap { $0.assignedBuddyRating }
        guard !ratings.isEmpty else { return "—" }
        let avg = ratings.reduce(0, +) / Double(ratings.count)
        return String(format: "%.1f", avg).replacingOccurrences(of: ".", with: ",")
    }
    private var regularBuddyCount: Int {
        Set(elderlyVisits.compactMap { $0.assignedBuddyName }).count
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    // Beheer-switcher: wíé je beheert — altijd bovenaan
                    elderlySwitcher
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.top, BCSpacing.md)

                    // Naaste-card
                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.md) {
                            HStack(spacing: BCSpacing.md) {
                                ZStack {
                                    Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 56, height: 56)
                                    Text(String(appState.activeFamilyElderly.firstName.prefix(1)))
                                        .font(BCTypography.title3)
                                        .foregroundStyle(BCColors.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(appState.activeFamilyElderly.fullName)
                                        .font(BCTypography.headline)
                                        .foregroundStyle(BCColors.textPrimary)
                                    Text("\(appState.activeFamilyElderly.age) jaar · \(appState.activeFamilyElderly.address)")
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textSecondary)
                                }
                                Spacer()
                                Button {
                                    showEditProfile = true
                                } label: {
                                    Label("Aanpassen", systemImage: "pencil")
                                        .font(BCTypography.captionEmphasized)
                                        .foregroundStyle(BCColors.primary)
                                        .padding(.horizontal, BCSpacing.sm)
                                        .padding(.vertical, BCSpacing.xs)
                                        .background(Capsule().fill(BCColors.primary.opacity(0.08)))
                                }
                                .buttonStyle(.plain)
                            }
                            Divider()
                            HStack(spacing: BCSpacing.md) {
                                StatPill(icon: "house.fill", value: "\(elderlyVisits.count)", label: "Bezoeken", color: BCColors.primary)
                                StatPill(icon: "star.fill", value: satisfactionText, label: "Tevreden", color: BCColors.success)
                                StatPill(icon: "person.2.fill", value: "\(regularBuddyCount)", label: "Vaste buddies", color: BCColors.navy500)
                            }
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    // Groene hulp-hero
                    BCHelpHeroCard(
                        eyebrow: "VOOR \(appState.activeFamilyElderly.firstName.uppercased())",
                        title: "Hulp aanvragen",
                        subtitle: "Plan een vertrouwde buddy in voor \(appState.activeFamilyElderly.firstName).",
                        icon: "hand.raised.fill"
                    ) {
                        showRequestFlow = true
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    // Nudge: bezoek wacht op beoordeling
                    if appState.familyHasUnreviewedVisits {
                        Button { showRecentVisits = true } label: {
                            HStack(spacing: BCSpacing.md) {
                                ZStack {
                                    Circle().fill(BCColors.warning.opacity(0.14)).frame(width: 40, height: 40)
                                    Image(systemName: "star.bubble.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(BCColors.warning)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bezoek wacht op beoordeling")
                                        .font(BCTypography.bodyEmphasized)
                                        .foregroundStyle(BCColors.textPrimary)
                                    Text("\(appState.activeFamilyElderly.firstName) heeft nog niet beoordeeld — wil jij het doen?")
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textSecondary)
                                }
                                Spacer(minLength: BCSpacing.sm)
                                Circle()
                                    .fill(BCColors.danger)
                                    .frame(width: 10, height: 10)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(BCColors.textTertiary)
                            }
                            .padding(BCSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                                    .fill(BCColors.surface)
                            )
                            .bcSoftShadow(.card)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, BCSpacing.lg)
                    }

                    // Snel regelen
                    BCSectionHeader(title: "Snel regelen")
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.top, BCSpacing.xs)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: BCSpacing.sm),
                                  GridItem(.flexible(), spacing: BCSpacing.sm)],
                        spacing: BCSpacing.sm
                    ) {
                        ZStack(alignment: .topTrailing) {
                            BCQuickTile(
                                title: "Recente bezoeken",
                                subtitle: "Wat is er gebeurd",
                                icon: "list.bullet.rectangle",
                                color: BCColors.accentDark
                            ) {
                                showRecentVisits = true
                            }
                            if appState.familyHasUnreviewedVisits {
                                Circle()
                                    .fill(BCColors.danger)
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(BCColors.surface, lineWidth: 2))
                                    .padding(12)
                            }
                        }
                        BCQuickTile(
                            title: "Oudere koppelen",
                            subtitle: "Voeg een naaste toe",
                            icon: "person.badge.plus",
                            color: BCColors.navy500
                        ) {
                            showLinking = true
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    Spacer().frame(height: BCSpacing.xl)
                }
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .sheet(isPresented: $showRequestFlow) {
            RequestHelpFlow(onBehalfOf: appState.activeFamilyElderly)
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(editingFamilyElderly: true)
        }
        .sheet(isPresented: $showRecentVisits) {
            FamilyVisitsSheet()
        }
    }

    // MARK: - Navy header

    private var header: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [BCColors.navy900, BCColors.navy700],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

            HStack(alignment: .center, spacing: BCSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Familie-overzicht")
                        .font(BCTypography.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                    Text("Hallo \(appState.familyUser.firstName)")
                        .font(BCTypography.titleEmphasized)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Spacer()
                ZStack {
                    Circle().fill(.white.opacity(0.16))
                    Text(String(appState.familyUser.firstName.prefix(1)))
                        .font(BCTypography.title3)
                        .foregroundStyle(.white)
                }
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.md)
        }
        .frame(height: 64)
    }

    // MARK: - Beheer-switcher

    private var elderlySwitcher: some View {
        Menu {
            ForEach(Array(appState.familyLinkedElderly.enumerated()), id: \.element.id) { index, elderly in
                Button {
                    appState.activeFamilyElderlyIndex = index
                } label: {
                    if index == appState.activeFamilyElderlyIndex {
                        Label(elderly.fullName, systemImage: "checkmark")
                    } else {
                        Text(elderly.fullName)
                    }
                }
            }
        } label: {
            HStack(spacing: BCSpacing.sm) {
                ZStack {
                    Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 32, height: 32)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BCColors.primary)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("U beheert")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                    Text(appState.activeFamilyElderly.firstName)
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                }
                Spacer()
                if appState.familyLinkedElderly.count > 1 {
                    HStack(spacing: BCSpacing.xs) {
                        Text("Wissel")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(BCColors.primary)
                    }
                }
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, BCSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.surface)
            )
            .bcSoftShadow(.card)
        }
        .disabled(appState.familyLinkedElderly.count <= 1)
    }
}

// MARK: - Recent visits sheet (for family rating)

private struct FamilyVisitsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTask: ServiceTask? = nil

    private var visits: [ServiceTask] {
        appState.taskHistory.filter { $0.elderlyName == appState.activeFamilyElderly.firstName }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recente bezoeken")
                            .font(BCTypography.title3)
                            .foregroundStyle(BCColors.textPrimary)
                        Text("Bezoeken bij \(appState.activeFamilyElderly.firstName) — tik om te beoordelen")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textTertiary)
                    }
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                    if visits.isEmpty {
                        BCCard {
                            Text("Nog geen bezoeken.")
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    } else {
                        VStack(spacing: BCSpacing.sm) {
                            ForEach(visits) { task in
                                let rated = appState.taskRatings[task.id]
                                let needsReview = rated == nil && !appState.skippedReviews.contains(task.id)
                                Button { selectedTask = task } label: {
                                    BCCard {
                                        HStack(spacing: BCSpacing.md) {
                                            Image(systemName: task.category.icon)
                                                .font(.system(size: 22, weight: .semibold))
                                                .foregroundStyle(BCColors.primary)
                                                .frame(width: 44, height: 44)
                                                .background(Circle().fill(BCColors.primary.opacity(0.10)))
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(task.category.displayName)
                                                    .font(BCTypography.bodyEmphasized)
                                                    .foregroundStyle(BCColors.textPrimary)
                                                if let buddy = task.assignedBuddyName {
                                                    Text("Met \(buddy)")
                                                        .font(BCTypography.caption)
                                                        .foregroundStyle(BCColors.textSecondary)
                                                }
                                                if let date = task.completedAt {
                                                    Text(date.formatted(date: .long, time: .omitted))
                                                        .font(BCTypography.caption)
                                                        .foregroundStyle(BCColors.textTertiary)
                                                }
                                                HStack(spacing: 3) {
                                                    ForEach(1...5, id: \.self) { star in
                                                        Image(systemName: star <= (rated ?? 0) ? "star.fill" : "star")
                                                            .font(.system(size: 10, weight: .regular))
                                                            .foregroundStyle(star <= (rated ?? 0) ? BCColors.warning : BCColors.border)
                                                    }
                                                }
                                                .padding(.top, 1)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(BCColors.textTertiary)
                                        }
                                    }
                                    .overlay(alignment: .leading) {
                                        if needsReview {
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

                    Spacer().frame(height: BCSpacing.xl)
                }
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Bezoeken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
        .sheet(item: $selectedTask) { task in
            FamilyRatingSheet(task: task)
        }
    }
}

// MARK: - Rating sheet for family

private struct FamilyRatingSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let task: ServiceTask
    @State private var selectedStars: Int = 0
    @State private var reviewText: String = ""
    @State private var submitted = false

    private var alreadyRated: Bool { appState.taskRatings[task.id] != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BCSpacing.xl) {
                    VStack(spacing: BCSpacing.md) {
                        ZStack {
                            Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 80, height: 80)
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(BCColors.primary)
                        }
                        Text("Hoe was het bezoek van \(task.assignedBuddyName ?? "de buddy")?")
                            .font(BCTypography.title3)
                            .foregroundStyle(BCColors.textPrimary)
                            .multilineTextAlignment(.center)
                        Text(task.category.displayName)
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                    .padding(.top, BCSpacing.lg)
                    .padding(.horizontal, BCSpacing.lg)

                    if submitted || alreadyRated {
                        VStack(spacing: BCSpacing.sm) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(BCColors.warning)
                            Text("Bedankt voor de beoordeling!")
                                .font(BCTypography.headline)
                                .foregroundStyle(BCColors.textPrimary)
                        }
                        .padding(BCSpacing.xl)
                    } else {
                        VStack(spacing: BCSpacing.lg) {
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
                                        .font(BCTypography.body)
                                        .foregroundStyle(BCColors.textPrimary)
                                }
                                .padding(.horizontal, BCSpacing.lg)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))

                                BCPrimaryButton(title: "Verstuur beoordeling", icon: "star.fill") {
                                    appState.rateTask(taskId: task.id, stars: selectedStars, body: reviewText)
                                    withAnimation { submitted = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
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

                    Spacer().frame(height: BCSpacing.xl)
                }
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Beoordeling geven")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
        .onAppear { selectedStars = appState.taskRatings[task.id] ?? 0 }
    }
}

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = BCColors.primary

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(BCTypography.headline)
                .foregroundStyle(color)
            Text(label)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FamilyDashboardView().environment(AppState())
}
