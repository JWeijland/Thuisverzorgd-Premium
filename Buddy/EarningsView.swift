import SwiftUI

struct WalletView: View {
    private var availableCents: Int {
        MockData.earnings
            .filter { $0.date < Date().addingTimeInterval(-86400) }
            .reduce(0) { $0 + $1.amountCents }
    }

    private var pendingCents: Int {
        MockData.earnings
            .filter { $0.date >= Date().addingTimeInterval(-86400) }
            .reduce(0) { $0 + $1.amountCents }
    }

    private var totalThisWeek: Int {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return MockData.earnings.filter { $0.date >= weekStart }.reduce(0) { $0 + $1.amountCents }
    }

    private var totalThisMonth: Int {
        let monthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return MockData.earnings.filter { $0.date >= monthStart }.reduce(0) { $0 + $1.amountCents }
    }

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Wallet", subtitle: "Jouw saldo en verdiensten")

            ScrollView {
                VStack(spacing: BCSpacing.lg) {
                    // Hero wallet card
                    WalletHeroCard(availableCents: availableCents, pendingCents: pendingCents)
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.top, BCSpacing.md)

                    // Stats row
                    HStack(spacing: BCSpacing.sm) {
                        WalletStatPill(label: "Deze week", value: cents(totalThisWeek))
                        WalletStatPill(label: "Deze maand", value: cents(totalThisMonth))
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    // Transactions
                    VStack(spacing: BCSpacing.xs) {
                        HStack {
                            Text("Transacties")
                                .font(BCTypography.title3)
                                .foregroundStyle(BCColors.textPrimary)
                            Spacer()
                            Button("Exporteer voor belasting") { }
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.primary)
                        }
                        .padding(.horizontal, BCSpacing.lg)

                        VStack(spacing: 0) {
                            ForEach(Array(MockData.earnings.enumerated()), id: \.element.id) { index, entry in
                                TransactionRow(entry: entry)
                                if index < MockData.earnings.count - 1 {
                                    Divider()
                                        .padding(.leading, 68)
                                }
                            }
                        }
                        .background(BCColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous))
                        .padding(.horizontal, BCSpacing.lg)
                    }

                    Spacer().frame(height: BCSpacing.xl)
                }
            }
        }
        .background(BCColors.background.ignoresSafeArea())
    }

    private func cents(_ c: Int) -> String {
        String(format: "€ %.2f", Double(c) / 100).replacingOccurrences(of: ".", with: ",")
    }
}

// MARK: - Hero wallet card

private struct WalletHeroCard: View {
    let availableCents: Int
    let pendingCents: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BCRadius.xl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [BCColors.primary, BCColors.primary.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // subtle card texture circles
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 200, height: 200)
                .offset(x: 120, y: -60)
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 140, height: 140)
                .offset(x: -80, y: 80)

            VStack(alignment: .leading, spacing: BCSpacing.md) {
                HStack {
                    Label("Thuisverzorgd Wallet", systemImage: "wallet.pass.fill")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Image(systemName: "eurosign.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Beschikbaar saldo")
                        .font(BCTypography.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(formatted(availableCents))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Divider()
                    .background(Color.white.opacity(0.25))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("In behandeling")
                            .font(BCTypography.caption)
                            .foregroundStyle(.white.opacity(0.65))
                        Text(formatted(pendingCents))
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                    Button {
                    } label: {
                        Text("Uitbetalen")
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(BCColors.navy900)
                            .padding(.horizontal, BCSpacing.md)
                            .padding(.vertical, 10)
                            .background(Capsule(style: .continuous).fill(BCColors.accent))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(BCSpacing.lg)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: BCColors.primary.opacity(0.3), radius: 16, x: 0, y: 8)
    }

    private func formatted(_ cents: Int) -> String {
        String(format: "€ %.2f", Double(cents) / 100).replacingOccurrences(of: ".", with: ",")
    }
}

// MARK: - Stat pill

private struct WalletStatPill: View {
    let label: String
    let value: String

    var body: some View {
        BCCard {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                Text(value)
                    .font(BCTypography.title3)
                    .foregroundStyle(BCColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Transaction row

private struct TransactionRow: View {
    let entry: EarningEntry

    private var isPending: Bool {
        entry.date >= Date().addingTimeInterval(-86400)
    }

    var body: some View {
        HStack(spacing: BCSpacing.md) {
            Image(systemName: entry.category.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BCColors.primary)
                .frame(width: 40, height: 40)
                .background(Circle().fill(BCColors.primary.opacity(0.10)))

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.elderlyName)
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
                Text(entry.category.displayName)
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "+ € %.2f", Double(entry.amountCents) / 100)
                    .replacingOccurrences(of: ".", with: ","))
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(isPending ? BCColors.warning : BCColors.success)

                Text(isPending ? "In behandeling" : dateFormatter.string(from: entry.date))
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)
            }
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.vertical, BCSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "nl_NL")
    f.dateFormat = "d MMM"
    return f
}()

#Preview {
    WalletView().environment(AppState())
}
