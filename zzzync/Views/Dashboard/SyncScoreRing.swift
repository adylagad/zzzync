import SwiftUI

struct SyncScoreRing: View {
    let score: Int
    var size: CGFloat = 200
    @State private var animatedProgress: Double = 0

    private var progress: Double  { Double(score) / 100.0 }
    private var scoreColor: Color { .syncScoreColor(score: score) }
    private var ringWidth: CGFloat { size * 0.10 }

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(scoreColor.opacity(0.15), style: StrokeStyle(lineWidth: ringWidth + 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .blur(radius: 8)

            // Track ring
            Circle()
                .stroke(Color.zzzyncSurface2, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        stops: [
                            .init(color: scoreColor.opacity(0.5), location: 0),
                            .init(color: scoreColor,              location: 0.6),
                            .init(color: scoreColor.opacity(0.9), location: 1),
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: scoreColor.opacity(0.5), radius: 8, x: 0, y: 0)

            // Tip dot
            if animatedProgress > 0.02 {
                Circle()
                    .fill(scoreColor)
                    .frame(width: ringWidth * 0.85, height: ringWidth * 0.85)
                    .shadow(color: scoreColor, radius: 4)
                    .offset(y: -(size / 2))
                    .rotationEffect(.degrees(-90 + animatedProgress * 360))
            }

            // Center text
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: size * 0.28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("SYNC")
                    .font(.system(size: size * 0.085, weight: .bold))
                    .foregroundStyle(Color.zzzyncMuted)
                    .tracking(2.5)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(duration: 1.4, bounce: 0.15).delay(0.1)) {
                animatedProgress = progress
            }
        }
        .onChange(of: score) { _, _ in
            withAnimation(.spring(duration: 0.9)) {
                animatedProgress = progress
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 40) {
            SyncScoreRing(score: 78)
            HStack(spacing: 30) {
                SyncScoreRing(score: 45, size: 110)
                SyncScoreRing(score: 22, size: 110)
            }
        }
    }
}
