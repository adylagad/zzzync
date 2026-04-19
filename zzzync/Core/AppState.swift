import SwiftUI
import Observation

@Observable
final class AppState {
    var isOnboardingComplete: Bool {
        get { UserDefaults.standard.bool(forKey: "onboardingComplete") }
        set { UserDefaults.standard.set(newValue, forKey: "onboardingComplete") }
    }

    var hasHealthKitPermission = false
    var hasCalendarPermission = false
    var isAuthenticatedWithSupabase = false

    /// Called once at app launch. Signs in anonymously so every device gets a user_id
    /// without requiring the user to create an account.
    func authenticateSupabase() async {
        do {
            try await SupabaseService.shared.signInAnonymously()
            await MainActor.run { isAuthenticatedWithSupabase = true }
        } catch {
            // Non-fatal — app still works fully offline via LocalStore
            print("[Supabase] Anonymous auth failed: \(error.localizedDescription)")
        }
    }
}
