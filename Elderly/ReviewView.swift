import SwiftUI

struct ReviewView: View {
    @Environment(AppState.self) private var appState

    let buddyName: String
    let onDismiss: () -> Void

    @State private var selectedStars: Int = 0
    @State private var reviewText: String = ""
    @State private var submitted: Bool = false

    var body: some View {
        if submitted {
            thankYouView
        } else {
            reviewForm
        }
    }

    private var reviewForm: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Beoordeling", subtitle: "Hoe was het bezoek?")

            ScrollView {
                VStack(spacing: BCSpacing.xl) {
                    VStack(spacing: BCSpacing.md) {
                        ZStack {
                            Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 80, height: 80)
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(BCColors.primary)
                        }

                        Text("Hoe was het bezoek van \(buddyName)?")
                            .font(BCTypography.elderlyHeading)
                            .foregroundStyle(BCColors.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, BCSpacing.xl)
                    .padding(.horizontal, BCSpacing.lg)

                    // Large star buttons — minimum 60×60pt each per accessibility spec
                    HStack(spacing: BCSpacing.md) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                selectedStars = star
                            } label: {
                                Image(systemName: star <= selectedStars ? "star.fill" : "star")
                                    .font(.system(size: 38, weight: .semibold))
                                    .foregroundStyle(star <= selectedStars ? BCColors.warning : BCColors.border)
                                    .frame(width: 60, height: 60)
                                    .scaleEffect(star <= selectedStars ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.2), value: selectedStars)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(star) ster\(star == 1 ? "" : "ren")")
                        }
                    }

                    if selectedStars > 0 {
                        BCCard {
                            VStack(alignment: .leading, spacing: BCSpacing.xs) {
                                Text("Vertel er iets meer over (optioneel)")
                                    .font(BCTypography.subheadline)
                                    .foregroundStyle(BCColors.textSecondary)
                                TextField("Uw ervaring met dit bezoek…", text: $reviewText, axis: .vertical)
                                    .lineLimit(4, reservesSpace: true)
                                    .font(BCTypography.elderlyBody)
                                    .foregroundStyle(BCColors.textPrimary)
                            }
                        }
                        .padding(.horizontal, BCSpacing.lg)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer(minLength: BCSpacing.xl)
                }
            }

            VStack(spacing: BCSpacing.sm) {
                Divider()

                BCCTAButton(
                    title: "Verstuur beoordeling",
                    icon: "star.fill"
                ) {
                    appState.elderlySubmitsReview(stars: selectedStars, body: reviewText)
                    withAnimation { submitted = true }
                }
                .opacity(selectedStars > 0 ? 1.0 : 0.4)
                .disabled(selectedStars == 0)
                .padding(.horizontal, BCSpacing.lg)

                Button { onDismiss() } label: {
                    Text("Misschien later")
                        .font(BCTypography.elderlyCaption)
                        .foregroundStyle(BCColors.textTertiary)
                        .padding(.vertical, BCSpacing.sm)
                }
                .buttonStyle(.plain)
                .padding(.bottom, BCSpacing.md)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
    }

    private var thankYouView: some View {
        VStack(spacing: BCSpacing.xl) {
            Spacer()

            Image(systemName: "star.fill")
                .font(.system(size: 72))
                .foregroundStyle(BCColors.warning)

            VStack(spacing: BCSpacing.sm) {
                Text("Bedankt!")
                    .font(BCTypography.elderlyTitle)
                    .foregroundStyle(BCColors.textPrimary)
                Text("Uw beoordeling helpt ons om betere buddies te vinden.")
                    .font(BCTypography.elderlyBody)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BCSpacing.lg)
            }

            Spacer()

            BCPrimaryButton(title: "Terug naar huis", icon: "house.fill") {
                onDismiss()
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.xl)
        }
        .background(BCColors.background.ignoresSafeArea())
    }
}

#Preview {
    ReviewView(buddyName: "Aiyla", onDismiss: {})
        .environment(AppState())
}
