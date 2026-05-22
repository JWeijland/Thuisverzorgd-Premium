import SwiftUI

struct WMOGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BCSpacing.lg) {
                    introBanner
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.top, BCSpacing.md)

                    stepsSection
                        .padding(.horizontal, BCSpacing.lg)

                    pgbHighlight
                        .padding(.horizontal, BCSpacing.lg)

                    contactNote
                        .padding(.horizontal, BCSpacing.lg)

                    Spacer().frame(height: BCSpacing.xl)
                }
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Vergoeding via Wmo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
    }

    private var introBanner: some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                HStack(spacing: BCSpacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(BCColors.primary)
                    Text("Wat is de Wmo?")
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                }
                Text("De Wet maatschappelijke ondersteuning (Wmo) helpt mensen bij dagelijkse taken. Via uw gemeente kunt u financiering aanvragen — ook als Persoonsgebonden Budget (PGB) waarmee u zelf een Buddy kiest.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
            }
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Zo werkt het")
                .font(BCTypography.subheadline)
                .foregroundStyle(BCColors.textSecondary)
                .padding(.bottom, BCSpacing.md)

            ForEach(Array(wmoSteps.enumerated()), id: \.element.id) { index, step in
                WMOStepRow(step: step, isLast: index == wmoSteps.count - 1)
            }
        }
    }

    private var pgbHighlight: some View {
        BCCard {
            HStack(alignment: .top, spacing: BCSpacing.md) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(BCColors.warning)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: BCSpacing.xs) {
                    Text("Thuisverzorgd betalen via PGB")
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Heeft u een PGB-indicatie? Dan kunt u een Buddy via Thuisverzorgd betalen. U sluit een zorgovereenkomst af en de SVB betaalt de Buddy rechtstreeks — u betaalt niets zelf bij.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                }
            }
        }
    }

    private var contactNote: some View {
        BCCard {
            HStack(alignment: .top, spacing: BCSpacing.md) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(BCColors.primary)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: BCSpacing.xs) {
                    Text("Neem contact op met uw gemeente")
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Zoek het Wmo-loket via de website van uw gemeente, of bel het gemeentelijke nummer. Uw huisarts of een medewerker van Thuisverzorgd kan u ook verder helpen.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Data

private struct WMOStep: Identifiable {
    let id: Int
    let icon: String
    let title: String
    let description: String
}

private let wmoSteps = [
    WMOStep(
        id: 1,
        icon: "building.2.fill",
        title: "Aanmelding bij de gemeente",
        description: "Bel of bezoek het Wmo-loket van uw gemeente. U, een familielid of uw huisarts kan de aanmelding doen. Dit is gratis en vrijblijvend."
    ),
    WMOStep(
        id: 2,
        icon: "person.2.fill",
        title: "Keukentafelgesprek",
        description: "Een medewerker van de gemeente komt bij u thuis. Samen kijkt u wat u nog zelf kunt, wat uw omgeving kan bieden en welke extra hulp nodig is."
    ),
    WMOStep(
        id: 3,
        icon: "doc.text.magnifyingglass",
        title: "Beoordeling door de gemeente",
        description: "De gemeente bepaalt of u recht heeft op Wmo-ondersteuning en hoeveel uur hulp per week. U ontvangt binnen 8 weken een officieel besluit."
    ),
    WMOStep(
        id: 4,
        icon: "arrow.triangle.branch",
        title: "Kies: Zorg in Natura of PGB",
        description: "Zorg in Natura: de gemeente regelt de hulp direct. PGB: u krijgt een budget om zelf iemand in te huren — zoals een Buddy via Thuisverzorgd."
    ),
    WMOStep(
        id: 5,
        icon: "doc.badge.plus",
        title: "Zorgovereenkomst opstellen",
        description: "Bij een PGB sluit u een officiële zorgovereenkomst af met uw Buddy. Dit formulier dient u in bij de Sociale Verzekeringsbank (SVB)."
    ),
    WMOStep(
        id: 6,
        icon: "eurosign.circle.fill",
        title: "SVB betaalt uw Buddy",
        description: "De SVB beheert uw PGB-budget en betaalt uw Buddy rechtstreeks na goedkeuring van de gewerkte uren. U houdt zelf de regie."
    )
]

// MARK: - Step Row

private struct WMOStepRow: View {
    let step: WMOStep
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: BCSpacing.md) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(BCColors.primary.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Text("\(step.id)")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(BCColors.primary)
                }
                if !isLast {
                    Rectangle()
                        .fill(BCColors.border)
                        .frame(width: 2, height: 28)
                }
            }

            VStack(alignment: .leading, spacing: BCSpacing.xs) {
                HStack(spacing: BCSpacing.xs) {
                    Image(systemName: step.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BCColors.primary)
                    Text(step.title)
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                }
                Text(step.description)
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : BCSpacing.md)
        }
    }
}
