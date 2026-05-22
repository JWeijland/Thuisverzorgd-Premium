import SwiftUI

// MARK: - Buttons

struct BCPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var fullWidth: Bool = true
    var isLoading: Bool = false
    var accessibilityLabel: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: BCSpacing.sm) {
                if isLoading {
                    ProgressView().tint(.white)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(BCTypography.bodyEmphasized)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 72)
            .padding(.horizontal, BCSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(BCColors.primary)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}

struct BCSecondaryButton: View {
    let title: String
    var icon: String? = nil
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: BCSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(BCTypography.bodyEmphasized)
            }
            .foregroundStyle(BCColors.primary)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 72)
            .padding(.horizontal, BCSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(BCColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .stroke(BCColors.primary, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct BCDangerButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            action()
        } label: {
            HStack(spacing: BCSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title).font(BCTypography.bodyEmphasized)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(BCColors.danger)
            )
        }
        .buttonStyle(.plain)
    }
}

// Large tappable card for elderly home screen — 120pt+ height, accent strip on left
struct BCBigTile: View {
    @Environment(\.largeTextEnabled) private var largeText
    let title: String
    let subtitle: String?
    let icon: String
    var color: Color = BCColors.primary
    let action: () -> Void

    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(color)
                    .frame(width: 6)
                    .frame(maxHeight: .infinity)
                    .cornerRadius(BCRadius.sm, corners: [.topLeft, .bottomLeft])

                HStack(spacing: BCSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                            .fill(color.opacity(0.10))
                            .frame(width: et.iconBoxSize, height: et.iconBoxSize)
                        Image(systemName: icon)
                            .font(.system(size: et.iconSize, weight: .semibold))
                            .foregroundStyle(color)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(et.button)
                            .foregroundStyle(BCColors.textPrimary)
                            .multilineTextAlignment(.leading)
                        if let subtitle {
                            Text(subtitle)
                                .font(et.caption)
                                .foregroundStyle(BCColors.textSecondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: largeText ? 20 : 16, weight: .semibold))
                        .foregroundStyle(BCColors.textTertiary)
                }
                .padding(largeText ? BCSpacing.lg : BCSpacing.md)
            }
            .frame(maxWidth: .infinity, minHeight: et.tileHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .stroke(BCColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Cards

struct BCCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(BCSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .stroke(BCColors.border, lineWidth: 1)
            )
    }
}

// MARK: - Badges

struct BCLevelBadge: View {
    let level: ServiceLevel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 11, weight: .semibold))
            Text("Niveau \(level.rawValue)")
                .font(BCTypography.captionEmphasized)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous).fill(level.color)
        )
    }
}

struct BCStatusPill: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(BCTypography.captionEmphasized)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous).fill(color.opacity(0.12))
            )
    }
}

struct BCRatingStars: View {
    let value: Double
    var size: CGFloat = 13

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: starName(for: i))
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(BCColors.warning)
            }
            Text(String(format: "%.1f", value))
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(BCColors.textSecondary)
                .padding(.leading, 2)
        }
    }

    private func starName(for index: Int) -> String {
        let pos = Double(index) + 0.5
        if value >= Double(index + 1) { return "star.fill" }
        if value >= pos { return "star.leadinghalf.filled" }
        return "star"
    }
}

// MARK: - BCProgressBar

struct BCProgressBar: View {
    let value: Double     // 0.0–1.0
    var label: String? = nil
    var color: Color = BCColors.primary

    var body: some View {
        VStack(alignment: .leading, spacing: BCSpacing.xs) {
            if let label {
                Text(label)
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: BCRadius.sm)
                        .fill(color.opacity(0.15))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: BCRadius.sm)
                        .fill(color)
                        .frame(width: geo.size.width * max(0, min(1, value)), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - BCVOGBadge

struct BCVOGBadge: View {
    var expiresAt: Date? = nil
    @State private var showVOGInfo = false

    var body: some View {
        HStack(spacing: BCSpacing.xs) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BCColors.success)
            Text("VOG geverifieerd")
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(BCColors.success)
            Button {
                showVOGInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(BCColors.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Wat is een VOG? Meer informatie")
        }
        .sheet(isPresented: $showVOGInfo) {
            VOGInfoSheet()
        }
    }
}

private struct VOGInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.md) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(BCColors.success)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, BCSpacing.md)

                    Text("Wat is een VOG?")
                        .font(BCTypography.title2)
                        .foregroundStyle(BCColors.textPrimary)

                    Text("Een Verklaring Omtrent het Gedrag (VOG) is een document waaruit blijkt dat iemands gedrag uit het verleden geen bezwaar vormt voor het uitvoeren van een specifieke taak of functie.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)

                    Text("Elke buddy bij Thuisverzorgt heeft een geldige VOG. Deze wordt elke \(Config.vogRenewalYears) jaar vernieuwd en gecontroleerd door Thuisverzorgt.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                }
                .padding(BCSpacing.lg)
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("VOG Informatie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
    }
}

// MARK: - BCIllustrationCard

struct BCIllustrationCard: View {
    let symbol: String
    let color: Color
    let caption: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .fill(color.opacity(0.10))
            VStack(spacing: BCSpacing.sm) {
                Image(systemName: symbol)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(color)
                Text(caption)
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(color.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BCSpacing.md)
            }
            .padding(.vertical, BCSpacing.xl)
        }
    }
}

// MARK: - BCToast

struct BCToast: View {
    let message: String
    let icon: String

    var body: some View {
        HStack(spacing: BCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            Text(message)
                .font(BCTypography.bodyEmphasized)
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.vertical, BCSpacing.md)
        .background(
            Capsule(style: .continuous).fill(BCColors.textPrimary)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

// MARK: - BCOnboardingPhoneFooter

struct BCOnboardingPhoneFooter: View {
    var body: some View {
        HStack(spacing: BCSpacing.xs) {
            Image(systemName: "phone.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BCColors.primary)
            Text("Hulp nodig? Bel ons: \(Config.supportPhoneNumber)")
                .font(BCTypography.subheadline)
                .foregroundStyle(BCColors.textSecondary)
        }
        .padding(.vertical, BCSpacing.sm)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Header

struct BCSectionHeader: View {
    let title: String
    var trailing: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(BCTypography.headline)
                .foregroundStyle(BCColors.textPrimary)
            Spacer()
            if let trailing, let trailingAction {
                Button(action: trailingAction) {
                    Text(trailing)
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Empty State

struct BCEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: BCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(BCColors.textTertiary)
            Text(title)
                .font(BCTypography.headline)
                .foregroundStyle(BCColors.textPrimary)
            Text(message)
                .font(BCTypography.subheadline)
                .foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(BCSpacing.lg)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - BCNavBar

struct BCNavBar: View {
    let title: String
    var subtitle: String? = nil
    var backAction: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            BCColors.primary.ignoresSafeArea(edges: .top)
            HStack(alignment: .bottom, spacing: BCSpacing.sm) {
                if let backAction {
                    Button(action: backAction) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Terug")
                }
                VStack(alignment: .leading, spacing: 0) {
                    if let subtitle {
                        Text(subtitle)
                            .font(BCTypography.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Text(title)
                        .font(BCTypography.titleEmphasized)
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(BCColors.accent)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.sm)
        }
        .frame(height: 56)
    }
}

// MARK: - Corner radius helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
