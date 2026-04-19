import SwiftUI

struct DashboardView: View {
    @State private var vm = DashboardViewModel()
    @State private var showForecast = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zzzyncBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Hero: Sync Score
                        heroSection

                        // Jetlag card
                        if let jetlag = vm.jetlagResult {
                            summaryCard(
                                title: "Social Jetlag",
                                icon: "moon.fill",
                                accent: Color.zzzyncPrimary
                            ) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(jetlag.chronotypeDrift)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.85))
                                    HStack {
                                        Text(String(format: "%.1fh jetlag", abs(jetlag.jetlagHours)))
                                            .font(.caption)
                                            .foregroundStyle(Color.zzzyncMuted)
                                        Spacer()
                                        ScoreBadge(score: jetlag.score)
                                    }
                                }
                            }
                        }

                        // Forecast card
                        if let forecast = vm.forecast {
                            Button { showForecast = true } label: {
                                summaryCard(
                                    title: "Energy Forecast",
                                    icon: "bolt.fill",
                                    accent: Color.zzzyncAccent
                                ) {
                                    if forecast.cognitiveClashes.isEmpty {
                                        Text("No cognitive clashes today.")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.zzzyncScoreGood)
                                    } else {
                                        Text("\(forecast.cognitiveClashes.count) clash\(forecast.cognitiveClashes.count == 1 ? "" : "es") detected")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.zzzyncScoreBad)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        // Recent food logs
                        if !vm.recentFoodLogs.isEmpty {
                            summaryCard(
                                title: "Recent Meals",
                                icon: "fork.knife",
                                accent: Color(red: 0.4, green: 0.85, blue: 0.6)
                            ) {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(vm.recentFoodLogs) { log in
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(log.description)
                                                    .font(.caption)
                                                    .foregroundStyle(.white.opacity(0.85))
                                                    .lineLimit(1)
                                                Text(log.timestamp.timeString)
                                                    .font(.caption2)
                                                    .foregroundStyle(Color.zzzyncMuted)
                                            }
                                            Spacer()
                                            if let audit = log.auditResult {
                                                verdictBadge(audit.timingVerdict)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Error
                        if let error = vm.error {
                            InsightBubble(text: error, icon: "exclamationmark.triangle.fill")
                        }

                        // Loading
                        if vm.isLoading {
                            LoadingCardView(message: "Analyzing with Claude...")
                        }
                    }
                    .padding()
                }
                .refreshable { await vm.refresh() }
            }
            .navigationTitle("zzzync")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await vm.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.zzzyncPrimary)
                    }
                    .disabled(vm.isLoading)
                }
            }
            .sheet(isPresented: $showForecast) {
                EnergyForecastView()
            }
        }
        .onAppear {
            vm.loadCachedData()
            if vm.jetlagResult == nil {
                Task { await vm.refresh() }
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            if vm.isLoading && vm.jetlagResult == nil {
                ProgressView()
                    .tint(Color.zzzyncPrimary)
                    .scaleEffect(1.5)
                    .frame(height: 180)
            } else {
                SyncScoreRing(score: vm.syncScore)
            }

            if let jetlag = vm.jetlagResult {
                Text(jetlag.jetlagDescription)
                    .font(.callout)
                    .foregroundStyle(Color.zzzyncMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func summaryCard<Content: View>(
        title: String,
        icon: String,
        accent: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(accent)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            content()
        }
        .padding()
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
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
        case .onClock:   return .zzzyncScoreGood
        case .borderline: return .zzzyncScoreWarn
        case .offClock:  return .zzzyncScoreBad
        }
    }
}
