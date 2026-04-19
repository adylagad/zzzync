import SwiftUI
import Charts

struct SleepMidpointChartData: Identifiable {
    let id = UUID()
    let date: Date
    let midpointHour: Double
    let firstEventHour: Double?
}

struct SleepMidpointChart: View {
    let data: [SleepMidpointChartData]

    private let yMin: Double = 0
    private let yMax: Double = 24

    var body: some View {
        Chart {
            ForEach(data) { point in
                // Sleep midpoint line
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Sleep Midpoint", point.midpointHour),
                    series: .value("Series", "Body Clock")
                )
                .foregroundStyle(Color.zzzyncPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .symbol(.circle)
                .symbolSize(30)

                // Area under sleep line
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    yStart: .value("Start", point.midpointHour),
                    yEnd: .value("End", point.firstEventHour ?? point.midpointHour)
                )
                .foregroundStyle(Color.zzzyncPrimary.opacity(0.08))

                // First event line
                if let eventHour = point.firstEventHour {
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("First Event", eventHour),
                        series: .value("Series", "Calendar")
                    )
                    .foregroundStyle(Color.zzzyncAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .symbol(.square)
                    .symbolSize(25)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(Color.white.opacity(0.1))
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    .foregroundStyle(Color.zzzyncMuted)
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 4, 8, 12, 16, 20, 24]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(Color.white.opacity(0.1))
                AxisValueLabel {
                    if let h = value.as(Double.self) {
                        let hour = Int(h) % 24
                        let ampm = hour < 12 ? "AM" : "PM"
                        let display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
                        Text("\(display)\(ampm)")
                            .font(.caption2)
                            .foregroundStyle(Color.zzzyncMuted)
                    }
                }
            }
        }
        .chartYScale(domain: yMin...yMax)
        .chartForegroundStyleScale([
            "Body Clock": Color.zzzyncPrimary,
            "Calendar": Color.zzzyncAccent
        ])
        .chartLegend(position: .top, alignment: .leading, spacing: 8)
        .frame(height: 200)
    }
}
