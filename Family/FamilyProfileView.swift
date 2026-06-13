import SwiftUI

struct FamilyProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showLinking = false

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Profiel", subtitle: "Familielid")

            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    BCCard {
                        HStack(spacing: BCSpacing.md) {
                            ZStack {
                                Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 64, height: 64)
                                Text(initials)
                                    .font(BCTypography.title3)
                                    .foregroundStyle(BCColors.primary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.familyUser.fullName)
                                    .font(BCTypography.title3)
                                    .foregroundStyle(BCColors.textPrimary)
                                Text(appState.familyUser.relationship)
                                    .font(BCTypography.subheadline)
                                    .foregroundStyle(BCColors.textSecondary)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.sm) {
                            Label("Gekoppelde personen", systemImage: "link")
                                .font(BCTypography.headline)
                                .foregroundStyle(BCColors.textPrimary)
                            ForEach(Array(appState.familyLinkedElderly.enumerated()), id: \.element.id) { index, elderly in
                                HStack(spacing: BCSpacing.sm) {
                                    ZStack {
                                        Circle().fill(BCColors.primary.opacity(0.10)).frame(width: 40, height: 40)
                                        Text(String(elderly.firstName.prefix(1)))
                                            .font(BCTypography.bodyEmphasized)
                                            .foregroundStyle(BCColors.primary)
                                    }
                                    Text(elderly.fullName)
                                        .font(BCTypography.body)
                                        .foregroundStyle(BCColors.textPrimary)
                                    Spacer()
                                    if index == appState.activeFamilyElderlyIndex {
                                        BCStatusPill(label: "Actief", color: BCColors.success)
                                    } else {
                                        Button("Beheer") {
                                            appState.activeFamilyElderlyIndex = index
                                        }
                                        .font(BCTypography.captionEmphasized)
                                        .foregroundStyle(BCColors.primary)
                                    }
                                }
                            }
                            BCSecondaryButton(title: "Nog iemand koppelen", icon: "person.fill.badge.plus") {
                                showLinking = true
                            }
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    BCDisclosureSection(title: "Meldingen", icon: "bell.fill") {
                        BCToggleRow(title: "Meldingen toestaan", icon: "bell.fill",
                                    isOn: appState.notificationBinding(\.pushEnabled))
                        Divider().padding(.leading, BCSpacing.lg)
                        BCToggleRow(title: "Melding bij elk bezoek", icon: "figure.walk",
                                    isOn: appState.notificationBinding(\.visitUpdates))
                        Divider().padding(.leading, BCSpacing.lg)
                        BCToggleRow(title: "Melding bij SOS-alarm", icon: "exclamationmark.triangle.fill",
                                    isOn: appState.notificationBinding(\.sosAlerts))
                        Divider().padding(.leading, BCSpacing.lg)
                        BCToggleRow(title: "Maandrapport per e-mail", icon: "envelope.fill",
                                    isOn: appState.notificationBinding(\.monthlyReport))
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    BCPrivacySection(consent: appState.analyticsConsentBinding)
                        .padding(.horizontal, BCSpacing.lg)

                    Button {
                        appState.resetToRoleSelection()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Wissel rol (prototype)")
                        }
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.primary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.sm)

                    Spacer().frame(height: BCSpacing.xl)
                }
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .sheet(isPresented: $showLinking) {
            FamilyLinkingView()
        }
    }

    private var initials: String {
        let f = appState.familyUser.firstName.first.map(String.init) ?? ""
        let l = appState.familyUser.lastName.first.map(String.init) ?? ""
        return f + l
    }
}

#Preview {
    FamilyProfileView().environment(AppState())
}
