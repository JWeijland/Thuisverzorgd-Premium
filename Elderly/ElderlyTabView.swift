import SwiftUI

struct ElderlyTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selection: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                ElderlyHomeView()
                    .tag(0)
                    .tabItem {
                        Label("Hulp", systemImage: "house.fill")
                    }

                if !appState.isCordaanElderly {
                    MyBuddiesView()
                        .tag(1)
                        .tabItem {
                            Label("Buddies", systemImage: "person.2.fill")
                        }
                }

                // Betalingen alleen voor particuliere cliënten — Cordaan-zorg loopt via de instelling
                if !appState.isCordaanElderly {
                    PaymentOverviewView()
                        .tag(2)
                        .tabItem {
                            Label("Betalingen", systemImage: "eurosign.circle.fill")
                        }
                }

                ElderlyProfileView()
                    .tag(3)
                    .tabItem {
                        Label("Profiel", systemImage: "person.crop.circle")
                    }
            }
            .tint(BCColors.primary)
            .environment(\.largeTextEnabled, appState.largeTextEnabled)
        }
        .fullScreenCover(isPresented: Binding(
            get: { appState.showSOS },
            set: { appState.showSOS = $0 })
        ) {
            SOSView()
        }
    }
}

#Preview {
    ElderlyTabView().environment(AppState())
}
