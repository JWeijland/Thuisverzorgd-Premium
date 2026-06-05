import SwiftUI

struct PaymentOverviewView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.largeTextEnabled) private var largeText
    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    private var myRecords: [ServiceRecord] {
        appState.serviceRecords.filter { $0.elderlyName == appState.elderlyUser.fullName }
    }

    private var openRecords: [ServiceRecord] { myRecords.filter { !$0.isFinalized } }
    private var finalizedRecords: [ServiceRecord] { myRecords.filter { $0.isFinalized } }

    private var openTotalCents: Int { openRecords.reduce(0) { $0 + $1.clientChargeCents } }
    private var paidTotalCents: Int { finalizedRecords.reduce(0) { $0 + $1.clientChargeCents } }

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Betalingen", subtitle: "Overzicht van de kosten")

            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    paymentNotice

                    summaryCard

                    if !openRecords.isEmpty {
                        sectionHeader("Openstaand deze maand", icon: "clock.fill", color: BCColors.warning)
                        ForEach(openRecords) { record in
                            RecordRow(record: record, largeText: largeText)
                                .padding(.horizontal, BCSpacing.lg)
                        }
                    }

                    if !finalizedRecords.isEmpty {
                        sectionHeader("Eerder betaald", icon: "checkmark.seal.fill", color: BCColors.success)
                        ForEach(finalizedRecords) { record in
                            RecordRow(record: record, largeText: largeText)
                                .padding(.horizontal, BCSpacing.lg)
                        }
                    }

                    if myRecords.isEmpty {
                        BCCard {
                            VStack(spacing: BCSpacing.sm) {
                                Image(systemName: "eurosign.circle")
                                    .font(.system(size: 36, weight: .regular))
                                    .foregroundStyle(BCColors.textTertiary)
                                Text("Nog geen bezoeken geregistreerd.")
                                    .font(et.body)
                                    .foregroundStyle(BCColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, BCSpacing.md)
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    }
                }
                .padding(.top, BCSpacing.md)
                .padding(.bottom, BCSpacing.xl)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
    }

    // MARK: - Betaling (display-only)

    private var paymentNotice: some View {
        BCCard {
            HStack(spacing: BCSpacing.md) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(BCColors.primary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(BCColors.primary.opacity(0.10)))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Betalen")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                    Text("Betaling volgt later in de app")
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                }
                Spacer()
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }

    // MARK: - Samenvatting kaart

    private var summaryCard: some View {
        BCCard {
            VStack(spacing: BCSpacing.md) {
                HStack {
                    Text("Overzicht")
                        .font(et.heading)
                        .foregroundStyle(BCColors.textPrimary)
                    Spacer()
                }

                HStack(spacing: BCSpacing.lg) {
                    SummaryTile(
                        label: "Openstaand",
                        amount: openTotalCents,
                        color: openTotalCents > 0 ? BCColors.warning : BCColors.textTertiary
                    )
                    Divider().frame(height: 50)
                    SummaryTile(
                        label: "Betaald",
                        amount: paidTotalCents,
                        color: BCColors.success
                    )
                    Divider().frame(height: 50)
                    SummaryTile(
                        label: "Totaal",
                        amount: openTotalCents + paidTotalCents,
                        color: BCColors.primary
                    )
                }

                HStack(spacing: BCSpacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(BCColors.primary)
                    Text("Dit is een overzicht van de kosten. Betalen via de app komt in een latere versie.")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                    Spacer()
                }
                .padding(BCSpacing.sm)
                .background(RoundedRectangle(cornerRadius: BCRadius.sm).fill(BCColors.primary.opacity(0.06)))
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: BCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(et.caption)
                .foregroundStyle(BCColors.textSecondary)
            Spacer()
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.top, BCSpacing.sm)
    }
}

private struct SummaryTile: View {
    let label: String
    let amount: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(formatted(amount))
                .font(BCTypography.headline)
                .foregroundStyle(color)
            Text(label)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatted(_ cents: Int) -> String {
        String(format: "€ %.2f", Double(cents) / 100).replacingOccurrences(of: ".", with: ",")
    }
}

private struct RecordRow: View {
    let record: ServiceRecord
    let largeText: Bool

    var body: some View {
        BCCard {
            HStack(spacing: BCSpacing.md) {
                Image(systemName: record.taskCategory.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(BCColors.primary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(BCColors.primary.opacity(0.08)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.taskCategory.displayName)
                        .font(largeText ? BCTypography.body : BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("\(record.buddyName) · \(String(format: "%.2f", record.hours).replacingOccurrences(of: ".", with: ",")) uur")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                    Text(dateFormatted(record.completedAt))
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatted(record.clientChargeCents))
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                    if record.isFinalized {
                        Label("Betaald", systemImage: "checkmark.circle.fill")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.success)
                            .labelStyle(.titleAndIcon)
                    } else {
                        Text("Openstaand")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.warning)
                    }
                }
            }
        }
    }

    private func formatted(_ cents: Int) -> String {
        String(format: "€ %.2f", Double(cents) / 100).replacingOccurrences(of: ".", with: ",")
    }

    private func dateFormatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "d MMM yyyy"
        return f.string(from: date)
    }
}

#Preview {
    PaymentOverviewView().environment(AppState())
}
