import SwiftUI

struct APIKeyView: View {
    let onComplete: () -> Void
    @Environment(AppState.self) private var appState
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var validationError: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.zzzyncPrimary)

                Text("Claude API Key")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("zzzync uses Claude to correlate your biometrics and generate insights. Enter your Anthropic API key to get started.")
                    .font(.subheadline)
                    .foregroundStyle(Color.zzzyncMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.caption)
                    .foregroundStyle(Color.zzzyncMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)

                SecureField("sk-ant-...", text: $apiKey)
                    .font(.system(.body, design: .monospaced))
                    .padding(14)
                    .background(Color.zzzyncSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Text("Your key is stored only on this device.")
                    .font(.caption2)
                    .foregroundStyle(Color.zzzyncMuted)
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task { await saveAndContinue() }
                } label: {
                    HStack {
                        if isValidating { ProgressView().tint(apiKey.hasPrefix("sk-ant") ? Color.zzzyncOnPrimary : .white) }
                        Text(isValidating ? "Validating..." : "Start zzzync")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(apiKey.hasPrefix("sk-ant") ? Color.zzzyncPrimary : Color.zzzyncSurface)
                    .foregroundStyle(apiKey.hasPrefix("sk-ant") ? Color.zzzyncOnPrimary : Color.zzzyncMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(apiKey.count < 10 || isValidating)

                if let error = validationError {
                    Text(error).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    private func saveAndContinue() async {
        isValidating = true
        validationError = nil
        onComplete()
        isValidating = false
    }
}
