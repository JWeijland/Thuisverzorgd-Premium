import SwiftUI

/// Geanimeerde openingspagina. Toont kort het Thuisverzorgd-logo met een
/// minimale animatie en gaat daarna automatisch door naar het rolkeuze-
/// scherm. Eén tik slaat de animatie over.
struct SplashView: View {
    let onContinue: () -> Void

    /// Hoe lang de splash blijft staan voordat hij automatisch doorgaat.
    private let autoAdvanceAfter: TimeInterval = 2.4

    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var wordmarkOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 14
    @State private var taglineOpacity: Double = 0
    @State private var iconPulse: Bool = false
    @State private var hasContinued = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [BCColors.primary, BCColors.primaryDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: BCSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 128, height: 128)
                        .scaleEffect(iconPulse ? 1.08 : 1.0)
                    Circle()
                        .fill(BCColors.accent.opacity(0.22))
                        .frame(width: 104, height: 104)
                    Image(systemName: "house.fill")
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundStyle(BCColors.accent)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                VStack(spacing: BCSpacing.sm) {
                    (Text("Thuis").foregroundStyle(.white)
                     + Text("verzorgd").foregroundStyle(BCColors.accent))
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .opacity(wordmarkOpacity)
                        .offset(y: wordmarkOffset)

                    Text("Hulp om de hoek,\nmet een hart erbij.")
                        .font(.system(size: 19, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .opacity(taglineOpacity)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .onAppear { runAnimation() }
        .task {
            try? await Task.sleep(for: .seconds(autoAdvanceAfter))
            advance()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Thuisverzorgd. Hulp om de hoek, met een hart erbij.")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tik om door te gaan")
    }

    private func runAnimation() {
        // Icoon veert in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        // Woordmerk schuift omhoog en verschijnt
        withAnimation(.easeOut(duration: 0.5).delay(0.28)) {
            wordmarkOpacity = 1.0
            wordmarkOffset = 0
        }
        // Tagline verschijnt als laatste
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            taglineOpacity = 1.0
        }
        // Eén rustige pulse op het icoon
        withAnimation(.easeInOut(duration: 1.1).delay(0.9)) {
            iconPulse = true
        }
    }

    private func advance() {
        guard !hasContinued else { return }
        hasContinued = true
        onContinue()
    }
}

#Preview {
    SplashView(onContinue: {})
}
