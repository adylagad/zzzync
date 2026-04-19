import SwiftUI
import MarkdownUI

struct MealCorrelationCard: View {
    let log: FoodLog
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            Button {
                withAnimation(.spring(duration: 0.35, bounce: 0.1)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 14) {
                    // Photo or icon
                    Group {
                        if let data = log.imageData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                        } else {
                            ZStack {
                                Color.zzzyncSurface2
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.zzzyncMuted)
                            }
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.description)
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(.white).lineLimit(1)
                        Text(log.timestamp.timeString + "  ·  " + log.timestamp.shortDateString)
                            .font(.caption).foregroundStyle(Color.zzzyncMuted)
                        if let audit = log.auditResult {
                            verdictPill(audit.timingVerdict)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.zzzyncSubtle)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // Expanded detail
            if isExpanded, let audit = log.auditResult {
                Divider().background(Color.zzzyncSurface2)

                VStack(alignment: .leading, spacing: 12) {
                    // Insight row
                    InsightBubble(text: audit.metabolicInsight, icon: "waveform.path.ecg", color: .zzzyncBlue)

                    // Digestive sunset stat
                    HStack(spacing: 8) {
                        Image(systemName: "sunset.fill").foregroundStyle(Color.zzzyncAccent)
                        let h = abs(audit.hoursFromDigestiveSunset)
                        let dir = audit.hoursFromDigestiveSunset > 0 ? "after" : "before"
                        Text(String(format: "%.1fh %@ Digestive Sunset", h, dir))
                            .font(.caption).foregroundStyle(Color.zzzyncMuted)
                    }

                    Markdown(audit.claudeNarrative)
                        .markdownTheme(.zzzync)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(verdictBorderColor(log.auditResult?.timingVerdict).opacity(0.30), lineWidth: 1)
        )
    }

    private func verdictPill(_ v: MetabolicAuditResult.TimingVerdict) -> some View {
        let color: Color = v == .onClock ? .zzzyncGreen : v == .borderline ? .zzzyncScoreWarn : .zzzyncRed
        return Text(v.label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private func verdictBorderColor(_ v: MetabolicAuditResult.TimingVerdict?) -> Color {
        guard let v else { return .clear }
        return v == .onClock ? .zzzyncGreen : v == .borderline ? .zzzyncScoreWarn : .zzzyncRed
    }
}
