import SwiftUI

// Getoond als sheet vanuit RoleSelectionView nadat een rol getikt is.
// Stap 1 → vraagt of gebruiker via een org werkt
// Stap 2 → bewijs uploaden (foto beschrijving in prototype)
// Stap 3 → wachtscherm tot admin goedkeurt
struct OrganizationOnboardingFlow: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let role: UserRole

    enum Step { case orgQuestion, orgSelect, proofUpload, pending }
    @State private var step: Step = .orgQuestion
    @State private var selectedOrg: Organization? = nil
    @State private var proofNote: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                BCColors.background.ignoresSafeArea()
                switch step {
                case .orgQuestion: orgQuestionView
                case .orgSelect:   orgSelectView
                case .proofUpload: proofUploadView
                case .pending:     pendingView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step == .orgQuestion {
                        Button("Annuleer") { dismiss() }
                            .tint(BCColors.primary)
                    }
                }
            }
        }
    }

    // MARK: - Stap 1: Organisatievraag

    /// Rol-afhankelijke teksten — een oudere "werkt" niet als ZZP'er.
    private var orgQuestionTitle: String {
        switch role {
        case .elderly: return "Meldt u zich aan vanuit een zorginstelling?"
        case .family:  return "Regelt u de zorg via een zorginstelling?"
        default:       return "Werk je via een zorgorganisatie?"
        }
    }

    private var orgQuestionSubtitle: String {
        switch role {
        case .elderly:
            return "Sommige zorginstellingen zijn partner van Thuisverzorgd. Cliënten van zo'n instelling kunnen direct instappen."
        case .family:
            return "Sommige zorginstellingen zijn partner van Thuisverzorgd. Regelt u zorg voor een familielid via zo'n instelling, dan kunt u direct instappen."
        default:
            return "Sommige zorgorganisaties zijn partner van Thuisverzorgd. Medewerkers kunnen dan direct instappen."
        }
    }

    private var orgYesLabel: String {
        switch role {
        case .buddy: return "Ja, via een organisatie"
        default:     return "Ja, via een zorginstelling"
        }
    }

    private var orgNoLabel: String {
        switch role {
        case .elderly: return "Nee, ik meld me individueel aan"
        case .family:  return "Nee, ik regel het zelf"
        default:       return "Nee, zelfstandig (ZZP)"
        }
    }

    private var orgQuestionView: some View {
        VStack(spacing: BCSpacing.xl) {
            Spacer()

            VStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle()
                        .fill(BCColors.primary.opacity(0.08))
                        .frame(width: 80, height: 80)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(BCColors.primary)
                }

                Text(orgQuestionTitle)
                    .font(BCTypography.largeTitle)
                    .foregroundStyle(BCColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(orgQuestionSubtitle)
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, BCSpacing.lg)

            Spacer()

            VStack(spacing: BCSpacing.md) {
                BCCTAButton(title: orgYesLabel) {
                    step = .orgSelect
                }

                BCSecondaryButton(title: orgNoLabel) {
                    proceedWithoutOrg()
                }
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.xl)
        }
    }

    // MARK: - Stap 2: Kies organisatie

    private var orgSelectView: some View {
        ScrollView {
            VStack(spacing: BCSpacing.lg) {
                VStack(spacing: BCSpacing.sm) {
                    Text("Kies je organisatie")
                        .font(BCTypography.largeTitle)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Selecteer de organisatie waarbij je werkt of als cliënt bent ingeschreven.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, BCSpacing.xl)
                .padding(.horizontal, BCSpacing.lg)

                VStack(spacing: BCSpacing.md) {
                    ForEach(appState.availableOrganizations.filter(\.isActive)) { org in
                        OrgCard(org: org, isSelected: selectedOrg?.id == org.id) {
                            selectedOrg = org
                        }
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                BCCTAButton(title: "Volgende", icon: "chevron.right") {
                    if selectedOrg != nil { step = .proofUpload }
                }
                .opacity(selectedOrg != nil ? 1.0 : 0.4)
                .disabled(selectedOrg == nil)
                .padding(.horizontal, BCSpacing.lg)
                .padding(.bottom, BCSpacing.xl)
            }
        }
    }

    // MARK: - Stap 3: Bewijs uploaden

    private var proofUploadView: some View {
        ScrollView {
            VStack(spacing: BCSpacing.lg) {
                VStack(spacing: BCSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(BCColors.primary.opacity(0.08))
                            .frame(width: 64, height: 64)
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(BCColors.primary)
                    }
                    Text("Upload je bewijs")
                        .font(BCTypography.largeTitle)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Stuur een foto van je personeelspas, arbeidscontract of cliëntenkaart van \(selectedOrg?.name ?? "de organisatie").")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, BCSpacing.xl)
                .padding(.horizontal, BCSpacing.lg)

                // In prototype: foto-upload simulatie via knop
                BCCard {
                    VStack(spacing: BCSpacing.md) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(BCColors.primary)
                            Text("Foto maken of uploaden")
                                .font(BCTypography.bodyEmphasized)
                                .foregroundStyle(BCColors.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(BCColors.textTertiary)
                        }

                        if !proofNote.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(BCColors.success)
                                Text(proofNote)
                                    .font(BCTypography.caption)
                                    .foregroundStyle(BCColors.textSecondary)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, BCSpacing.lg)
                .onTapGesture {
                    proofNote = "Personeelspas_\(selectedOrg?.shortName ?? "org").jpg"
                }

                if proofNote.isEmpty {
                    Text("Tik op het vak hierboven om een bestand te selecteren (in prototype: automatisch ingevuld).")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BCSpacing.lg)
                }

                BCCTAButton(title: "Indienen", icon: "checkmark") {
                    guard let org = selectedOrg else { return }
                    let note = proofNote.isEmpty ? "Document geüpload" : proofNote
                    appState.pendingRole = role
                    appState.submitMembershipRequest(organization: org, proofNote: note)
                    step = .pending
                }
                .padding(.horizontal, BCSpacing.lg)
                .padding(.bottom, BCSpacing.xl)
            }
        }
    }

    // MARK: - Stap 4: Wachtscherm

    private var pendingView: some View {
        VStack(spacing: BCSpacing.xl) {
            Spacer()

            VStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle()
                        .fill(BCColors.warning.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "clock.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(BCColors.warning)
                }

                Text("Aanvraag ingediend")
                    .font(BCTypography.largeTitle)
                    .foregroundStyle(BCColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Je bewijs wordt beoordeeld door het Thuisverzorgd team. Je ontvangt een melding zodra je aanvraag is goedgekeurd. Dit duurt meestal 1 werkdag.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, BCSpacing.lg)

            Spacer()

            // Demo snelkoppeling: direct goedkeuren
            VStack(spacing: BCSpacing.sm) {
                Text("Prototype — simuleer goedkeuring:")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)

                Button {
                    if let id = appState.currentUserMembership?.id {
                        appState.approveMembership(id: id)
                    }
                    appState.isOnboardingComplete = true
                    appState.hasSeenSplash = true
                    appState.currentRole = role
                    dismiss()
                } label: {
                    HStack(spacing: BCSpacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Goedkeuren (demo)")
                    }
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.primary)
                    .padding(.horizontal, BCSpacing.md)
                    .padding(.vertical, BCSpacing.sm)
                    .background(Capsule().fill(BCColors.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, BCSpacing.xl)
        }
    }

    // MARK: - Helpers

    private func proceedWithoutOrg() {
        // Geen organisatie → wis eventuele eerdere lidmaatschap-staat,
        // zodat isCordaanBuddy/isCordaanElderly gegarandeerd false zijn en
        // de zelfstandige (ZZP) onboarding wordt getoond.
        appState.currentUserMembership = nil
        appState.selectedOrganization = nil
        appState.pendingRole = nil
        appState.isOnboardingComplete = false
        appState.hasSeenSplash = true
        appState.currentRole = role
        dismiss()
    }
}

private struct OrgCard: View {
    let org: Organization
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle()
                        .fill(BCColors.primary.opacity(0.08))
                        .frame(width: 52, height: 52)
                    Image(systemName: org.logoSymbol)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(BCColors.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(org.name)
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Partner organisatie · actief")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? BCColors.accentDark : BCColors.textTertiary.opacity(0.5))
            }
            .padding(BCSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .stroke(isSelected ? BCColors.accent : Color.clear, lineWidth: 2)
            )
            .bcSoftShadow(.card)
        }
        .buttonStyle(.plain)
    }
}
