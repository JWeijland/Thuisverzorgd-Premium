import SwiftUI

struct FamilyDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var showRequestFlow = false
    @State private var showEditProfile = false
    @State private var showWMOGuide = false
    @State private var showRecentVisits = false
    @Binding var showLinking: Bool

    init(showLinking: Binding<Bool> = .constant(false)) {
        _showLinking = showLinking
    }

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Hallo \(appState.familyUser.firstName)", subtitle: "Familie-overzicht")

            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    // Switcher: kies welke oudere je beheert
                    if appState.familyLinkedElderly.count > 1 {
                        elderlySwitcher
                            .padding(.horizontal, BCSpacing.lg)
                            .padding(.top, BCSpacing.md)
                    }

                    // Linked elderly card
                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.sm) {
                            HStack {
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
                                    Text("\(appState.activeFamilyElderly.age) jaar — \(appState.activeFamilyElderly.address)")
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
                                StatPill(icon: "heart.fill", value: "12", label: "Bezoeken")
                                StatPill(icon: "star.fill", value: "4.9", label: "Tevreden")
                            }
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                    // Unreviewed banner
                    if appState.familyHasUnreviewedVisits {
                        Button { showRecentVisits = true } label: {
                            BCCard {
                                HStack(spacing: BCSpacing.md) {
                                    Image(systemName: "star.bubble.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(BCColors.warning)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Bezoek wacht op beoordeling")
                                            .font(BCTypography.bodyEmphasized)
                                            .foregroundStyle(BCColors.textPrimary)
                                        Text("\(appState.activeFamilyElderly.firstName) heeft nog niet beoordeeld — wil jij het doen?")
                                            .font(BCTypography.caption)
                                            .foregroundStyle(BCColors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(BCColors.textTertiary)
                                }
                            }
                            .overlay(alignment: .leading) {
                                UnevenRoundedRectangle(
                                    topLeadingRadius: BCRadius.lg,
                                    bottomLeadingRadius: BCRadius.lg,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 0,
                                    style: .continuous
                                )
                                .fill(BCColors.warning)
                                .frame(width: 4)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, BCSpacing.lg)
                    }

                    // Quick actions
                    BCSectionHeader(title: "Snel regelen")
                        .padding(.horizontal, BCSpacing.lg)

                    VStack(spacing: BCSpacing.sm) {
                        BCBigTile(
                            title: "Hulp aanvragen voor \(appState.activeFamilyElderly.firstName)",
                            subtitle: "Plan een buddy in",
                            icon: "hand.raised.fill",
                            color: BCColors.primary
                        ) {
                            showRequestFlow = true
                        }
                        BCBigTile(
                            title: "Vergoeding aanvragen via Wmo",
                            subtitle: "Gemeentelijke financiering voor hulpkosten",
                            icon: "eurosign.circle.fill",
                            color: BCColors.success
                        ) {
                            showWMOGuide = true
                        }
                        ZStack(alignment: .topTrailing) {
                            BCBigTile(
                                title: "Bekijk recente bezoeken",
                                subtitle: "Wat is er gebeurd",
                                icon: "list.bullet.rectangle",
                                color: BCColors.accent
                            ) {
                                showRecentVisits = true
                            }
                            if appState.familyHasUnreviewedVisits {
                                Circle()
                                    .fill(BCColors.danger)
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(BCColors.background, lineWidth: 2))
                                    .padding(10)
                            }
                        }
                        BCBigTile(
                            title: "Oudere koppelen",
                            subtitle: "Voeg moeder, vader of een andere oudere toe",
                            icon: "person.badge.plus",
                            color: BCColors.level1
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
        .sheet(isPresented: $showWMOGuide) {
            WMOGuideView()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(editingFamilyElderly: true)
        }
        .sheet(isPresented: $showRecentVisits) {
            FamilyVisitsSheet()
        }
    }

    // MARK: - Elderly switcher

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
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BCColors.primary)
                Text("U beheert: \(appState.activeFamilyElderly.firstName)")
                    .font(BCTypography.subheadline)
                    .foregroundStyle(BCColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BCColors.textSecondary)
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, BCSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(BCColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                            .stroke(BCColors.border, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Recent visits sheet (for family rating)

private struct FamilyVisitsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTask: ServiceTask? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recente bezoeken")
                            .font(BCTypography.title3)
                            .foregroundStyle(BCColors.textPrimary)
                        Text("Tik op een bezoek om een beoordeling te geven")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textTertiary)
                    }
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                    if appState.taskHistory.isEmpty {
                        BCCard {
                            Text("Nog geen bezoeken.")
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    } else {
                        VStack(spacing: BCSpacing.sm) {
                            ForEach(appState.taskHistory) { task in
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

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BCColors.primary)
            Text(value)
                .font(BCTypography.headline)
                .foregroundStyle(BCColors.textPrimary)
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
