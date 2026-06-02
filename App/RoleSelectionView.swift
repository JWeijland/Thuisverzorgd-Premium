import SwiftUI

struct RoleSelectionView: View {
    @Environment(AppState.self) private var appState
    @State private var orgFlowRole: UserRole? = nil

    var body: some View {
        ZStack {
            BCColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: BCSpacing.lg) {
                        introBlock
                            .padding(.top, BCSpacing.xl)

                        VStack(spacing: BCSpacing.md) {
                            ForEach([UserRole.elderly, .buddy, .family], id: \.id) { role in
                                RoleCard(role: role) {
                                    // Alleen buddy's kunnen via een zorgorganisatie werken;
                                    // ouderen en familie stappen direct in (geen jargon-vraag).
                                    if role == .buddy {
                                        orgFlowRole = role
                                    } else {
                                        enterDirectly(as: role)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, BCSpacing.lg)

                        trustStrip
                            .padding(.horizontal, BCSpacing.lg)
                            .padding(.top, BCSpacing.lg)

                        prototypeNote
                            .padding(.horizontal, BCSpacing.lg)
                            .padding(.bottom, BCSpacing.xl)
                    }
                }
            }
        }
        .sheet(item: $orgFlowRole) { role in
            OrganizationOnboardingFlow(role: role)
        }
    }

    /// Ouderen/familie zonder organisatie: meteen de juiste rol in (zelfstandig pad).
    private func enterDirectly(as role: UserRole) {
        appState.currentUserMembership = nil
        appState.selectedOrganization = nil
        appState.pendingRole = nil
        appState.isOnboardingComplete = false
        appState.hasSeenSplash = true
        appState.currentRole = role
    }

    private var header: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [BCColors.navy900, BCColors.navy700],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            HStack(spacing: BCSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous)
                        .fill(.white.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: "house.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(BCColors.accent)
                }
                (Text("Thuis").foregroundStyle(.white)
                 + Text("verzorgd").foregroundStyle(BCColors.accent))
                    .font(BCTypography.titleEmphasized)
                Spacer()
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.vertical, BCSpacing.md)
        }
        .frame(height: 64)
    }

    private var introBlock: some View {
        VStack(spacing: BCSpacing.sm) {
            Text("Welkom bij Thuisverzorgd")
                .font(BCTypography.largeTitle)
                .foregroundStyle(BCColors.textPrimary)
                .multilineTextAlignment(.center)
            Text("Hulp om de hoek, met een hart erbij. Kies hieronder hoe u Thuisverzorgd wilt gebruiken.")
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BCSpacing.lg)
        }
    }

    private var trustStrip: some View {
        HStack(spacing: BCSpacing.md) {
            TrustBadge(icon: "checkmark.shield.fill", label: "VOG\ngescreend")
            TrustBadge(icon: "lock.fill", label: "AVG\nveilig")
            TrustBadge(icon: "hand.raised.fill", label: "Verzekerde\ndienst")
        }
    }

    private var prototypeNote: some View {
        VStack(spacing: BCSpacing.md) {
            Text("Prototype — selecteer een rol om de bijbehorende app-ervaring te bekijken.")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, BCSpacing.lg)

            // Demo shortcuts
            VStack(spacing: BCSpacing.sm) {
                DemoButton(label: "Demo: ZZP Buddy kaart", icon: "bolt.fill") {
                    appState.isDemoMode = true
                    appState.hasSeenSplash = true
                    appState.isOnboardingComplete = true
                    appState.currentRole = .buddy
                }
                DemoButton(label: "Demo: Cordaan Buddy", icon: "building.2.fill") {
                    appState.activateCordaanDemo(role: .buddy)
                }
                DemoButton(label: "Demo: Cordaan Cliënt", icon: "building.2.fill") {
                    appState.activateCordaanDemo(role: .elderly)
                }
                DemoButton(label: "Admin dashboard", icon: "gearshape.2.fill") {
                    appState.isDemoMode = true
                    appState.hasSeenSplash = true
                    appState.isOnboardingComplete = true
                    appState.currentRole = .admin
                }
            }
        }
    }
}

private struct DemoButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(BCTypography.captionEmphasized)
            }
            .foregroundStyle(BCColors.primary)
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, BCSpacing.sm)
            .background(Capsule().fill(BCColors.primary.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }
}

private struct RoleCard: View {
    let role: UserRole
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .fill(BCColors.navy900)
                        .frame(width: 60, height: 60)
                    Image(systemName: role.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName)
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.navy900)
                    Text(role.subtitle)
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: BCSpacing.sm)
                ZStack {
                    Circle()
                        .fill(BCColors.accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(BCColors.green600)
                }
            }
            .padding(BCSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.xl, style: .continuous)
                    .fill(BCColors.surface)
            )
            .bcSoftShadow(.card)
        }
        .buttonStyle(.plain)
    }
}

private struct TrustBadge: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: BCSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BCColors.primary)
            Text(label)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BCSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                .fill(BCColors.surfaceMuted)
        )
    }
}

#Preview {
    RoleSelectionView()
        .environment(AppState())
}
