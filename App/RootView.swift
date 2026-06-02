import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Group {
                if !appState.hasSeenSplash {
                    // Geanimeerde openingspagina — altijd als eerste bij het opstarten.
                    // Het herstellen van een sessie loopt ondertussen op de achtergrond.
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            appState.hasSeenSplash = true
                        }
                    }
                } else if appState.isInitializing {
                    initLoadingScreen
                } else if appState.showLogin {
                    LoginView()
                } else {
                    switch appState.currentRole {
                    case .none:
                        RoleSelectionView()
                    case .elderly:
                        ElderlyTabView()
                    case .buddy:
                        BuddyTabView()
                    case .family:
                        FamilyTabView()
                    case .admin:
                        AdminTabView()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: appState.currentRole)
            .animation(.easeInOut(duration: 0.35), value: appState.hasSeenSplash)
            .animation(.easeInOut(duration: 0.2), value: appState.isInitializing)
            .animation(.easeInOut(duration: 0.25), value: appState.showLogin)

            // Global toast overlay
            if let toast = appState.toastMessage {
                VStack {
                    Spacer()
                    BCToast(message: toast.text, icon: toast.icon)
                        .padding(.bottom, 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
                .animation(.spring(response: 0.35), value: appState.toastMessage != nil)
            }
        }
        .animation(.spring(response: 0.35), value: appState.toastMessage != nil)
        .task { await appState.initialize() }
    }

    private var initLoadingScreen: some View {
        ZStack {
            BCColors.primary.ignoresSafeArea()
            VStack(spacing: BCSpacing.xl) {
                ZStack {
                    Circle()
                        .fill(BCColors.accent.opacity(0.18))
                        .frame(width: 96, height: 96)
                    Image(systemName: "house.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(BCColors.accent)
                }
                ProgressView()
                    .tint(.white.opacity(0.7))
                    .scaleEffect(1.2)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
}
