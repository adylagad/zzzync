import SwiftUI

struct ProtocolTimelineRow: View {
    let item: ProtocolItem
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline line + icon
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: item.category.systemImage)
                        .font(.system(size: 15))
                        .foregroundStyle(categoryColor)
                }
                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1)
                        .frame(minHeight: 20)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.time.timeString)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(categoryColor)
                    Text(item.category.label.uppercased())
                        .font(.caption2)
                        .foregroundStyle(Color.zzzyncMuted)
                        .tracking(0.8)
                }
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                Text(item.rationale)
                    .font(.caption)
                    .foregroundStyle(Color.zzzyncMuted)
                    .lineSpacing(3)
            }
            .padding(.bottom, isLast ? 0 : 12)
        }
    }

    private var categoryColor: Color {
        switch item.category {
        case .caffeine:      return Color(red: 0.9, green: 0.6, blue: 0.2)
        case .cognitiveWork: return Color.zzzyncPrimary
        case .meal:          return Color(red: 0.3, green: 0.85, blue: 0.55)
        case .rest:          return Color(red: 0.5, green: 0.4, blue: 0.9)
        case .exercise:      return Color(red: 0.2, green: 0.8, blue: 0.7)
        }
    }
}
