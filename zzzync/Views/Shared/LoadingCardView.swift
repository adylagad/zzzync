import SwiftUI

// MARK: - Loading skeleton

struct LoadingCardView: View {
    let message: String
    @State private var phase: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(Color.zzzyncPrimary)
                    .scaleEffect(0.85)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.zzzyncMuted)
            }
            skeletonLine(width: nil)
            skeletonLine(width: 0.75)
            skeletonLine(width: 0.55)
        }
        .padding(16)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func skeletonLine(width: CGFloat?) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(shimmerGradient(geo: geo))
                .frame(width: width.map { geo.size.width * $0 } ?? geo.size.width, height: 12)
        }
        .frame(height: 12)
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }

    private func shimmerGradient(geo: GeometryProxy) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.zzzyncSurface2, location: 0),
                .init(color: Color(white: 0.28), location: 0.4 + phase * 0.2),
                .init(color: Color.zzzyncSurface2, location: 0.8),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Insight bubble

struct InsightBubble: View {
    let text: String
    var icon: String = "sparkles"
    var color: Color = .zzzyncPrimary

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 13, weight: .semibold))
                .padding(.top, 1)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Color(white: 0.85))
                .lineSpacing(3)
        }
        .padding(14)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Score badge

struct ScoreBadge: View {
    let score: Int
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.syncScoreColor(score: score).opacity(0.18))
            Text("\(score)")
                .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                .foregroundStyle(Color.syncScoreColor(score: score))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Health metric tile (Apple Health-style)

struct MetricTile: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    var unit: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .tracking(0.5)
            }
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.zzzyncMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
