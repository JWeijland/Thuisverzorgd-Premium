import SwiftUI

/// Toont alle service-voorkeuren per niveau. Buddy kruist aan welke
/// taken hij/zij wil doen. Niveaus die nog niet zijn ontgrendeld zijn
/// zichtbaar maar locked met een "Voltooi cursus om te ontgrendelen" badge.
///
/// Wordt gebruikt vanuit:
/// - BuddyProfileView (via "Mijn voorkeuren" card)
/// - LevelUnlockedPreferencesSheet (alleen één niveau, na cursus-unlock)
struct BuddyPreferencesView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    /// Als ingesteld, alleen dit niveau tonen (gebruikt door LevelUnlockedSheet).
    /// Als nil, alle niveaus tonen.
    let focusedLevel: ServiceLevel?

    @State private var localPreferences: [ServiceLevel: Set<String>] = [:]

    init(focusedLevel: ServiceLevel? = nil) {
        self.focusedLevel = focusedLevel
    }

    private var unlockedLevel: ServiceLevel {
        appState.effectiveBuddyLevel
    }

    private var levelsToShow: [ServiceLevel] {
        if let f = focusedLevel { return [f] }
        return [.zero, .one, .two, .three]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.lg) {
                    header

                    ForEach(levelsToShow, id: \.self) { level in
                        levelSection(level: level)
                    }
                }
                .padding(.horizontal, BCSpacing.lg)
                .padding(.top, BCSpacing.md)
                .padding(.bottom, BCSpacing.xl)
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle(focusedLevel == nil ? "Mijn voorkeuren" : "Niveau \(focusedLevel!.rawValue) voorkeuren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Opslaan") { saveAndDismiss() }
                        .tint(BCColors.primary)
                        .fontWeight(.semibold)
                }
                if focusedLevel == nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Sluit") { dismiss() }
                            .tint(BCColors.primary)
                    }
                }
            }
            .onAppear {
                localPreferences = appState.buddyUser.servicePreferences
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: BCSpacing.xs) {
            Text(focusedLevel == nil
                 ? "Wat voor zorg wil je verlenen?"
                 : "Welke taken wil je doen?")
                .font(BCTypography.title2)
                .foregroundStyle(BCColors.textPrimary)
            Text(focusedLevel == nil
                 ? "Kies de taken waar je je comfortabel bij voelt. Je krijgt alleen aanvragen voor wat je hier aankruist."
                 : "Je hebt dit niveau net ontgrendeld. Kies de nieuwe taken die je wilt aanbieden.")
                .font(BCTypography.subheadline)
                .foregroundStyle(BCColors.textSecondary)
        }
    }

    private func levelSection(level: ServiceLevel) -> some View {
        let items = BuddyServiceCatalog.items(for: level)
        let isLocked = level.rawValue > unlockedLevel.rawValue
        let selected = localPreferences[level] ?? []

        return VStack(alignment: .leading, spacing: BCSpacing.sm) {
            HStack(spacing: BCSpacing.sm) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(level.color)
                    .frame(width: 4, height: 18)
                Text("Niveau \(level.rawValue) — \(level.title)")
                    .font(BCTypography.headline)
                    .foregroundStyle(BCColors.textPrimary)
                Spacer()
                if !isLocked {
                    Text("\(selected.count) gekozen")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                }
            }

            if isLocked {
                HStack(spacing: BCSpacing.xs) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(level.color)
                    Text("Voltooi de cursus Niveau \(level.rawValue) om dit te ontgrendelen")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                }
                .padding(.horizontal, BCSpacing.sm)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous)
                        .fill(level.color.opacity(0.08))
                )
            }

            VStack(spacing: BCSpacing.xs) {
                ForEach(items, id: \.name) { item in
                    serviceRow(item: item, level: level, isLocked: isLocked, isSelected: selected.contains(item.name))
                }
            }
        }
    }

    private func serviceRow(item: BuddyServiceCatalog.Item, level: ServiceLevel, isLocked: Bool, isSelected: Bool) -> some View {
        Button {
            guard !isLocked else { return }
            var current = localPreferences[level] ?? []
            if isSelected { current.remove(item.name) }
            else { current.insert(item.name) }
            localPreferences[level] = current
        } label: {
            HStack(spacing: BCSpacing.md) {
                Image(systemName: item.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isLocked ? BCColors.textTertiary : (isSelected ? .white : level.color))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(
                        isLocked ? BCColors.surfaceMuted :
                        (isSelected ? level.color : level.color.opacity(0.10))
                    ))

                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .font(BCTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isLocked ? BCColors.textTertiary : BCColors.textPrimary)
                    Text(item.subtitle)
                        .font(BCTypography.caption)
                        .foregroundStyle(isLocked ? BCColors.textTertiary.opacity(0.6) : BCColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(level.color.opacity(0.5))
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(level.color)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(BCColors.border)
                }
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, BCSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(isLocked ? BCColors.surfaceMuted.opacity(0.5) : BCColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .stroke(
                        isLocked ? BCColors.border.opacity(0.5) :
                        (isSelected ? level.color : BCColors.border),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .opacity(isLocked ? 0.65 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }

    private func saveAndDismiss() {
        for (level, services) in localPreferences {
            appState.setBuddyPreferences(level: level, services: services)
        }
        appState.showToast(text: "Voorkeuren opgeslagen", icon: "checkmark.circle.fill")
        dismiss()
    }
}

#Preview {
    BuddyPreferencesView().environment(AppState())
}
