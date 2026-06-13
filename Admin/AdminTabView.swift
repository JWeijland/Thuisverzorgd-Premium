import SwiftUI

struct AdminTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            AdminBillingView()
                .tabItem { Label("Overzicht", systemImage: "chart.bar.fill") }

            AdminPhoneRequestView()
                .tabItem { Label("Telefonisch", systemImage: "phone.fill") }

            AdminManagementView()
                .tabItem { Label("Beheer", systemImage: "person.2.badge.gearshape.fill") }

            AdminSettingsView()
                .tabItem { Label("Instellingen", systemImage: "gearshape.fill") }
        }
        .tint(BCColors.primary)
    }
}

// MARK: - Admin instellingen (placeholder)

private struct AdminSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Instellingen", subtitle: "Admin configuratie")
            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    BCCard {
                        VStack(spacing: 0) {
                            AdminRow(icon: "person.crop.circle.fill", label: "Admin account") { }
                            Divider().padding(.leading, 56)
                            AdminRow(icon: "lock.fill", label: "Beveiliging") { }
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    BCDisclosureSection(title: "Meldingen", icon: "bell.fill") {
                        BCToggleRow(title: "Meldingen toestaan", icon: "bell.fill",
                                    isOn: appState.notificationBinding(\.pushEnabled))
                        Divider().padding(.leading, BCSpacing.lg)
                        BCToggleRow(title: "Bezoek-updates", icon: "figure.walk",
                                    isOn: appState.notificationBinding(\.visitUpdates))
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    BCPrivacySection(consent: appState.analyticsConsentBinding)
                        .padding(.horizontal, BCSpacing.lg)

                    Button {
                        appState.resetToRoleSelection()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Uitloggen")
                        }
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.danger)
                        .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, BCSpacing.lg)
                }
                .padding(.top, BCSpacing.md)
                .padding(.bottom, BCSpacing.xl)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
    }
}

// MARK: - Admin beheer (dashboard, intakes/VOG, koppelcodes, gebruikers)

private struct AdminManagementView: View {
    @Environment(AppState.self) private var appState
    @State private var realStats: DBDashboardStats? = nil

