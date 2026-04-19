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
                    VStack(spacing: 0) {
                        if let forecast = vm.forecast {
                            // Peak window banner
                            peakBanner(forecast)
                                .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 20)

                            // Energy curve
                            sectionLabel("Today's Energy Curve")
                            energyChartCard
                                .padding(.horizontal, 20).padding(.bottom, 20)

                            // Cognitive clashes
                            if !forecast.cognitiveClashes.isEmpty {
                                sectionLabel("Cognitive Clashes")
                                clashesCard(forecast.cognitiveClashes)
                                    .padding(.horizontal, 20).padding(.bottom, 20)
                            }

                            // Claude narrative
                            sectionLabel("Claude's Analysis")
                            narrativeCard(forecast.claudeNarrative)
                                .padding(.horizontal, 20).padding(.bottom, 20)

                        } else if !vm.isLoading {
                            emptyState
                        }

                        if vm.isLoading {
                            LoadingCardView(message: "Generating your energy forecast with Claude...")
                                .padding(.horizontal, 20)
                        }
                        if let error = vm.error {
                            InsightBubble(text: error, icon: "exclamationmark.triangle.fill", color: .zzzyncRed)
                                .padding(.horizontal, 20)
                        }
                        Spacer(minLength: 32)
                    }
                    .padding(.top, 8)
                }
                .refreshable { await vm.refresh() }
            }
            .navigationTitle("Energy Forecast")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.zzzyncBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await vm.refresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.zzzyncBlue)
                    }
                    .disabled(vm.isLoading)
                }
            }
        }
        .onAppear { vm.load() }
    }

    // MARK: - Peak Banner

    private func peakBanner(_ forecast: EnergyForecast) -> some View {
        let peakHour = forecast.hourlyEnergyLevel.max(by: { $0.value < $1.value })?.key ?? 10
        let peakDate = Calendar.current.date(bySettingHour: peakHour, minute: 0, second: 0, of: Date()) ?? Date()

        return HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.zzzyncBlue.opacity(0.15)).frame(width: 56, height: 56)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.zzzyncBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Peak Focus Window")
                    .font(.footnote).fontWeight(.semibold)
                    .foregroundStyle(Color.zzzyncMuted)
                    .tracking(0.6).textCase(.uppercase)
                Text(peakDate, style: .time)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(forecast.cognitiveClashes.count) cognitive clash\(forecast.cognitiveClashes.count == 1 ? "" : "es") detected")
                    .font(.caption)
                    .foregroundStyle(forecast.cognitiveClashes.isEmpty ? Color.zzzyncGreen : Color.zzzyncRed)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Chart Card

    private var energyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                legendDot(color: .zzzyncBlue, label: "Energy")
                legendDot(color: .zzzyncRed, label: "Clash")
            }

            if energyPoints.isEmpty {
                Text("No forecast data. Pull down to generate.")
                    .font(.subheadline).foregroundStyle(Color.zzzyncMuted)
                    .frame(height: 180).frame(maxWidth: .infinity)
            } else {
                CalendarDensityChart(
                    energyData: energyPoints,
                    events: vm.todayEvents,
                    clashes: vm.forecast?.cognitiveClashes ?? []
                )
            }
        }
        .padding(16)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.zzzyncMuted)
        }
    }

    // MARK: - Clashes Card

    private func clashesCard(_ clashes: [CognitiveClash]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(clashes.enumerated()), id: \.element.id) { idx, clash in
                clashRow(clash)
                if idx < clashes.count - 1 {
                    Divider().background(Color.zzzyncSurface2).padding(.leading, 52)
                }
            }
        }
        .padding(16)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func clashRow(_ clash: CognitiveClash) -> some View {
        let color: Color = {
            switch clash.severity {
            case .low:    return .zzzyncGreen
            case .medium: return .zzzyncAccent
            case .high:   return .zzzyncRed
            }
        }()
        return HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: clash.severity == .high ? "exclamationmark.triangle.fill" :
                      clash.severity == .medium ? "exclamationmark.circle.fill" : "info.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(clash.eventTitle)
                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                    Spacer()
                    Text(clash.eventStart.timeString)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(color)
                }
                Text(clash.suggestion)
                    .font(.caption).foregroundStyle(Color.zzzyncMuted).lineSpacing(3)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Narrative

    private func narrativeCard(_ narrative: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").foregroundStyle(Color.zzzyncBlue)
                Text("Claude's Analysis")
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
            }
            Divider().background(Color.zzzyncSurface2)
            Markdown(narrative).markdownTheme(.zzzync)
        }
        .padding(16)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.title3).fontWeight(.bold).foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20).padding(.bottom, 10)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Color.zzzyncBlue.opacity(0.10)).frame(width: 90, height: 90)
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 44)).foregroundStyle(Color.zzzyncBlue)
            }
            VStack(spacing: 8) {
                Text("No Forecast yet")
                    .font(.title3).fontWeight(.bold).foregroundStyle(.white)
                Text("Pull down to generate your energy forecast and see which meetings clash with your biology.")
                    .font(.subheadline).foregroundStyle(Color.zzzyncMuted)
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
            }
            Spacer()
        }
        .padding(.top, 60)
    }
}
