import SwiftUI
import MarkdownUI

struct MealCorrelationCard: View {
    let log: FoodLog
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(alignment: .top, spacing: 12) {
                // Food photo thumbnail
                if let data = log.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.zzzyncSurface)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .foregroundStyle(Color.zzzyncMuted)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(log.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(log.timestamp.timeString + " · " + log.timestamp.shortDateString)
                        .font(.caption)
                        .foregroundStyle(Color.zzzyncMuted)

                    if let audit = log.auditResult {
                        verdictBadge(audit.timingVerdict)
                    }
                }

                Spacer()

                Button {
                    withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.zzzyncMuted)
                        .padding(6)
                }
            }

            if isExpanded, let audit = log.auditResult {
                Divider().background(Color.white.opacity(0.08))

                // One-liner insight
                InsightBubble(text: audit.metabolicInsight, icon: "waveform.path.ecg")

                // Hours from digestive sunset
                HStack {
                    Image(systemName: "sunset.fill")
                        .foregroundStyle(Color.zzzyncAccent)
                    let h = abs(audit.hoursFromDigestiveSunset)
                    let dir = audit.hoursFromDigestiveSunset > 0 ? "after" : "before"
                    Text(String(format: "%.1fh %@ Digestive Sunset", h, dir))
                        .font(.caption)
                        .foregroundStyle(Color.zzzyncMuted)
                }

                // Full narrative
                Markdown(audit.claudeNarrative)
                    .markdownTheme(.zzzync)
            }
        }
        .padding()
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(verdictBorderColor(log.auditResult?.timingVerdict).opacity(0.25), lineWidth: 1)
        )
    }

    private func verdictBadge(_ verdict: MetabolicAuditResult.TimingVerdict) -> some View {
        Text(verdict.label)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(verdictColor(verdict).opacity(0.2))
            .foregroundStyle(verdictColor(verdict))
            .clipShape(Capsule())
    }

    private func verdictColor(_ v: MetabolicAuditResult.TimingVerdict) -> Color {
        switch v {
        case .onClock:    return .zzzyncScoreGood
        case .borderline: return .zzzyncScoreWarn
        case .offClock:   return .zzzyncScoreBad
        }
    }

    private func verdictBorderColor(_ v: MetabolicAuditResult.TimingVerdict?) -> Color {
        guard let v else { return .clear }
        return verdictColor(v)
    }
}
