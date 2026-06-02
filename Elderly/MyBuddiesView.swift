import SwiftUI

struct MyBuddiesView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.largeTextEnabled) private var largeText
    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    private var favoriteBuddies: [BuddyUser] {
        MockData.allBuddies.filter { appState.favoriteBuddyNames.contains($0.firstName) }
    }

    private var pastBuddies: [BuddyUser] {
        let pastNames = Set(appState.taskHistory.compactMap(\.assignedBuddyName))
        return MockData.allBuddies.filter {
            pastNames.contains($0.firstName) && !appState.favoriteBuddyNames.contains($0.firstName)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Mijn buddies", subtitle: "Vaste mensen die u kennen")

            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.md) {

                    // Favorites
                    Text("Vaste buddies")
                        .font(et.heading)
                        .foregroundStyle(BCColors.textPrimary)
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.top, BCSpacing.md)

                    Text("Vaste buddies krijgen 5 minuten voorrang als u hulp aanvraagt.")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .padding(.horizontal, BCSpacing.lg)

                    if favoriteBuddies.isEmpty {
                        BCCard {
                            Text("U heeft nog geen vaste buddies. Tik op een eerder bezoek om iemand toe te voegen.")
                                .font(et.body)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(favoriteBuddies.enumerated()), id: \.element.id) { index, buddy in
                                BuddyRow(buddy: buddy, isFavorite: true) {
                                    appState.toggleFavorite(buddyName: buddy.firstName)
                                }
                                if index < favoriteBuddies.count - 1 {
                                    Divider()
                                        .padding(.leading, BCSpacing.lg)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                                .fill(BCColors.surface)
                        )
                        .bcSoftShadow(.card)
                        .padding(.horizontal, BCSpacing.lg)
                    }

                    // Past (not favorited)
                    if !pastBuddies.isEmpty {
                        Text("Eerder geholpen")
                            .font(et.heading)
                            .foregroundStyle(BCColors.textPrimary)
                            .padding(.horizontal, BCSpacing.lg)
                            .padding(.top, BCSpacing.lg)

                        VStack(spacing: 0) {
                            ForEach(Array(pastBuddies.enumerated()), id: \.element.id) { index, buddy in
                                BuddyRow(buddy: buddy, isFavorite: false) {
                                    appState.toggleFavorite(buddyName: buddy.firstName)
                                }
                                if index < pastBuddies.count - 1 {
                                    Divider()
                                        .padding(.leading, BCSpacing.lg)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                                .fill(BCColors.surface)
                        )
                        .bcSoftShadow(.card)
                        .padding(.horizontal, BCSpacing.lg)
                    }
                }
                .padding(.bottom, BCSpacing.xl)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
    }
}

private struct BuddyRow: View {
    @Environment(AppState.self) private var appState
    @Environment(\.largeTextEnabled) private var largeText
    let buddy: BuddyUser
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    var body: some View {
        HStack(spacing: BCSpacing.md) {
            let avatarSize: CGFloat = largeText ? 72 : 56
            ZStack {
                Circle().fill(BCColors.primary.opacity(0.10)).frame(width: avatarSize, height: avatarSize)
                Image(systemName: buddy.avatarSystemName)
                    .font(.system(size: largeText ? 38 : 30, weight: .regular))
                    .foregroundStyle(BCColors.primary)
            }
            VStack(alignment: .leading, spacing: largeText ? 6 : 4) {
                HStack(spacing: BCSpacing.xs) {
                    Text(buddy.firstName)
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: largeText ? 16 : 12, weight: .semibold))
                            .foregroundStyle(BCColors.danger)
                    }
                }
                BCRatingStars(value: buddy.ratingAverage)
                HStack(spacing: BCSpacing.xs) {
                    BCLevelBadge(level: buddy.level)
                    Text("\(buddy.totalTasks) bezoeken")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textTertiary)
                }
            }
            Spacer()
            let heartSize: CGFloat = largeText ? 56 : 44
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onToggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: largeText ? 24 : 18, weight: .semibold))
                    .foregroundStyle(isFavorite ? BCColors.danger : BCColors.textTertiary)
                    .frame(width: heartSize, height: heartSize)
                    .background(Circle().fill(isFavorite ? BCColors.danger.opacity(0.10) : BCColors.surfaceMuted))
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isFavorite)
        }
        .padding(.horizontal, BCSpacing.md)
        .padding(.vertical, BCSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MyBuddiesView().environment(AppState())
}