    // Tellingen — uit echte view (live) of berekend uit de lokale staat (demo).
    private var buddiesCount: Int   { realStats?.buddies ?? appState.allBuddies.count }
    private var elderlyCount: Int   { realStats?.elderly ?? appState.allElderlyUsers.count }
    private var openCount: Int      { realStats?.openTasks ?? appState.openTasks.filter { $0.status == .open }.count }
    private var activeCount: Int    { realStats?.activeTasks ?? appState.openTasks.filter { [.accepted, .arrived, .inProgress].contains($0.status) }.count }
    private var completedCount: Int { realStats?.completedTasks ?? appState.taskHistory.count }
    private var pendingIntakes: Int { realStats?.pendingIntakes ?? appState.allBuddies.filter { !$0.intakeDone }.count }
    private var pendingVOG: Int     { realStats?.pendingVog ?? appState.allBuddies.filter { !$0.vogValid }.count }

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Beheer", subtitle: "Buddies, intakes & gebruikers")
            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    dashboardCard
                    intakeVogSection
                    linkingCodeSection
                    usersSection
                }
                .padding(.top, BCSpacing.md)
                .padding(.bottom, BCSpacing.xl)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .task {
            guard !appState.isDemoMode, appState.realUserId != nil else { return }
            realStats = try? await AdminService().fetchDashboardStats()
        }
    }

    // MARK: Dashboard

    private var dashboardCard: some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                Text("Dashboard")
                    .font(BCTypography.headline)
                    .foregroundStyle(BCColors.textPrimary)
                HStack(spacing: 0) {
                    StatTile(value: buddiesCount, label: "Buddies", color: BCColors.primary)
                    Divider().frame(height: 44)
                    StatTile(value: elderlyCount, label: "Ouderen", color: BCColors.primary)
                    Divider().frame(height: 44)
                    StatTile(value: completedCount, label: "Afgerond", color: BCColors.success)
                }
                Divider()
                HStack(spacing: 0) {
                    StatTile(value: openCount, label: "Open taken", color: BCColors.warning)
                    Divider().frame(height: 44)
                    StatTile(value: activeCount, label: "Lopend", color: BCColors.accent)
                    Divider().frame(height: 44)
                    StatTile(value: pendingIntakes + pendingVOG, label: "Te doen", color: BCColors.danger)
                }
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }

    // MARK: Intakes & VOG

    private var intakeVogSection: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            BCSectionHeader(title: "Intakes & VOG")
                .padding(.horizontal, BCSpacing.lg)
            if appState.allBuddies.isEmpty {
                BCCard {
                    BCEmptyState(icon: "person.crop.circle.badge.questionmark",
                                 title: "Geen buddies",
                                 message: "Er zijn nog geen buddies om te beoordelen.")
                }
                .padding(.horizontal, BCSpacing.lg)
            } else {
                ForEach(appState.allBuddies) { buddy in
                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.sm) {
                            Text(buddy.fullName)
                                .font(BCTypography.bodyEmphasized)
                                .foregroundStyle(BCColors.textPrimary)
                            HStack(spacing: BCSpacing.sm) {
                                BCStatusPill(label: buddy.vogValid ? "VOG geldig" : "VOG open",
                                             color: buddy.vogValid ? BCColors.success : BCColors.warning)
                                BCStatusPill(label: buddy.intakeDone ? "Intake ok" : "Intake open",
                                             color: buddy.intakeDone ? BCColors.success : BCColors.warning)
                                Spacer()
                            }
                            HStack(spacing: BCSpacing.sm) {
                                Button(buddy.vogValid ? "VOG afwijzen" : "VOG goedkeuren") {
                                    appState.adminSetVOG(buddyId: buddy.id, valid: !buddy.vogValid)
                                }
                                .font(BCTypography.captionEmphasized)
                                .foregroundStyle(BCColors.primary)
                                Button(buddy.intakeDone ? "Intake heropenen" : "Intake goedkeuren") {
                                    appState.adminSetIntake(buddyId: buddy.id, done: !buddy.intakeDone)
                                }
                                .font(BCTypography.captionEmphasized)
                                .foregroundStyle(BCColors.primary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)
                }
            }
        }
    }

    // MARK: Koppelcodes

    private var linkingCodeSection: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            BCSectionHeader(title: "Koppelcodes")
                .padding(.horizontal, BCSpacing.lg)
            BCCard {
                VStack(alignment: .leading, spacing: BCSpacing.sm) {
                    Text("Genereer een welkomstcode waarmee een familielid een oudere kan koppelen.")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                    ForEach(appState.allElderlyUsers) { elderly in
                        HStack {
                            Text(elderly.fullName)
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textPrimary)
                            Spacer()
                            Button("Code maken") {
                                appState.adminCreateLinkingCode(for: elderly)
                            }
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.primary)
                        }
                    }
                }
            }
            .padding(.horizontal, BCSpacing.lg)
        }
    }

    // MARK: Gebruikers + rollen

    private var usersSection: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            BCSectionHeader(title: "Gebruikers")
                .padding(.horizontal, BCSpacing.lg)
            BCCard {
                VStack(spacing: 0) {
                    ForEach(Array(allUsers.enumerated()), id: \.offset) { index, user in
                        if index > 0 { Divider() }
                        UserRoleRow(name: user.name, role: user.role) { newRole in
                            appState.adminSetRole(userId: user.id, role: newRole)
                        }
                    }
                }
            }
            .padding(.horizontal, BCSpacing.lg)
        }
    }

    private struct UserRow { let id: UUID; let name: String; let role: UserRole }

    private var allUsers: [UserRow] {
        appState.allBuddies.map { UserRow(id: $0.id, name: $0.fullName, role: .buddy) }
        + appState.allElderlyUsers.map { UserRow(id: $0.id, name: $0.fullName, role: .elderly) }
        + [UserRow(id: appState.familyUser.id, name: appState.familyUser.fullName, role: .family)]
    }
}

private struct StatTile: View {
    let value: Int
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(BCTypography.title2)
                .foregroundStyle(color)
            Text(label)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct UserRoleRow: View {
    let name: String
    let role: UserRole
    let onChange: (UserRole) -> Void

    private func roleLabel(_ r: UserRole) -> String {
        switch r {
        case .elderly: return "Oudere"
        case .buddy:   return "Buddy"
        case .family:  return "Familie"
        case .admin:   return "Admin"
        }
    }

    var body: some View {
        HStack(spacing: BCSpacing.sm) {
            Text(name)
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textPrimary)
            Spacer()
            Menu {
                ForEach(UserRole.allCases) { r in
                    Button(roleLabel(r)) { onChange(r) }
                }
            } label: {
                BCStatusPill(label: roleLabel(role), color: BCColors.primary)
            }
        }
        .padding(.vertical, BCSpacing.sm)
    }
}

private struct AdminRow: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BCColors.primary)
                    .frame(width: 32)
                Text(label)
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(BCColors.textTertiary)
            }
            .padding(.vertical, BCSpacing.md)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AdminTabView().environment(AppState())
}
