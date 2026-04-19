import SwiftUI

struct OnboardingFlow: View {
    @Environment(AppState.self) private var appState
    @State private var step = 0

    var body: some View {
        ZStack {
            Color.zzzyncBackground.ignoresSafeArea()

            TabView(selection: $step) {
                WelcomeStep(onNext: { step = 1 })
                    .tag(0)
                HealthPermissionView(onNext: { step = 2 })
                    .tag(1)
                CalendarPermissionView(onNext: { step = 3 })
                    .tag(2)
                APIKeyView(onComplete: {
                    appState.isOnboardingComplete = true
                })
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)
        }
    }
}

private struct WelcomeStep: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("zzz")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.zzzyncPrimary)
                Text("zzzync")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("The Social Jetlag Resolver")
                    .font(.subheadline)
                    .foregroundStyle(Color.zzzyncMuted)
                    .tracking(1)
                    .textCase(.uppercase)
            }

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "moon.fill", color: .zzzyncPrimary,
                           title: "Social Jetlag Score",
                           desc: "Discover the gap between your body clock and your calendar.")
                featureRow(icon: "fork.knife", color: Color(red: 0.3, green: 0.85, blue: 0.55),
                           title: "Metabolic Window Audit",
                           desc: "Find out if you're eating at the wrong time for your biology.")
                featureRow(icon: "brain.head.profile", color: Color.zzzyncAccent,
                           title: "Daily Bio-Protocol",
                           desc: "Get your optimal caffeine, focus, and meal windows.")
            }
            .padding(.horizontal)

            Spacer()

            Button(action: onNext) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.zzzyncPrimary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                Text(desc).font(.caption).foregroundStyle(Color.zzzyncMuted).lineSpacing(3)
            }
        }
    }
}
