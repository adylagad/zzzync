import SwiftUI
import Observation

@Observable
final class AppState {
    var isOnboardingComplete: Bool = UserDefaults.standard.bool(forKey: "onboardingComplete") {
        didSet { UserDefaults.standard.set(isOnboardingComplete, forKey: "onboardingComplete") }
    }

    var hasHealthKitPermission = false
    var hasCalendarPermission = false
    var isAuthenticatedWithSupabase = false
    var accountProfile: SupabaseService.AccountProfile = .signedOut
    var isAccountActionInFlight = false
    var accountActionError: String?

    /// Called once at app launch. Signs in anonymously so every device gets a user_id
    /// without requiring the user to create an account.
    func authenticateSupabase() async {
        if HackathonDemoScenario.isEnabled {
            HackathonDemoScenario.installFixedDataIfNeeded(force: false)
            await MainActor.run {
                isAuthenticatedWithSupabase = false
                accountProfile = .signedOut
                accountActionError = nil
            }
            return
        }

        do {
            try await SupabaseService.shared.signInAnonymously()
            await LocalStore.shared.syncFromCloud()
            await LocalStore.shared.flushPendingSync()
            let profile = await SupabaseService.shared.accountProfile()
            await MainActor.run { isAuthenticatedWithSupabase = true }
            await MainActor.run { accountProfile = profile }
        } catch {
            // Non-fatal — app still works fully offline via LocalStore
            print("[Supabase] Anonymous auth failed: \(error.localizedDescription)")
        }
    }

    func refreshAccountProfile() async {
        let profile = await SupabaseService.shared.accountProfile()
        await MainActor.run { accountProfile = profile }
    }

    func upgradeAnonymousToApple(idToken: String, nonce: String) async {
        await MainActor.run {
            isAccountActionInFlight = true
            accountActionError = nil
        }

        do {
            try await SupabaseService.shared.signInWithApple(idToken: idToken, nonce: nonce)
            LocalStore.shared.enqueueFullCloudResync()
            await LocalStore.shared.syncFromCloud()
            await LocalStore.shared.flushPendingSync()
            await refreshAccountProfile()
        } catch {
            await MainActor.run {
                accountActionError = error.localizedDescription
            }
        }

        await MainActor.run {
            isAccountActionInFlight = false
        }
    }

    func signOutAccount() async {
        await MainActor.run {
            isAccountActionInFlight = true
            accountActionError = nil
        }

        do {
            try await SupabaseService.shared.signOut()
            LocalStore.shared.clearAllLocalData()
            try await SupabaseService.shared.signInAnonymously()
            await LocalStore.shared.syncFromCloud()
            await refreshAccountProfile()
        } catch {
            await MainActor.run {
                accountActionError = error.localizedDescription
            }
        }

        await MainActor.run {
            isAccountActionInFlight = false
        }
    }
}
