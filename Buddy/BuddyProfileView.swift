import SwiftUI

struct BuddyProfileView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Mijn profiel", subtitle: "Hoe ouderen je zien")

            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    // Header card
                    BCCard {
                        VStack(spacing: BCSpacing.md) {
                            ZStack {
                                Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 96, height: 96)
                                Image(systemName: appState.buddyUser.avatarSystemName)
                                    .font(.system(size: 48))
                                    .foregroundStyle(BCColors.primary)
                            }
                            VStack(spacing: 4) {
                                Text(appState.buddyUser.fullName)
                                    .font(BCTypography.title2)
                                    .foregroundStyle(BCColors.textPrimary)
                                Text(appState.buddyUser.study)
                                    .font(BCTypography.subheadline)
                                    .foregroundStyle(BCColors.textSecondary)
                                BCRatingStars(value: appState.buddyUser.ratingAverage, size: 16)
                            }
                            BCStatusPill(label: "\(appState.buddyUser.totalTasks) bezoeken", color: BCColors.primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                    // Availability toggle
                    BCCard {
                        Toggle(isOn: Binding(
                            get: { appState.isAvailableNow },
                            set: { appState.isAvailableNow = $0 }
                        )) {
                            HStack(spacing: BCSpacing.sm) {
                                Image(systemName: appState.isAvailableNow ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(appState.isAvailableNow ? BCColors.success : BCColors.textTertiary)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Beschikbaarheid")
                                        .font(BCTypography.bodyEmphasized)
                                        .foregroundStyle(BCColors.textPrimary)
                                    Text(appState.isAvailableNow ? "Beschikbaar voor taken" : "Niet beschikbaar")
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textSecondary)
                                }
                            }
                        }
                        .tint(BCColors.success)
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    preferencesCard

                    // Verifications
                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.sm) {
                            Text("Verificaties")
                                .font(BCTypography.headline)
                                .foregroundStyle(BCColors.textPrimary)
                            VerifyRow(label: "VOG (verklaring omtrent gedrag)", verified: appState.buddyUser.vogValid)
                            VerifyRow(label: "Kennismakingsgesprek", verified: true)
                            VerifyRow(label: "Bankrekening ••••\(appState.buddyUser.ibanLast4)", verified: true)
                            BCVOGBadge(expiresAt: appState.buddyUser.vogExpiresAt)
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    // Bio
                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.xs) {
                            Text("Over mij")
                                .font(BCTypography.headline)
                                .foregroundStyle(BCColors.textPrimary)
                            Text(appState.buddyUser.bio)
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    BCSectionHeader(title: "Recente beoordelingen")
                        .padding(.horizontal, BCSpacing.lg)
                    VStack(spacing: BCSpacing.sm) {
                        ForEach(MockData.reviewsForBuddy) { review in
                            BCCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: BCSpacing.sm) {
                                        BCRatingStars(value: Double(review.stars))
                                        Spacer()
                                        Text(dateFormatter.string(from: review.date))
                                            .font(BCTypography.caption)
                                            .foregroundStyle(BCColors.textTertiary)
                                    }
                                    Text(review.body)
                                        .font(BCTypography.body)
                                        .foregroundStyle(BCColors.textPrimary)
                                    Text("— \(review.authorName)")
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textSecondary)
                                }
                            }
                        }
                    }
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
    }

    private var preferencesCard: some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                HStack {
                    Label("Mijn diensten", systemImage: "checklist")
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                    Spacer()
                }
                if appState.buddyUser.offeredServices.isEmpty {
                    Text("Nog geen diensten gekozen.")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                } else {
                    Text(appState.buddyUser.offeredServices.sorted().joined(separator: " · "))
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }
}

private struct VerifyRow: View {
    let label: String
    let verified: Bool

    var body: some View {
        HStack {
            Image(systemName: verified ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .foregroundStyle(verified ? BCColors.success : BCColors.warning)
            Text(label)
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textPrimary)
            Spacer()
            Text(verified ? "Geverifieerd" : "Wacht op")
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(verified ? BCColors.success : BCColors.warning)
        }
    }
}

private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "nl_NL")
    f.dateFormat = "d MMM"
    return f
}()

#Preview {
    BuddyProfileView().environment(AppState())
}
