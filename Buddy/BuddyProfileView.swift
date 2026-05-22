import SwiftUI

struct BuddyProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showDiplomaSheet = false
    @State private var showPreferencesSheet = false

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
                                // Ratingcijfer niet tonen aan zorginstelling-buddies
                                if !appState.isCordaanBuddy {
                                    BCRatingStars(value: appState.buddyUser.ratingAverage, size: 16)
                                }
                            }
                            HStack(spacing: BCSpacing.sm) {
                                // Niveau niet tonen aan zorginstelling-buddies
                                if !appState.isCordaanBuddy {
                                    BCLevelBadge(level: appState.buddyUser.level)
                                }
                                BCStatusPill(label: "\(appState.buddyUser.totalTasks) bezoeken", color: BCColors.primary)
                            }
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

                    // Voorkeuren — alleen voor zelfstandige buddies (Cordaan-buddies zijn al gecertificeerd)
                    if !appState.isCordaanBuddy {
                        preferencesCard
                    }

                    // Verifications
                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.sm) {
                            Text("Verificaties")
                                .font(BCTypography.headline)
                                .foregroundStyle(BCColors.textPrimary)
                            VerifyRow(label: "ID-verificatie", verified: appState.buddyUser.kycVerified)
                            VerifyRow(label: "VOG (verklaring omtrent gedrag)", verified: appState.buddyUser.vogValid)
                            VerifyRow(label: "Bankrekening ••••\(appState.buddyUser.ibanLast4)", verified: true)
                            BCVOGBadge(expiresAt: appState.buddyUser.vogExpiresAt)
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    // Diploma — niet voor zorginstelling-buddies (zij zijn al gediplomeerd)
                    if !appState.isCordaanBuddy {
                        DiplomaCard(showSheet: $showDiplomaSheet)
                    }

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

                    // Reviews — niet zichtbaar voor zorginstelling-buddies
                    if !appState.isCordaanBuddy {
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
                    }

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
        .sheet(isPresented: $showDiplomaSheet) {
            DiplomaUploadSheet()
        }
        .sheet(isPresented: $showPreferencesSheet) {
            BuddyPreferencesView()
                .environment(appState)
        }
    }

    private var preferencesCard: some View {
        Button {
            showPreferencesSheet = true
        } label: {
            BCCard {
                HStack(spacing: BCSpacing.md) {
                    Image(systemName: "checklist")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(BCColors.primary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(BCColors.primary.opacity(0.12)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mijn voorkeuren")
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(BCColors.textPrimary)
                        Text(preferencesSummary)
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(BCColors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, BCSpacing.lg)
    }

    private var preferencesSummary: String {
        let totals = appState.buddyUser.servicePreferences.values.reduce(0) { $0 + $1.count }
        if totals == 0 {
            return "Nog geen voorkeuren — kies welke taken je wilt doen"
        }
        return "\(totals) taken gekozen — wijzig wanneer je wilt"
    }
}

// MARK: - Diploma card

private struct DiplomaCard: View {
    @Environment(AppState.self) private var appState
    @Binding var showSheet: Bool

    var body: some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                HStack {
                    Label("Diploma", systemImage: "graduationcap.fill")
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                    Spacer()
                    switch appState.diplomaStatus {
                    case .none:
                        EmptyView()
                    case .pending:
                        BCStatusPill(label: "In behandeling", color: BCColors.warning)
                    case .verified:
                        BCStatusPill(label: "Geverifieerd", color: BCColors.success)
                    }
                }

                switch appState.diplomaStatus {
                case .none:
                    Text("Heb je een erkend zorgdiploma? Upload het en sla niveau 1 en 2 over. De verkorte Basis Buddy cursus (18 min) is nog wel verplicht.")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                    Button { showSheet = true } label: {
                        Label("Diploma uploaden", systemImage: "arrow.up.doc.fill")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.primary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                .fill(BCColors.primary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)

                case .pending(let type):
                    HStack(spacing: BCSpacing.sm) {
                        ProgressView().tint(BCColors.warning)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type)
                                .font(BCTypography.bodyEmphasized)
                                .foregroundStyle(BCColors.textPrimary)
                            Text("Wordt geverifieerd door Thuisverzorgd…")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                    }

                case .verified(let type):
                    HStack(spacing: BCSpacing.sm) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(BCColors.success)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type)
                                .font(BCTypography.bodyEmphasized)
                                .foregroundStyle(BCColors.textPrimary)
                            if appState.shortCourseComplete {
                                Text("Niveau 3 ontgrendeld ✓")
                                    .font(BCTypography.captionEmphasized)
                                    .foregroundStyle(BCColors.success)
                            } else {
                                Text("Voltooi de verkorte Basis Buddy cursus om Niveau 3 te activeren.")
                                    .font(BCTypography.caption)
                                    .foregroundStyle(BCColors.warning)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }
}

// MARK: - Diploma upload sheet

private struct DiplomaUploadSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: String? = nil
    @State private var uploading = false

    private let diplomaTypes = [
        ("MBO niveau 2 — Helpende Zorg & Welzijn", "Basisniveau, Niveau 3 wordt ontgrendeld"),
        ("MBO niveau 3 — Verzorgende IG", "Verzorgend niveau, Niveau 3 wordt ontgrendeld"),
        ("MBO niveau 4 — Verpleegkunde", "Verpleegkundig niveau, Niveau 3 wordt ontgrendeld"),
        ("HBO-V — Verpleegkunde", "HBO bachelor, Niveau 3 wordt ontgrendeld"),
        ("BIG-geregistreerde verpleegkundige", "Volledige bevoegdheid, Niveau 3 wordt ontgrendeld"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.lg) {
                    VStack(alignment: .leading, spacing: BCSpacing.xs) {
                        Text("Welk diploma upload je?")
                            .font(BCTypography.title3)
                            .foregroundStyle(BCColors.textPrimary)
                        Text("Thuisverzorgd verifieert je diploma. Na goedkeuring kun je direct Niveau 3 taken aannemen — zodra je de verkorte Basis Buddy cursus (18 min) hebt afgerond.")
                            .font(BCTypography.body)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                    VStack(spacing: BCSpacing.sm) {
                        ForEach(diplomaTypes, id: \.0) { type, subtitle in
                            Button { selectedType = type } label: {
                                HStack(spacing: BCSpacing.md) {
                                    Image(systemName: "graduationcap.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(selectedType == type ? .white : BCColors.primary)
                                        .frame(width: 44, height: 44)
                                        .background(Circle().fill(selectedType == type ? BCColors.primary : BCColors.primary.opacity(0.10)))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(type)
                                            .font(BCTypography.bodyEmphasized)
                                            .foregroundStyle(BCColors.textPrimary)
                                            .multilineTextAlignment(.leading)
                                        Text(subtitle)
                                            .font(BCTypography.caption)
                                            .foregroundStyle(BCColors.textSecondary)
                                    }
                                    Spacer()
                                    if selectedType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(BCColors.primary)
                                    }
                                }
                                .padding(BCSpacing.md)
                                .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                                    .fill(BCColors.surface)
                                    .overlay(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                                        .stroke(selectedType == type ? BCColors.primary : BCColors.border,
                                                lineWidth: selectedType == type ? 1.5 : 1)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    if selectedType != nil {
                        BCCard {
                            HStack(spacing: BCSpacing.sm) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(BCColors.primary)
                                Text("In de demo wordt je diploma direct na 3 seconden geverifieerd. In de echte app controleert het Thuisverzorgd team je document binnen 1 werkdag.")
                                    .font(BCTypography.caption)
                                    .foregroundStyle(BCColors.textSecondary)
                            }
                        }
                        .padding(.horizontal, BCSpacing.lg)
                        .transition(.opacity)
                    }

                    Spacer().frame(height: BCSpacing.xl)
                }
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Diploma uploaden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleer") { dismiss() }.tint(BCColors.primary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    BCPrimaryButton(
                        title: uploading ? "Uploaden…" : "Bevestig & upload",
                        icon: "arrow.up.doc.fill",
                        isLoading: uploading
                    ) {
                        guard let type = selectedType else { return }
                        uploading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            appState.submitDiploma(type: type)
                            dismiss()
                        }
                    }
                    .disabled(selectedType == nil)
                    .opacity(selectedType == nil ? 0.45 : 1.0)
                    .padding(BCSpacing.lg)
                }
                .background(BCColors.background)
            }
            .animation(.easeInOut(duration: 0.2), value: selectedType)
        }
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
