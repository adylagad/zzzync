import SwiftUI
import Charts

struct EnergyPoint: Identifiable {
    let id = UUID()
    let hour: Int
    let energy: Double
}

struct CalendarDensityChart: View {
    let energyData: [EnergyPoint]
    let events: [CalendarEvent]
    let clashes: [CognitiveClash]

    var body: some View {
        Chart {
            // Energy area
            ForEach(energyData) { point in
                AreaMark(
                    x: .value("Hour", point.hour),
                    y: .value("Energy", point.energy)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.zzzyncPrimary.opacity(0.6), Color.zzzyncPrimary.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Hour", point.hour),
                    y: .value("Energy", point.energy)
                )
                .foregroundStyle(Color.zzzyncPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            // Clash markers
            ForEach(clashes) { clash in
                let hour = Calendar.current.component(.hour, from: clash.eventStart)
                RuleMark(x: .value("Clash", hour))
                    .foregroundStyle(clashColor(clash.severity).opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    .annotation(position: .top) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(clashColor(clash.severity))
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: [0, 6, 9, 12, 15, 18, 21]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(Color.white.opacity(0.1))
                AxisValueLabel {
                    if let h = value.as(Int.self) {
                        let ampm = h < 12 ? "AM" : "PM"
                        let display = h == 0 ? 12 : (h > 12 ? h - 12 : h)
                        Text("\(display)\(ampm)")
                            .font(.caption2)
                            .foregroundStyle(Color.zzzyncMuted)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 0.5, 1.0]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(Color.white.opacity(0.1))
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(v == 0 ? "Low" : v == 0.5 ? "Mid" : "Peak")
                            .font(.caption2)
                            .foregroundStyle(Color.zzzyncMuted)
                    }
                }
            }
        }
        .chartYScale(domain: 0...1)
        .frame(height: 180)
    }

    private func clashColor(_ severity: ClashSeverity) -> Color {
        switch severity {
        case .low:    return .zzzyncScoreGood
        case .medium: return .zzzyncScoreWarn
        case .high:   return .zzzyncScoreBad
        }
    }
}
