import SwiftUI
import AuthenticationServices
import CryptoKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var currentNonce: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zzzyncBackground.ignoresSafeArea()

                VStack(spacing: 14) {
                    accountCard
                    actionCard
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Settings")
            .task {
                await appState.refreshAccountProfile()
            }
        }
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Account")
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                Text("Type")
                    .foregroundStyle(Color.zzzyncMuted)
                Spacer()
                Text(appState.accountProfile.isAnonymous ? "Anonymous" : "Apple")
                    .foregroundStyle(.white)
            }

            HStack {
                Text("User")
                    .foregroundStyle(Color.zzzyncMuted)
                Spacer()
                Text(shortUserID(appState.accountProfile.userId))
                    .foregroundStyle(.white)
                    .font(.system(.subheadline, design: .monospaced))
            }

            if let email = appState.accountProfile.email, !email.isEmpty {
                HStack {
                    Text("Email")
                        .foregroundStyle(Color.zzzyncMuted)
                    Spacer()
                    Text(email)
                        .foregroundStyle(.white)
                        .font(.subheadline)
                }
            }
        }
        .padding(16)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if appState.accountProfile.isAnonymous {
                SignInWithAppleButton(.signIn) { request in
                    let nonce = randomNonce()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                } onCompletion: { result in
                    handleAppleResult(result)
                }
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .disabled(appState.isAccountActionInFlight)
            } else {
                Label("Apple connected", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Color.zzzyncGreen)
                    .font(.subheadline.weight(.semibold))
            }

            if !appState.accountProfile.isAnonymous {
                Button {
                    Task { await appState.signOutAccount() }
                } label: {
                    Text("Sign Out")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.zzzyncSurface2)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(appState.isAccountActionInFlight)
            }

            if appState.isAccountActionInFlight {
                ProgressView()
                    .tint(Color.zzzyncPrimary)
            }

            if let error = appState.accountActionError, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.zzzyncRed)
            }
        }
        .padding(16)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            appState.accountActionError = error.localizedDescription
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentNonce,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                appState.accountActionError = "Apple sign-in failed."
                return
            }
            Task {
                await appState.upgradeAnonymousToApple(idToken: idToken, nonce: nonce)
            }
        }
    }

    private func shortUserID(_ id: UUID?) -> String {
        guard let raw = id?.uuidString else { return "—" }
        return String(raw.prefix(8))
    }

    private func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
