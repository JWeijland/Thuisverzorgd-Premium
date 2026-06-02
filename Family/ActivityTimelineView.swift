import SwiftUI

struct ActivityTimelineView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Activiteit", subtitle: "Wat is er gebeurd")

            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.lg) {
                    Text("Tijdlijn van bezoeken en gebeurtenissen rond \(appState.activeFamilyElderly.firstName).")
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.top, BCSpacing.md)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(MockData.familyActivity(for: appState.activeFamilyElderly.firstName)) { item in
                            TimelineRow(item: item)
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    Spacer().frame(height: BCSpacing.xl)
                }
            }
        }
        .background(BCColors.background.ignoresSafeArea())
    }
}

private struct TimelineRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(alignment: .top, spacing: BCSpacing.md) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(item.color.opacity(0.18)).frame(width: 36, height: 36)
                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(item.color)
                }
                Rectangle()
                    .fill(BCColors.border)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
                Text(item.detail)
                    .font(BCTypography.subheadline)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.leading)
                Text(relativeFormatter.localizedString(for: item.date, relativeTo: Date()))
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)
            }
            .padding(.bottom, BCSpacing.md)
        }
    }
}

private let relativeFormatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.locale = Locale(identifier: "nl_NL")
    f.unitsStyle = .full
    return f
}()

#Preview {
    ActivityTimelineView().environment(AppState())
}
