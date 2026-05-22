import SwiftUI
import UIKit

struct AdminBillingView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedMonth: String? = nil
    @State private var selectedPaymentType: PaymentType? = nil
    @State private var showFinalizeAlert = false
    @State private var exportURL: URL? = nil
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    private var availableMonths: [String] {
        let months = Set(appState.serviceRecords.map(\.month))
        return months.sorted().reversed()
    }

    private var filteredRecords: [ServiceRecord] {
        appState.serviceRecords.filter { record in
            let monthOK = selectedMonth.map { record.month == $0 } ?? true
            let typeOK  = selectedPaymentType.map { record.paymentType == $0 } ?? true
            return monthOK && typeOK
        }
    }

    private var openMonths: [String] {
        availableMonths.filter { month in
            appState.serviceRecords.filter { $0.month == month }.contains { !$0.isFinalized }
        }
    }

    // Totalen over gefilterde records
    private var totalClient: Int  { filteredRecords.reduce(0) { $0 + $1.clientChargeCents } }
    private var totalBuddy: Int   { filteredRecords.reduce(0) { $0 + $1.buddyEarningsCents } }
    private var totalProfit: Int  { filteredRecords.reduce(0) { $0 + $1.profitCents } }

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Facturatie", subtitle: "Overzicht & export")

            filterBar

            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    totalsCard
                    actionsRow
                    recordsTable
                }
                .padding(.top, BCSpacing.md)
                .padding(.bottom, BCSpacing.xl)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .alert("Maand afsluiten", isPresented: $showFinalizeAlert) {
            Button("Annuleer", role: .cancel) { }
            Button("Afsluiten", role: .destructive) {
                if let month = selectedMonth { appState.finalizeMonth(month) }
            }
        } message: {
            Text("Alle records voor \(selectedMonth ?? "deze maand") worden definitief. Dit kan niet ongedaan worden gemaakt.")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(items: shareItems)
        }
    }

    // MARK: - Filter balk

    private var filterBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BCSpacing.sm) {
                    // Maand filter
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

                    // Betalingstype filter
                    Menu {
                        Button("Alle types") { selectedPaymentType = nil }
                        Divider()
                        ForEach(PaymentType.allCases) { type in
                            Button(type.displayName) { selectedPaymentType = type }
                        }
                    } label: {
                        FilterPill(
                            label: selectedPaymentType?.displayName ?? "Alle types",
                            icon: "creditcard",
                            isActive: selectedPaymentType != nil
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
                    TotalTile(label: "Klant/gemeente", amount: totalClient, color: BCColors.primary)
                    Divider().frame(height: 50)
                    TotalTile(label: "Buddy verdienste", amount: totalBuddy, color: BCColors.textSecondary)
                    Divider().frame(height: 50)
                    TotalTile(label: "Winst (20%)", amount: totalProfit, color: BCColors.success)
                }

                // Per betalingstype splitsen
                let particulierTotal = filteredRecords.filter { $0.paymentType == .particulier }
                    .reduce(0) { $0 + $1.clientChargeCents }
                let zinTotal = filteredRecords.filter { $0.paymentType == .zinNatura }
                    .reduce(0) { $0 + $1.clientChargeCents }

                if particulierTotal > 0 || zinTotal > 0 {
                    Divider()
                    HStack {
                        Label("Particulier: \(euros(particulierTotal))", systemImage: "creditcard.fill")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                        Spacer()
                        Label("ZiN: \(euros(zinTotal))", systemImage: "building.columns.fill")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                }
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }

    // MARK: - Acties

    private var actionsRow: some View {
        HStack(spacing: BCSpacing.md) {
            // CSV export
            Button {
                exportCSV()
            } label: {
                Label("Export CSV", systemImage: "tablecells.fill")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: BCRadius.md).fill(BCColors.primary))
            }
            .buttonStyle(.plain)

            // PDF factuur (alleen als maand geselecteerd en niet definitief)
            Button {
                exportPDF()
            } label: {
                Label("Factuur PDF", systemImage: "doc.richtext.fill")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: BCRadius.md).fill(BCColors.accent))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, BCSpacing.lg)
    }

    // MARK: - Maand afsluiten knop

    @ViewBuilder
    private var finalizeButton: some View {
        if let month = selectedMonth, openMonths.contains(month) {
            Button {
                showFinalizeAlert = true
            } label: {
                Label("Maand \(monthLabel(month)) afsluiten", systemImage: "checkmark.seal.fill")
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(RoundedRectangle(cornerRadius: BCRadius.lg).fill(BCColors.success))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, BCSpacing.lg)
        }
    }

    // MARK: - Records tabel

    private var recordsTable: some View {
        VStack(spacing: BCSpacing.sm) {
            // Tabelheader
            HStack(spacing: 0) {
                Text("Buddy / Ouder").frame(maxWidth: .infinity, alignment: .leading)
                Text("Uren").frame(width: 48, alignment: .trailing)
                Text("Bedrag").frame(width: 72, alignment: .trailing)
                Text("Type").frame(width: 60, alignment: .trailing)
            }
            .font(BCTypography.caption)
            .foregroundStyle(BCColors.textTertiary)
            .padding(.horizontal, BCSpacing.lg)

            if filteredRecords.isEmpty {
                BCCard {
                    Text("Geen records gevonden voor de geselecteerde filters.")
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

                finalizeButton
            }
        }
    }

    // MARK: - Export

    private func exportCSV() {
        let csv = appState.csvExport(month: selectedMonth)
        let filename = selectedMonth.map { "thuisverzorgt-\($0).csv" } ?? "thuisverzorgt-alle.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        shareItems = [url]
        showShareSheet = true
    }

    private func exportPDF() {
        guard let url = generatePDF() else { return }
        shareItems = [url]
        showShareSheet = true
    }

    private func generatePDF() -> URL? {
        let month = selectedMonth ?? "alle"
        let records = filteredRecords
        var lines: [String] = [
            "THUISVERZORGT — FACTUUROVERZICHT",
            "Periode: \(selectedMonth.map { monthLabel($0) } ?? "Alle maanden")",
            "Gegenereerd: \(dateNow())",
            "",
            "═══════════════════════════════════════",
            ""
        ]

        // Totalen
        lines.append("TOTALEN")
        lines.append("Omzet (klant/gemeente): \(euros(totalClient))")
        lines.append("Uitbetaling aan buddies: \(euros(totalBuddy))")
        lines.append("Nettowinst Thuisverzorgt: \(euros(totalProfit))")
        lines.append("")
        lines.append("Particulier: \(euros(records.filter { $0.paymentType == .particulier }.reduce(0) { $0 + $1.clientChargeCents }))")
        lines.append("Zorg in Natura: \(euros(records.filter { $0.paymentType == .zinNatura }.reduce(0) { $0 + $1.clientChargeCents }))")
        lines.append("")
        lines.append("═══════════════════════════════════════")
        lines.append("")
        lines.append("DETAILS")
        lines.append("")

        for r in records {
            lines.append("• \(r.buddyName) → \(r.elderlyName)")
            lines.append("  \(r.taskCategory.displayName) · \(String(format: "%.2f", r.hours)) uur · \(r.paymentType.displayName)")
            if let mun = r.municipality { lines.append("  Gemeente: \(mun)") }
            lines.append("  Buddy: \(euros(r.buddyEarningsCents)) | Klant: \(euros(r.clientChargeCents)) | Winst: \(euros(r.profitCents))")
            lines.append("  Status: \(r.isFinalized ? "Definitief" : "Concept")")
            lines.append("")
        }

        let text = lines.joined(separator: "\n")
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.black
            ]
            text.draw(with: CGRect(x: 40, y: 40, width: 515, height: 760),
                      options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("factuur-\(month).pdf")
        try? data.write(to: url)
        return url
    }

    // MARK: - Helpers

    private func euros(_ cents: Int) -> String {
        String(format: "€ %.2f", Double(cents) / 100).replacingOccurrences(of: ".", with: ",")
    }

    private func monthLabel(_ month: String) -> String {
        let parts = month.split(separator: "-")
        guard parts.count == 2, let m = Int(parts[1]) else { return month }
        let names = ["", "jan", "feb", "mrt", "apr", "mei", "jun",
                     "jul", "aug", "sep", "okt", "nov", "dec"]
        return m < names.count ? "\(names[m]) \(parts[0])" : month
    }

    private func dateNow() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: Date())
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
                        typeTag
                    }
                }

                HStack(spacing: BCSpacing.sm) {
                    Label("Buddy: \(euros(record.buddyEarningsCents))", systemImage: "person.fill")
                    Spacer()
                    Label("Winst: \(euros(record.profitCents))", systemImage: "chart.line.uptrend.xyaxis")
                    Spacer()
                    if record.isFinalized {
                        Label("Definitief", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(BCColors.success)
                    } else {
                        Label("Concept", systemImage: "clock")
                            .foregroundStyle(BCColors.warning)
                    }
                }
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)

                if let mun = record.municipality {
                    HStack(spacing: BCSpacing.xs) {
                        Image(systemName: "building.columns.fill")
                        Text("ZiN — \(mun)")
                    }
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.primary)
                }
            }
        }
    }

    private var typeTag: some View {
        Text(record.paymentType.displayName)
            .font(BCTypography.caption)
            .foregroundStyle(BCColors.primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(BCColors.primary.opacity(0.10)))
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
                .font(BCTypography.headline)
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
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

// MARK: - UIActivityViewController wrapper

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    AdminBillingView().environment(AppState())
}
