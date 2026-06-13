import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var mode: AuthMode = .login

    // Login
    @State private var loginEmail = ""
    @State private var loginPassword = ""

    // Register
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedRole: UserRole = .elderly
    @State private var registerEmail = ""
    @State private var registerPassword = ""

    @State private var errorMessage: String? = nil
    @State private var infoMessage: String? = nil
    @State private var isLoading = false

    enum AuthMode: String, CaseIterable {
        case login = "Inloggen"
        case register = "Registreren"
    }

    var body: some View {
        ZStack {
            BCColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    pageHeader

                    Picker("Modus", selection: $mode) {
                        ForEach(AuthMode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.lg)
                    .padding(.bottom, BCSpacing.md)
                    .onChange(of: mode) { _, _ in errorMessage = nil; infoMessage = nil }

                    if mode == .login {
                        loginSection
                    } else {
                        registerSection
                    }

                    demoShortcut

                    if let info = infoMessage {
                        HStack(spacing: BCSpacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(info)
                        }
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.primary)
                        .multilineTextAlignment(.leading)
                        .padding(BCSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                .fill(BCColors.primary.opacity(0.08))
                        )
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.bottom, BCSpacing.lg)
                    }

                    if let error = errorMessage {
                        HStack(spacing: BCSpacing.sm) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(error)
                        }
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.danger)
                        .multilineTextAlignment(.leading)
                        .padding(BCSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                .fill(BCColors.danger.opacity(0.08))
                        )
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.bottom, BCSpacing.lg)
                    }
                }
            }

            if isLoading {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
    }

    // MARK: - Header

    private var pageHeader: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [BCColors.navy900, BCColors.navy700],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            VStack(spacing: BCSpacing.sm) {
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
                }
                .padding(.top, BCSpacing.xl)
                Text("Hulp om de hoek, met een hart erbij.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, BCSpacing.lg)
            }
        }
    }

    // MARK: - Login

    private var loginSection: some View {
        VStack(spacing: BCSpacing.md) {
            AuthField(
                label: "E-mailadres",
                placeholder: "naam@voorbeeld.nl",
                text: $loginEmail,
                keyboard: .emailAddress,
                autocapitalization: .never
            )

            AuthField(
                label: "Wachtwoord",
                placeholder: "••••••••",
                text: $loginPassword,
                isSecure: true
            )

            Button {
                Task { await performLogin() }
            } label: {
                submitLabel("Inloggen")
            }
            .buttonStyle(.plain)
            .disabled(isLoading || loginEmail.isEmpty || loginPassword.isEmpty)
            .opacity(loginEmail.isEmpty || loginPassword.isEmpty ? 0.5 : 1)

            Button {
                Task { await performReset() }
            } label: {
                Text("Wachtwoord vergeten?")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.primary)
            }
            .buttonStyle(.plain)
            .disabled(isLoading || loginEmail.isEmpty)
            .opacity(loginEmail.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.bottom, BCSpacing.xl)
    }

    // MARK: - Register

    private var registerSection: some View {
        VStack(spacing: BCSpacing.md) {
            HStack(spacing: BCSpacing.sm) {
                AuthField(label: "Voornaam", placeholder: "Jan", text: $firstName)
                AuthField(label: "Achternaam", placeholder: "de Vries", text: $lastName)
            }

            rolePicker

            AuthField(
                label: "E-mailadres",
                placeholder: "naam@voorbeeld.nl",
                text: $registerEmail,
                keyboard: .emailAddress,
                autocapitalization: .never
            )

            AuthField(
                label: "Wachtwoord",
                placeholder: "Minimaal 8 tekens",
                text: $registerPassword,
                isSecure: true
            )

            Button {
                Task { await performRegister() }
            } label: {
                submitLabel("Account aanmaken")
            }
            .buttonStyle(.plain)
            .disabled(isLoading || !registerFormValid)
            .opacity(registerFormValid ? 1 : 0.5)

            Text("Door te registreren ga je akkoord met onze gebruiksvoorwaarden en het AVG-privacybeleid.")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.bottom, BCSpacing.xl)
    }

    private var rolePicker: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            Text("Ik gebruik Thuisverzorgd als")
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(BCColors.textSecondary)

            ForEach(UserRole.allCases.filter { $0 != .admin }) { role in
                Button {
                    selectedRole = role
                } label: {
                    HStack(spacing: BCSpacing.md) {
                        Image(systemName: selectedRole == role ? "largecircle.fill.circle" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(selectedRole == role ? BCColors.green600 : BCColors.textTertiary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(role.displayName)
                                .font(BCTypography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(BCColors.textPrimary)
                            Text(role.subtitle)
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, BCSpacing.md)
                    .padding(.vertical, BCSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                            .fill(selectedRole == role ? BCColors.accent.opacity(0.10) : BCColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                    .stroke(
                                        selectedRole == role ? BCColors.green600 : BCColors.border,
                                        lineWidth: selectedRole == role ? 1.5 : 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: selectedRole)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func submitLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.primary)
            )
            .bcSoftShadow(.subtle)
    }

    private var registerFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty &&
        !registerEmail.isEmpty && registerPassword.count >= 8
    }

    // MARK: - Demo shortcut

    private var demoShortcut: some View {
        VStack(spacing: BCSpacing.sm) {
            HStack {
                Rectangle().frame(height: 1).foregroundStyle(BCColors.border)
                Text("of")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)
                    .fixedSize()
                Rectangle().frame(height: 1).foregroundStyle(BCColors.border)
            }
            .padding(.horizontal, BCSpacing.lg)

            Menu {
                Button {
                    goDemo(role: .buddy)
                } label: {
                    Label("Demo — Buddy kaart", systemImage: "map.fill")
                }
                Button {
                    goDemo(role: .elderly)
                } label: {
                    Label("Demo — Oudere", systemImage: "figure.wave")
                }
                Button {
                    goDemo(role: .family)
                } label: {
                    Label("Demo — Familie", systemImage: "house.and.flag.fill")
                }
            } label: {
                HStack(spacing: BCSpacing.sm) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Demo overslaan")
                        .font(BCTypography.captionEmphasized)
                }
                .foregroundStyle(BCColors.textSecondary)
                .padding(.horizontal, BCSpacing.md)
                .padding(.vertical, BCSpacing.sm)
                .background(Capsule().fill(BCColors.surfaceMuted))
            }
            .padding(.bottom, BCSpacing.lg)
        }
    }

    private func goDemo(role: UserRole) {
        appState.isDemoMode = true
        appState.isOnboardingComplete = true
        appState.currentRole = role
        appState.showLogin = false
        appState.hasSeenSplash = true
    }

    // MARK: - Actions

    private func performReset() async {
        guard !loginEmail.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        do {
            try await appState.authService.resetPassword(email: loginEmail)
            infoMessage = "We hebben een herstel-link gestuurd naar \(loginEmail). Controleer je inbox."
        } catch {
            errorMessage = friendlyError(error)
        }
        isLoading = false
    }

    private func performLogin() async {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        do {
            try await appState.authService.signIn(email: loginEmail, password: loginPassword)
            if let userId = appState.authService.currentUserId {
                await appState.handleAuthSuccess(userId: userId)
                if appState.currentRole == nil {
                    errorMessage = "Account gevonden maar profiel ontbreekt. Probeer opnieuw te registreren."
                }
            }
        } catch {
            errorMessage = friendlyError(error)
        }
        isLoading = false
    }

    private func performRegister() async {
        isLoading = true
        errorMessage = nil
        do {
            let needsConfirmation = try await appState.authService.signUp(
                email: registerEmail,
                password: registerPassword,
                role: selectedRole.rawValue,
                firstName: firstName,
                lastName: lastName
            )
            if needsConfirmation {
                errorMessage = "Bevestig je e-mailadres via de link in je inbox en log daarna in."
            } else if let userId = appState.authService.currentUserId {
                await appState.handleAuthSuccess(userId: userId, role: selectedRole)
            }
        } catch {
            errorMessage = friendlyError(error)
        }
        isLoading = false
    }

    private func friendlyError(_ error: Error) -> String {
        let raw = (error.localizedDescription + " " + String(describing: error)).lowercased()
        if raw.contains("email not confirmed") || raw.contains("not confirmed") {
            return "E-mailadres nog niet bevestigd. Controleer je inbox en klik op de bevestigingslink."
        } else if raw.contains("invalid login credentials") || raw.contains("invalid_credentials") || raw.contains("invalid email or password") {
            return "E-mailadres of wachtwoord klopt niet."
        } else if raw.contains("already registered") || raw.contains("already exists") || raw.contains("already in use") || raw.contains("duplicate") {
            return "Er bestaat al een account met dit e-mailadres. Log in."
        } else if raw.contains("weak") && raw.contains("password") {
            return "Wachtwoord is te zwak. Kies minimaal 8 tekens."
        } else if raw.contains("network") || raw.contains("offline") || raw.contains("could not connect") || raw.contains("timed out") {
            return "Geen internetverbinding. Controleer je wifi of mobiele data."
        } else if raw.contains("signup") && raw.contains("disabled") {
            return "Registratie is tijdelijk uitgeschakeld."
        } else if raw.contains("rate limit") || raw.contains("too many") {
            return "Te veel pogingen. Wacht even en probeer het opnieuw."
        }
        #if DEBUG
        return "Fout: \(error.localizedDescription)"
        #else
        return "Er is iets misgegaan. Probeer het opnieuw."
        #endif
    }
}

// MARK: - Shared form field

private struct AuthField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(BCColors.textSecondary)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(BCTypography.body)
            .foregroundStyle(BCColors.textPrimary)
            .keyboardType(keyboard)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled()
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(BCColors.surface)
            )
            .bcSoftShadow(.subtle)
        }
    }
}

#Preview {
    LoginView()
        .environment(AppState())
}
