import SwiftUI

@main
struct ZzzyncApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isOnboardingComplete {
                    ContentView()
                } else {
                    OnboardingFlow()
                }
            }
            .preferredColorScheme(.dark)
            .environment(appState)
            .task {
                // Establish anonymous Supabase session on every launch
                await appState.authenticateSupabase()
            }
        }
    }
}
