import SwiftUI

struct CertificateView: View {
    let level: ServiceLevel
    let buddyName: String
    @Environment(\.dismiss) private var dismiss

    private let issuedAt = Date()
    private let certificateHash = UUID().uuidString.prefix(16).lowercased()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BCSpacing.xl) {
                    certificateCard
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.top, BCSpacing.lg)

                    VStack(spacing: BCSpacing.sm) {
                        BCPrimaryButton(title: "Deel certificaat", icon: "square.and.arrow.up") {
                            // TODO[real-integration]: Native share sheet with PDF export
                        }

                        BCSecondaryButton(title: "Terug naar cursussen", icon: "chevron.left") {
                            dismiss()
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.bottom, BCSpacing.xl)
                }
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Certificaat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
    }

    private var certificateCard: some View {
        VStack(spacing: BCSpacing.lg) {
            // Header stripe
            VStack(spacing: BCSpacing.sm) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(BCColors.accent)
                Text("Thuisverzorgt")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Opleidingsinstituut")
                    .font(BCTypography.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(BCSpacing.lg)
            .background(BCColors.primary)

            VStack(spacing: BCSpacing.md) {
                Text("CERTIFICAAT")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(BCColors.textTertiary)
                    .kerning(3)

                Text("Hierbij verklaren wij dat")
                    .font(BCTypography.subheadline)
                    .foregroundStyle(BCColors.textSecondary)

                Text(buddyName)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(BCColors.textPrimary)

                Text("succesvol het niveau \(level.rawValue) certificaat heeft behaald")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)

                BCLevelBadge(level: level)
                    .padding(.vertical, BCSpacing.xs)

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Uitgegeven")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.textTertiary)
                        Text(dateString(from: issuedAt))
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Geldig tot")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.textTertiary)
                        Text(dateString(from: issuedAt.addingTimeInterval(86400 * 365 * Double(Config.certificateValidityYears))))
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                }

                HStack {
                    Image(systemName: "qrcode")
                        .font(.system(size: 36))
                        .foregroundStyle(BCColors.border)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Certificaatnummer")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.textTertiary)
                        Text(String(certificateHash))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(BCColors.textTertiary)
                    }
                }
            }
            .padding(BCSpacing.lg)

            // Footer
            HStack(spacing: BCSpacing.xs) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(BCColors.success)
                Text("Erkend door Thuisverzorgt | Geldig voor \(Config.certificateValidityYears) jaar")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)
            }
            .padding(.bottom, BCSpacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .fill(BCColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .stroke(BCColors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private func dateString(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: date)
    }
}

#Preview {
    CertificateView(level: .one, buddyName: "Aiyla Demir")
}
