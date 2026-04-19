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

    var body: some View {
        Chart {
            ForEach(data) { point in
                // Shaded gap area between body clock and calendar
                if let eventHour = point.firstEventHour {
                    AreaMark(
                        x: .value("Date", point.date, unit: .day),
                        yStart: .value("Body", min(point.midpointHour, eventHour)),
                        yEnd: .value("Event", max(point.midpointHour, eventHour))
                    )
                    .foregroundStyle(Color.zzzyncPrimary.opacity(0.10))
                }

                // Body clock line
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Sleep Midpoint", point.midpointHour),
                    series: .value("Series", "Body Clock")
                )
                .foregroundStyle(Color.zzzyncPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .symbol {
                    Circle()
                        .fill(Color.zzzyncPrimary)
                        .frame(width: 8, height: 8)
                        .shadow(color: Color.zzzyncPrimary.opacity(0.6), radius: 3)
                }

                // First event line
                if let eventHour = point.firstEventHour {
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("First Event", eventHour),
                        series: .value("Series", "Calendar")
                    )
                    .foregroundStyle(Color.zzzyncAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .symbol {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.zzzyncAccent)
                            .frame(width: 7, height: 7)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                    .foregroundStyle(Color.white.opacity(0.07))
                AxisValueLabel(format: .dateTime.weekday(.narrow))
                    .foregroundStyle(Color.zzzyncMuted)
                    .font(.system(size: 10))
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 4, 8, 12, 16, 20, 24]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                    .foregroundStyle(Color.white.opacity(0.07))
                AxisValueLabel {
                    if let h = value.as(Double.self) {
                        let hour = Int(h) % 24
                        let display = hour == 0 ? "12AM" : hour < 12 ? "\(hour)AM" : hour == 12 ? "12PM" : "\(hour - 12)PM"
                        Text(display)
                            .font(.system(size: 9))
                            .foregroundStyle(Color.zzzyncMuted)
                    }
                }
            }
        }
        .chartYScale(domain: 0...24)
        .chartForegroundStyleScale([
            "Body Clock": Color.zzzyncPrimary,
            "Calendar":   Color.zzzyncAccent
        ])
        .chartLegend(.hidden)
        .frame(height: 190)
    }
}
