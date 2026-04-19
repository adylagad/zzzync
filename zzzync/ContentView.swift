import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            JetlagMapView()
                .tabItem {
                    Label("Jetlag", systemImage: "moon.fill")
                }

            MetabolicAuditView()
                .tabItem {
                    Label("Metabolic", systemImage: "fork.knife")
                }

            BioProtocolView()
                .tabItem {
                    Label("Protocol", systemImage: "clock.badge.checkmark.fill")
                }
        }
        .tint(Color.zzzyncPrimary)
        .toolbarBackground(Color.zzzyncBackground.opacity(0.95), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
