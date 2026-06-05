import SwiftUI

struct AdminTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            AdminBillingView()
                .tabItem { Label("Overzicht", systemImage: "chart.bar.fill") }

            AdminPhoneRequestView()
                .tabItem { Label("Telefonisch", systemImage: "phone.fill") }

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
                            AdminRow(icon: "bell.fill", label: "Meldingen") { }
                            Divider().padding(.leading, 56)
                            AdminRow(icon: "lock.fill", label: "Beveiliging") { }
                        }
                    }
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
