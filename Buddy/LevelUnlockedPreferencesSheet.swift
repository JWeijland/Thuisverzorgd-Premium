import SwiftUI

/// Vier-sheet die automatisch verschijnt na het voltooien van een cursus.
/// Toont de feliciteer-boodschap en stuurt de buddy direct door naar
/// BuddyPreferencesView gefocust op het net ontgrendelde niveau.
struct LevelUnlockedPreferencesSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let level: ServiceLevel

    @State private var showPreferences: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: BCSpacing.lg) {
                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(level.color.opacity(0.15))
                        .frame(width: 160, height: 160)
                    Image(systemName: "rosette")
                        .font(.system(size: 80, weight: .semibold))
                        .foregroundStyle(level.color)
                }

                VStack(spacing: BCSpacing.sm) {
                    Text("Niveau \(level.rawValue) ontgrendeld!")
                        .font(BCTypography.title)
                        .foregroundStyle(BCColors.textPrimary)
                    Text(level.title)
                        .font(BCTypography.title3)
                        .foregroundStyle(level.color)
                    Text(level.celebrationMessage)
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BCSpacing.lg)
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: BCSpacing.sm) {
                    HStack(spacing: BCSpacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(level.color)
                        Text("Wat nu?")
                            .font(BCTypography.headline)
                            .foregroundStyle(BCColors.textPrimary)
                    }
                    Text("Kies welke nieuwe taken van Niveau \(level.rawValue) je wilt aanbieden. Je krijgt alleen aanvragen waar je voor kiest.")
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                }
                .padding(BCSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                        .fill(level.color.opacity(0.08))
                )
                .padding(.horizontal, BCSpacing.lg)

                VStack(spacing: BCSpacing.sm) {
                    BCPrimaryButton(
                        title: "Kies mijn voorkeuren",
                        icon: "checklist",
                        fullWidth: true
                    ) {
                        showPreferences = true
                    }
                    BCSecondaryButton(
                        title: "Later in mijn profiel",
                        icon: "clock",
                        fullWidth: true
                    ) {
                        close()
                    }
                }
                .padding(.horizontal, BCSpacing.lg)
                .padding(.bottom, BCSpacing.md)
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $showPreferences, onDismiss: { close() }) {
            BuddyPreferencesView(focusedLevel: level)
                .environment(appState)
        }
    }

    private func close() {
        appState.dismissLevelUnlock()
        dismiss()
    }
}

#Preview {
    LevelUnlockedPreferencesSheet(level: .one).environment(AppState())
}
