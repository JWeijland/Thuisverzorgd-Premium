import SwiftUI

struct BuddyTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            BuddyMapView()
                .tag(0)
                .tabItem { Label("Kaart", systemImage: "map.fill") }

            WalletView()
                .tag(1)
                .tabItem { Label("Portemonnee", systemImage: "wallet.pass.fill") }

            BuddyProfileView()
                .tag(2)
                .tabItem { Label("Profiel", systemImage: "person.crop.circle") }
        }
        .tint(BCColors.primary)
        .fullScreenCover(isPresented: Binding(
            get: { !appState.isOnboardingComplete },
            set: { if !$0 { appState.isOnboardingComplete = true } }
        )) {
            BuddyOnboardingFlow()
        }
    }
}

#Preview {
    BuddyTabView().environment(AppState())
}
