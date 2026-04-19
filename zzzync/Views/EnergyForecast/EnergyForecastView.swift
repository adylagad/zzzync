import SwiftUI
import MarkdownUI

struct EnergyForecastView: View {
    @State private var vm = ForecastViewModel()

    private var energyPoints: [EnergyPoint] {
        guard let forecast = vm.forecast else { return [] }
        return (0...23).map { hour in
            EnergyPoint(hour: hour, energy: forecast.hourlyEnergyLevel[hour] ?? 0.5)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zzzyncBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Energy chart
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Today's Energy Curve")
                                .font(.headline)
                                .foregroundStyle(.white)

                            if energyPoints.isEmpty {
                                Text("No forecast data. Pull to refresh.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.zzzyncMuted)
                                    .frame(height: 180)
                                    .frame(maxWidth: .infinity)
                            } else {
                                CalendarDensityChart(
                                    energyData: energyPoints,
                                    events: vm.todayEvents,
                                    clashes: vm.forecast?.cognitiveClashes ?? []
                                )
                            }
                        }
                        .padding()
                        .background(Color.zzzyncSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Cognitive clashes
                        if let forecast = vm.forecast, !forecast.cognitiveClashes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Cognitive Clashes")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                ForEach(forecast.cognitiveClashes) { clash in
                                    clashRow(clash)
                                }
                            }
                            .padding()
                            .background(Color.zzzyncSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        // Claude narrative
                        if let narrative = vm.forecast?.claudeNarrative {
                            Markdown(narrative)
                                .markdownTheme(.zzzync)
                                .padding()
                                .background(Color.zzzyncSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        if vm.isLoading {
                            LoadingCardView(message: "Generating energy forecast...")
                        }

                        if let error = vm.error {
                            InsightBubble(text: error, icon: "exclamationmark.triangle.fill")
                        }
                    }
                    .padding()
                }
                .refreshable { await vm.refresh() }
            }
            .navigationTitle("Energy Forecast")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await vm.refresh() } } label: {
                        Image(systemName: "arrow.clockwise").foregroundStyle(Color.zzzyncPrimary)
                    }
                    .disabled(vm.isLoading)
                }
            }
        }
        .onAppear { vm.load() }
    }

    private func clashRow(_ clash: CognitiveClash) -> some View {
        HStack(alignment: .top, spacing: 12) {
            clashSeverityDot(clash.severity)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(clash.eventTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(clash.eventStart.timeString)
                        .font(.caption)
                        .foregroundStyle(Color.zzzyncMuted)
                }
                Text(clash.suggestion)
                    .font(.caption)
                    .foregroundStyle(Color.zzzyncMuted)
                    .lineSpacing(3)
            }
        }
    }

    private func clashSeverityDot(_ severity: ClashSeverity) -> some View {
        let color: Color = {
            switch severity {
            case .low:    return .zzzyncScoreGood
            case .medium: return .zzzyncScoreWarn
            case .high:   return .zzzyncScoreBad
            }
        }()
        return Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .padding(.top, 4)
    }
}
