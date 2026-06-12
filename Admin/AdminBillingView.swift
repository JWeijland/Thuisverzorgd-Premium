import SwiftUI
import UIKit

struct AdminBillingView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedMonth: String? = nil

    private var availableMonths: [String] {
        let months = Set(appState.serviceRecords.map(\.month))
        return months.sorted().reversed()
    }

    private var filteredRecords: [ServiceRecord] {
        appState.serviceRecords.filter { record in
            selectedMonth.map { record.month == $0 } ?? true
        }
    }

    // Totalen over gefilterde records
    private var totalClient: Int  { filteredRecords.reduce(0) { $0 + $1.clientChargeCents } }
    private var totalBuddy: Int   { filteredRecords.reduce(0) { $0 + $1.buddyEarningsCents } }
    private var totalProfit: Int  { filteredRecords.reduce(0) { $0 + $1.profitCents } }

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Overzicht", subtitle: "Bezoeken & bedragen (display-only)")

            filterBar

            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    displayOnlyNotice
                    totalsCard
                    recordsTable
                }
                .padding(.top, BCSpacing.md)
                .padding(.bottom, BCSpacing.xl)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
    }

    // MARK: - Display-only melding

    private var displayOnlyNotice: some View {
        BCCard {
            HStack(spacing: BCSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(BCColors.primary)
                Text("Betalen via de app komt in een latere versie. Dit overzicht toont alleen de bedragen.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                Spacer()
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }

    // MARK: - Filter balk

    private var filterBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BCSpacing.sm) {
                    Menu {
                        Button("Alle maanden") { selectedMonth = nil }
                        Divider()
                        ForEach(availableMonths, id: \.self) { month in
                            Button(month) { selectedMonth = month }
                        }
                    } label: {
                        FilterPill(
                            label: selectedMonth.map { monthLabel($0) } ?? "Alle maanden",
                            icon: "calendar",
                            isActive: selectedMonth != nil
                        )
                    }
                }
                .padding(.horizontal, BCSpacing.lg)
                .padding(.vertical, BCSpacing.sm)
            }
            Divider()
        }
        .background(BCColors.surface)
    }

    // MARK: - Totalen kaart

    private var totalsCard: some View {
        BCCard {
            VStack(spacing: BCSpacing.md) {
                HStack {
                    Text(selectedMonth.map { "Totalen \(monthLabel($0))" } ?? "Totalen")
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                    Spacer()
                    Text("\(filteredRecords.count) records")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                }

                HStack(spacing: 0) {
                    TotalTile(label: "Klant betaalt", amount: totalClient, color: BCColors.primary)
                    Divider().frame(height: 50)
                    TotalTile(label: "Buddy verdienste", amount: totalBuddy, color: BCColors.textSecondary)
                    Divider().frame(height: 50)
                    TotalTile(label: "Platformfee", amount: totalProfit, color: BCColors.success)
                }
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }

    // MARK: - Records tabel

    private var recordsTable: some View {
        VStack(spacing: BCSpacing.sm) {
            HStack(spacing: 0) {
                Text("Buddy / Ouder").frame(maxWidth: .infinity, alignment: .leading)
                Text("Uren").frame(width: 48, alignment: .trailing)
                Text("Bedrag").frame(width: 72, alignment: .trailing)
            }
            .font(BCTypography.caption)
            .foregroundStyle(BCColors.textTertiary)
            .padding(.horizontal, BCSpacing.lg)

            if filteredRecords.isEmpty {
                BCCard {
                    Text("Geen records gevonden voor de geselecteerde maand.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BCSpacing.md)
                }
                .padding(.horizontal, BCSpacing.lg)
            } else {
                ForEach(filteredRecords) { record in
                    BillingRecordRow(record: record)
                        .padding(.horizontal, BCSpacing.lg)
                }
            }
        }
    }

    // MARK: - Helpers

    private func monthLabel(_ month: String) -> String {
        let parts = month.split(separator: "-")
        guard parts.count == 2, let m = Int(parts[1]) else { return month }
        let names = ["", "jan", "feb", "mrt", "apr", "mei", "jun",
                     "jul", "aug", "sep", "okt", "nov", "dec"]
        return m < names.count ? "\(names[m]) \(parts[0])" : month
    }
}

// MARK: - BillingRecordRow

private struct BillingRecordRow: View {
    let record: ServiceRecord

    var body: some View {
        BCCard {
            VStack(spacing: BCSpacing.sm) {
                HStack(spacing: BCSpacing.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.buddyName)
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.textPrimary)
                        Text("→ \(record.elderlyName)")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                        Text(record.taskCategory.displayName)
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textTertiary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.2fh", record.hours).replacingOccurrences(of: ".", with: ","))
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                        Text(euros(record.clientChargeCents))
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.textPrimary)
                    }
                }

                HStack(spacing: BCSpacing.sm) {
                    Label("Buddy: \(euros(record.buddyEarningsCents))", systemImage: "person.fill")
                    Spacer()
                    Label("Platformfee: \(euros(record.profitCents))", systemImage: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(BCColors.success)
                }
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
            }
        }
    }

    private func euros(_ cents: Int) -> String {
        String(format: "€ %.2f", Double(cents) / 100).replacingOccurrences(of: ".", with: ",")
    }
}

// MARK: - Hulpviews

private struct TotalTile: View {
    let label: String
    let amount: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "€ %.2f", Double(amount) / 100).replacingOccurrences(of: ".", with: ","))
                .font(BCTypography.title3)
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FilterPill: View {
    let label: String
    let icon: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: BCSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(label)
                .font(BCTypography.captionEmphasized)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(isActive ? .white : BCColors.textPrimary)
        .padding(.horizontal, BCSpacing.md)
        .padding(.vertical, BCSpacing.sm)
        .background(Capsule().fill(isActive ? BCColors.primary : BCColors.surface))
        .overlay(Capsule().stroke(isActive ? Color.clear : BCColors.border, lineWidth: 1))
    }
}

#Preview {
    AdminBillingView().environment(AppState())
}
