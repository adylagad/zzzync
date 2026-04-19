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

                Text("zzzync reads your calendar to find the gap between your first meeting and your biological wake time.")
                    .font(.subheadline)
                    .foregroundStyle(Color.zzzyncMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 12) {
                permRow("Meeting times and density", icon: "clock.fill")
                permRow("All calendars (including Google)", icon: "calendar.badge.checkmark")
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
                        Text("Calendar access granted").foregroundStyle(.white)
                    }
                    Button(action: onNext) {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.zzzyncPrimary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                } else {
                    Button {
                        Task { await requestAccess() }
                    } label: {
                        HStack {
                            if isRequesting { ProgressView().tint(.white) }
                            Text(isRequesting ? "Requesting..." : "Allow Calendar Access")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.zzzyncPrimary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isRequesting)

                    Button("Skip for now", action: onNext)
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
