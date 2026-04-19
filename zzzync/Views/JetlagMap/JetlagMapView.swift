import SwiftUI
import MarkdownUI

struct JetlagMapView: View {
    @State private var vm = JetlagViewModel()

    private var chartData: [SleepMidpointChartData] {
        let firstEventByDay = Dictionary(
            uniqueKeysWithValues: vm.firstEvents.map { ($0.startDate.startOfDay, $0.startDate.fractionalHour) }
        )
        return vm.sleepRecords.map { record in
            SleepMidpointChartData(
                date: record.date,
                midpointHour: record.midpoint.fractionalHour,
                firstEventHour: firstEventByDay[record.date.startOfDay]
            )
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zzzyncBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Chart
                        VStack(alignment: .leading, spacing: 10) {
                            Text("7-Day Midpoint Drift")
                                .font(.headline)
                                .foregroundStyle(.white)

                            if chartData.isEmpty {
                                Text("No sleep data yet. Allow HealthKit access to see your drift.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.zzzyncMuted)
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                            } else {
                                SleepMidpointChart(data: chartData)
                            }

                            HStack(spacing: 16) {
                                legendItem(color: .zzzyncPrimary, label: "Body Clock (sleep midpoint)")
                                legendItem(color: .zzzyncAccent, label: "Calendar (first event)")
                            }
                        }
                        .padding()
                        .background(Color.zzzyncSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Jetlag result
                        if let result = vm.result {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Social Jetlag")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    ScoreBadge(score: result.score, size: 44)
                                }

                                Text(result.jetlagDescription)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)

                                Divider().background(Color.white.opacity(0.1))

                                Markdown(result.claudeNarrative)
                                    .markdownTheme(.zzzync)
                            }
                            .padding()
                            .background(Color.zzzyncSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        if vm.isLoading {
                            LoadingCardView(message: "Calculating Social Jetlag...")
                        }

                        if let error = vm.error {
                            InsightBubble(text: error, icon: "exclamationmark.triangle.fill")
                        }
                    }
                    .padding()
                }
                .refreshable { await vm.analyze() }
            }
            .navigationTitle("Jetlag Map")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await vm.analyze() } } label: {
                        Image(systemName: "arrow.clockwise").foregroundStyle(Color.zzzyncPrimary)
                    }
                    .disabled(vm.isLoading)
                }
            }
        }
        .onAppear { vm.load() }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundStyle(Color.zzzyncMuted)
        }
    }
}

// MARK: - Markdown theme

extension Theme {
    static let zzzync = Theme()
        .text {
            ForegroundColor(.white.opacity(0.85))
            FontSize(15)
        }
        .strong {
            ForegroundColor(.white)
            FontWeight(.semibold)
        }
}
