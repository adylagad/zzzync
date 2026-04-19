import SwiftUI

struct ProtocolTimelineRow: View {
    let item: ProtocolItem
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline column
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: item.category.systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(categoryColor)
                }
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [categoryColor.opacity(0.3), Color.zzzyncSurface2],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 1.5)
                        .frame(minHeight: 24)
                }
            }

            // Content column
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .center, spacing: 8) {
                    Text(item.time.timeString)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(categoryColor)
                    Text(item.category.label.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.zzzyncMuted)
                        .tracking(1.2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(categoryColor.opacity(0.12))
                        .clipShape(Capsule())
                }
                Text(item.title)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(item.rationale)
                    .font(.caption)
                    .foregroundStyle(Color.zzzyncMuted)
                    .lineSpacing(3)
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
    }

    private var categoryColor: Color {
        switch item.category {
        case .caffeine:      return Color.zzzyncAccent
        case .cognitiveWork: return Color.zzzyncPrimary
        case .meal:          return Color.zzzyncGreen
        case .rest:          return Color.zzzyncTeal
        case .exercise:      return Color.zzzyncBlue
        }
    }
}
