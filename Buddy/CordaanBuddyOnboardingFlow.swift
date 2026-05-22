import SwiftUI

// Verkorte onboarding voor Cordaan-medewerkers (4 stappen i.p.v. 14)
// Geen ZZP-stappen, geen cursussen, geen tarieven.
struct CordaanBuddyOnboardingFlow: View {
    @Environment(AppState.self) private var appState

    @State private var step = 0
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var bio = ""
    @State private var availableDays: Set<String> = []
    @State private var agreedToRules = false

    private let days = ["Ma", "Di", "Wo", "Do", "Vr", "Za", "Zo"]

    var body: some View {
        ZStack {
            BCColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                orgBadge
                    .padding(.top, BCSpacing.md)

                ScrollView {
                    VStack(spacing: BCSpacing.lg) {
                        switch step {
                        case 0: welcomeStep
                        case 1: personalInfoStep
                        case 2: availabilityStep
                        case 3: rulesStep
                        default: EmptyView()
                        }
                    }
                    .padding(BCSpacing.lg)
                    .padding(.bottom, BCSpacing.xxl)
                }

                bottomBar
            }
        }
    }

    // MARK: - Voortgangsbalk

    private var progressBar: some View {
        HStack(spacing: BCSpacing.xs) {
            ForEach(0..<4) { i in
                Capsule()
                    .fill(i <= step ? BCColors.primary : BCColors.border)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
    }

    private var orgBadge: some View {
        HStack(spacing: BCSpacing.xs) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 12, weight: .semibold))
            Text("Cordaan medewerker")
                .font(BCTypography.captionEmphasized)
        }
        .foregroundStyle(BCColors.primary)
        .padding(.horizontal, BCSpacing.md)
        .padding(.vertical, BCSpacing.xs)
        .background(Capsule().fill(BCColors.primary.opacity(0.10)))
    }

    // MARK: - Stap 0: Welkom

    private var welcomeStep: some View {
        VStack(spacing: BCSpacing.lg) {
            Spacer().frame(height: BCSpacing.md)

            ZStack {
                Circle()
                    .fill(BCColors.primary.opacity(0.08))
                    .frame(width: 96, height: 96)
                Image(systemName: "building.2.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(BCColors.primary)
            }

            VStack(spacing: BCSpacing.sm) {
                Text("Welkom, Cordaan medewerker!")
                    .font(BCTypography.largeTitle)
                    .foregroundStyle(BCColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Via Thuisverzorgt kun je als Cordaan-medewerker direct ingepland worden bij cliënten. Je registratie is een stuk korter dan voor zelfstandige buddies.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: BCSpacing.sm) {
                HighlightRow(icon: "xmark.circle", text: "Geen cursussen — jouw kwalificaties staan al vast")
                HighlightRow(icon: "xmark.circle", text: "Geen tarieven instellen — dit regelt Cordaan")
                HighlightRow(icon: "checkmark.circle.fill", text: "Snel klaar — 3 korte stappen")
            }
            .padding(BCSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg).fill(BCColors.surfaceMuted)
            )
        }
    }

    // MARK: - Stap 1: Persoonsgegevens

    private var personalInfoStep: some View {
        VStack(alignment: .leading, spacing: BCSpacing.md) {
            Text("Jouw gegevens")
                .font(BCTypography.largeTitle)
                .foregroundStyle(BCColors.textPrimary)
            Text("Deze gegevens zijn zichtbaar voor cliënten.")
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textSecondary)

            BCCard {
                VStack(spacing: BCSpacing.md) {
                    OnboardingField(label: "Voornaam", placeholder: "Bijv. Petra", text: $firstName)
                    Divider()
                    OnboardingField(label: "Achternaam", placeholder: "Bijv. Smits", text: $lastName)
                    Divider()
                    OnboardingField(label: "Telefoonnummer", placeholder: "06 12 34 56 78",
                                   text: $phone, keyboard: .phonePad)
                }
            }

            BCCard {
                VStack(alignment: .leading, spacing: BCSpacing.sm) {
                    Label("Korte introductie (optioneel)", systemImage: "text.bubble")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                    TextField("Vertel iets over jezelf...", text: $bio, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textPrimary)
                }
            }
        }
    }

    // MARK: - Stap 2: Beschikbaarheid

    private var availabilityStep: some View {
        VStack(alignment: .leading, spacing: BCSpacing.md) {
            Text("Beschikbaarheid")
                .font(BCTypography.largeTitle)
                .foregroundStyle(BCColors.textPrimary)
            Text("Op welke dagen ben je beschikbaar? Dit helpt cliënten je te vinden.")
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textSecondary)

            BCCard {
                VStack(alignment: .leading, spacing: BCSpacing.md) {
                    Text("Selecteer je beschikbare dagen")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.textSecondary)

                    HStack(spacing: BCSpacing.sm) {
                        ForEach(days, id: \.self) { day in
                            let selected = availableDays.contains(day)
                            Button {
                                if selected { availableDays.remove(day) }
                                else { availableDays.insert(day) }
                            } label: {
                                Text(day)
                                    .font(BCTypography.captionEmphasized)
                                    .foregroundStyle(selected ? .white : BCColors.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: BCRadius.sm)
                                            .fill(selected ? BCColors.primary : BCColors.surfaceMuted)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if availableDays.isEmpty {
                Text("Selecteer minimaal één dag om verder te gaan.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.warning)
            }
        }
    }

    // MARK: - Stap 3: Huisregels

    private var rulesStep: some View {
        VStack(alignment: .leading, spacing: BCSpacing.md) {
            Text("Huisregels")
                .font(BCTypography.largeTitle)
                .foregroundStyle(BCColors.textPrimary)

            BCCard {
                VStack(alignment: .leading, spacing: BCSpacing.md) {
                    RuleRow(number: "1", text: "Je bent altijd op tijd, of geeft tijdig afmelding door.")
                    Divider()
                    RuleRow(number: "2", text: "Alle zorghandelingen vallen onder je Cordaan-bevoegdheden. Voer niets uit buiten je kwalificaties.")
                    Divider()
                    RuleRow(number: "3", text: "Vertrouwelijke informatie over cliënten deel je niet buiten de zorgketen.")
                    Divider()
                    RuleRow(number: "4", text: "Check altijd in via de app bij aankomst bij de cliënt.")
                    Divider()
                    RuleRow(number: "5", text: "Meld problemen of incidenten direct bij Cordaan én via de app.")
                }
            }

            Button {
                agreedToRules.toggle()
            } label: {
                HStack(spacing: BCSpacing.md) {
                    Image(systemName: agreedToRules ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(agreedToRules ? BCColors.primary : BCColors.textTertiary)
                    Text("Ik ga akkoord met de huisregels van Thuisverzorgt")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textPrimary)
                    Spacer()
                }
                .padding(BCSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: BCRadius.lg)
                        .fill(BCColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: BCRadius.lg)
                                .stroke(agreedToRules ? BCColors.primary : BCColors.border, lineWidth: 1.5)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Onderste balk

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: BCSpacing.md) {
                if step > 0 {
                    Button {
                        withAnimation { step -= 1 }
                    } label: {
                        Text("Terug")
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(BCColors.primary)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(
                                RoundedRectangle(cornerRadius: BCRadius.lg)
                                    .stroke(BCColors.primary, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    if step < 3 {
                        withAnimation { step += 1 }
                    } else {
                        finishOnboarding()
                    }
                } label: {
                    Text(step < 3 ? "Volgende" : "Klaar — ga aan de slag!")
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(nextEnabled ? .white : BCColors.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: BCRadius.lg)
                                .fill(nextEnabled ? BCColors.primary : BCColors.border)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!nextEnabled)
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.vertical, BCSpacing.md)
        }
        .background(BCColors.surface)
    }

    private var nextEnabled: Bool {
        switch step {
        case 0: return true
        case 1: return !firstName.isEmpty && !lastName.isEmpty
        case 2: return !availableDays.isEmpty
        case 3: return agreedToRules
        default: return false
        }
    }

    private func finishOnboarding() {
        appState.isOnboardingComplete = true
        appState.showToast(text: "Welkom bij Thuisverzorgt, \(firstName)!", icon: "building.2.fill")
    }
}

// MARK: - Helper subviews

private struct HighlightRow: View {
    let icon: String
    let text: String
    var isPositive: Bool { icon.contains("checkmark") }

    var body: some View {
        HStack(spacing: BCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isPositive ? BCColors.success : BCColors.textTertiary)
            Text(text)
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textPrimary)
            Spacer()
        }
    }
}

private struct RuleRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: BCSpacing.md) {
            Text(number)
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(BCColors.primary))
            Text(text)
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

private struct OnboardingField: View {
    let label: String
    let placeholder: String
    let text: Binding<String>
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textPrimary)
        }
    }
}

#Preview {
    CordaanBuddyOnboardingFlow()
        .environment(AppState())
}
