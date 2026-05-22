import SwiftUI

struct SplashView: View {
    let onContinue: () -> Void
    var onDemoMap: (() -> Void)? = nil
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            BCColors.primary.ignoresSafeArea()

            VStack(spacing: BCSpacing.xl) {
                Spacer()

                VStack(spacing: BCSpacing.lg) {
                    ZStack {
                        Circle()
                            .fill(BCColors.accent.opacity(0.18))
                            .frame(width: 128, height: 128)
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 68, weight: .semibold))
                            .foregroundStyle(BCColors.accent)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            logoScale = 1.0
                            logoOpacity = 1.0
                        }
                    }

                    VStack(spacing: BCSpacing.sm) {
                        Text("Thuisverzorgt")
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Hulp om de hoek,\nmet een hart erbij.")
                            .font(.system(size: 20, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(logoOpacity)
                }

                Spacer()

                VStack(spacing: BCSpacing.md) {
                    Button {
                        onContinue()
                    } label: {
                        Text("Aan de slag")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(BCColors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background(
                                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                    .fill(.white)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, BCSpacing.lg)
                    .accessibilityLabel("Aan de slag, begin met Thuisverzorgt")

                    if let onDemoMap {
                        Button {
                            onDemoMap()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Demo: Buddy kaart")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.horizontal, BCSpacing.md)
                            .padding(.vertical, BCSpacing.xs)
                            .background(Capsule().fill(.white.opacity(0.12)))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Hulp nodig? Bel ons: \(Config.supportPhoneNumber)")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.bottom, BCSpacing.lg)
                }
            }
        }
    }
}

#Preview {
    SplashView(onContinue: {})
}
