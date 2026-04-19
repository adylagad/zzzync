import SwiftUI

struct LoadingCardView: View {
    let message: String
    @State private var opacity: Double = 0.4

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(Color.zzzyncPrimary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.zzzyncMuted)
            }

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.zzzyncSurface)
                .frame(height: 14)
                .opacity(opacity)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.zzzyncSurface)
                .frame(height: 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 60)
                .opacity(opacity)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.zzzyncSurface)
                .frame(height: 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 30)
                .opacity(opacity)
        }
        .padding()
        .background(Color.zzzyncSurface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                opacity = 1.0
            }
        }
    }
}

struct InsightBubble: View {
    let text: String
    var icon: String = "sparkles"

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.zzzyncAccent)
                .font(.system(size: 14))
                .padding(.top, 2)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(14)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.zzzyncPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ScoreBadge: View {
    let score: Int
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.syncScoreColor(score: score).opacity(0.15))
            Text("\(score)")
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(Color.syncScoreColor(score: score))
        }
        .frame(width: size, height: size)
    }
}
