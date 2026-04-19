import SwiftUI

struct HealthPermissionView: View {
    let onNext: () -> Void
    @State private var isRequesting = false
    @State private var error: String?
    @State private var granted = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)

                Text("Health Access")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Used for your Jetlag score.")
                    .font(.subheadline)
                    .foregroundStyle(Color.zzzyncMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            dataPoints

            Spacer()

            VStack(spacing: 12) {
                if granted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("Health connected").foregroundStyle(.white)
                    }
                    Button(action: onNext) {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.zzzyncPrimary)
                            .foregroundStyle(Color.zzzyncOnPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                } else {
                    Button {
                        Task { await requestAccess() }
                    } label: {
                        HStack {
                            if isRequesting { ProgressView().tint(Color.zzzyncOnPrimary) }
                            Text(isRequesting ? "Requesting..." : "Allow Health")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.zzzyncPrimary)
                        .foregroundStyle(Color.zzzyncOnPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isRequesting)

                    Button("Skip", action: onNext)
                        .font(.subheadline)
                        .foregroundStyle(Color.zzzyncMuted)
                }

                if let error {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    private var dataPoints: some View {
        VStack(alignment: .leading, spacing: 12) {
            permRow("Sleep", icon: "moon.zzz.fill")
            permRow("HRV", icon: "waveform.path.ecg")
            permRow("Resting HR", icon: "heart.circle.fill")
        }
        .padding()
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func permRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.zzzyncPrimary)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.caption)
                .foregroundStyle(Color.zzzyncMuted)
        }
    }

    private func requestAccess() async {
        isRequesting = true
        do {
            try await HealthKitService.shared.requestPermissions()
            granted = true
        } catch {
            self.error = error.localizedDescription
        }
        isRequesting = false
    }
}
