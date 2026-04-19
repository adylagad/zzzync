import SwiftUI

struct CalendarPermissionView: View {
    let onNext: () -> Void
    @State private var isRequesting = false
    @State private var error: String?
    @State private var granted = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.zzzyncAccent)

                Text("Calendar Access")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Used to compare wake time vs first meeting.")
                    .font(.subheadline)
                    .foregroundStyle(Color.zzzyncMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 12) {
                permRow("First meeting time", icon: "clock.fill")
                permRow("All connected calendars", icon: "calendar.badge.checkmark")
            }
            .padding()
            .background(Color.zzzyncSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                if granted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("Calendar connected").foregroundStyle(.white)
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
                            Text(isRequesting ? "Requesting..." : "Allow Calendar")
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

    private func permRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.zzzyncAccent)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
        }
    }

    private func requestAccess() async {
        isRequesting = true
        do {
            try await CalendarService.shared.requestPermissions()
            granted = true
        } catch {
            self.error = error.localizedDescription
        }
        isRequesting = false
    }
}
