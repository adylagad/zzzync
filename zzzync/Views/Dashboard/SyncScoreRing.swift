import SwiftUI

struct SyncScoreRing: View {
    let score: Int
    var size: CGFloat = 180
    @State private var animatedProgress: Double = 0

    private var progress: Double { Double(score) / 100.0 }
    private var scoreColor: Color { Color.syncScoreColor(score: score) }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.zzzyncSurface, lineWidth: size * 0.12)

            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [scoreColor.opacity(0.6), scoreColor],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Sync Score")
                    .font(.system(size: size * 0.1, weight: .medium))
                    .foregroundStyle(Color.zzzyncMuted)
                    .textCase(.uppercase)
                    .tracking(1)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(duration: 1.2, bounce: 0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: score) { _, _ in
            withAnimation(.spring(duration: 0.8)) {
                animatedProgress = progress
            }
        }
    }
}

#Preview {
    ZStack {
        Color.zzzyncBackground.ignoresSafeArea()
        VStack(spacing: 30) {
            SyncScoreRing(score: 72)
            SyncScoreRing(score: 45, size: 120)
            SyncScoreRing(score: 20, size: 100)
        }
    }
}
