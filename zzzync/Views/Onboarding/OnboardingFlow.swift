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
                CalendarPermissionView(onNext: {
                    appState.isOnboardingComplete = true
                })
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)

            // Step dots
            VStack {
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i == step ? Color.zzzyncPrimary : Color.zzzyncSurface2)
                            .frame(width: i == step ? 20 : 6, height: 6)
                            .animation(.spring(duration: 0.35), value: step)
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }
}

private struct WelcomeStep: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            VStack(spacing: 10) {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(Color.zzzyncPrimary.opacity(0.20))
                        .frame(width: 110, height: 110)
                        .blur(radius: 20)
                    Circle()
                        .fill(Color.zzzyncSurface)
                        .frame(width: 90, height: 90)
                    Text("zzz")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.zzzyncPrimary)
                }
                .padding(.bottom, 8)

                Text("zzzync")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Social Jetlag Resolver")
                    .font(.footnote).fontWeight(.semibold)
                    .foregroundStyle(Color.zzzyncMuted)
                    .tracking(1.2).textCase(.uppercase)
            }

            Spacer().frame(height: 48)

            // Feature rows
            VStack(spacing: 0) {
                featureRow(
                    icon: "moon.fill",
                    color: .zzzyncPrimary,
                    title: "Social Jetlag Score",
                    desc: "Discover the gap between your body clock and your calendar demands."
                )
                Divider().background(Color.zzzyncSurface2).padding(.leading, 66)

                featureRow(
                    icon: "fork.knife",
                    color: .zzzyncGreen,
                    title: "Metabolic Window Audit",
                    desc: "See if you're eating in sync with your circadian melatonin window."
                )
                Divider().background(Color.zzzyncSurface2).padding(.leading, 66)

                featureRow(
                    icon: "brain.head.profile",
                    color: .zzzyncAccent,
                    title: "Daily Bio-Protocol",
                    desc: "Get your optimal caffeine, peak focus, and last-meal windows."
                )
            }
            .background(Color.zzzyncSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 20)

            Spacer()

            Button(action: onNext) {
                Text("Get Started")
                    .font(.headline).fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.zzzyncPrimary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 56)
        }
    }

    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 42, height: 42)
                Image(systemName: icon).font(.system(size: 17)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                Text(desc)
                    .font(.caption).foregroundStyle(Color.zzzyncMuted).lineSpacing(3)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}
