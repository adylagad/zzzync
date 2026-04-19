import SwiftUI

struct DashboardView: View {
    @State private var vm = DashboardViewModel()
    @State private var showForecast = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zzzyncBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Hero ring
                        heroSection
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 24)

                        // Quick metrics row
                        if let jetlag = vm.jetlagResult {
                            metricsRow(jetlag: jetlag)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                        }

                        // Section: Circadian status
                        sectionHeader("Status")
                        if let jetlag = vm.jetlagResult {
                            jetlagCard(jetlag)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                        }

                        // Section: Today's energy
                        if let forecast = vm.forecast {
                            sectionHeader("Energy")
                            forecastCard(forecast)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                        }

                        // Section: Recent meals
                        if !vm.recentFoodLogs.isEmpty {
                            sectionHeader("Meals")
                            recentMealsCard
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                        }

                        // States
                        if vm.isLoading {
                            LoadingCardView(message: "Analyzing...")
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                        }
                        if let error = vm.error {
                            InsightBubble(text: error, icon: "exclamationmark.triangle.fill", color: .zzzyncRed)
                                .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 32)
                    }
                }
                .refreshable { await vm.refresh() }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.zzzyncBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await vm.refresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.zzzyncPrimary)
                    }
                    .disabled(vm.isLoading)
                }
            }
            .sheet(isPresented: $showForecast) {
                EnergyForecastView()
                    .presentationDetents([.large])
                    .presentationBackground(Color.zzzyncBackground)
            }
        }
        .onAppear {
            vm.loadCachedData()
            if vm.jetlagResult == nil { Task { await vm.refresh() } }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 20) {
            if vm.isLoading && vm.jetlagResult == nil {
                ZStack {
                    Circle()
                        .stroke(Color.zzzyncSurface2, lineWidth: 20)
                        .frame(width: 200, height: 200)
                    VStack(spacing: 6) {
                        ProgressView().tint(Color.zzzyncPrimary).scaleEffect(1.2)
                        Text("Analyzing…")
                            .font(.caption)
                            .foregroundStyle(Color.zzzyncMuted)
                    }
                }
            } else {
                SyncScoreRing(score: vm.syncScore)
            }

            if let jetlag = vm.jetlagResult {
                Text(jetlag.chronotypeDrift.conciseInsight(maxWords: 10))
                    .font(.subheadline)
                    .foregroundStyle(Color.zzzyncMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Quick metrics

    private func metricsRow(jetlag: SocialJetlagResult) -> some View {
        HStack(spacing: 10) {
            MetricTile(
                icon: "moon.fill",
                iconColor: .zzzyncPrimary,
                label: "Jetlag",
                value: String(format: "%.1f", abs(jetlag.jetlagHours)),
                unit: "hr"
            )
            MetricTile(
                icon: "waveform.path.ecg",
                iconColor: .zzzyncBlue,
                label: "HRV",
                value: {
                    let b = LocalStore.shared.loadBiometrics().last?.hrvMs
                    return b.map { String(format: "%.0f", $0) } ?? "--"
                }(),
                unit: "ms"
            )
            MetricTile(
                icon: "heart.fill",
                iconColor: .zzzyncRed,
                label: "RHR",
                value: {
                    let b = LocalStore.shared.loadBiometrics().last?.rhrBpm
                    return b.map { String(format: "%.0f", $0) } ?? "--"
                }(),
                unit: "bpm"
            )
        }
    }

    // MARK: - Section header (Apple Health style)

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
    }

    // MARK: - Jetlag card

    private func jetlagCard(_ jetlag: SocialJetlagResult) -> some View {
        HStack(spacing: 16) {
            // Score ring (small)
            ZStack {
                Circle()
                    .stroke(Color.zzzyncSurface2, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: Double(jetlag.score) / 100)
                    .stroke(Color.syncScoreColor(score: jetlag.score),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(jetlag.score)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(jetlag.jetlagDescription)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Label(
                    String(format: "%.1fh gap", abs(jetlag.jetlagHours)),
                    systemImage: "calendar.badge.clock"
                )
                .font(.caption)
                .foregroundStyle(Color.zzzyncMuted)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Forecast card

    private func forecastCard(_ forecast: EnergyForecast) -> some View {
        Button { showForecast = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.zzzyncBlue.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.zzzyncBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Energy Forecast")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    if forecast.cognitiveClashes.isEmpty {
                        Label("No clashes", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.zzzyncGreen)
                    } else {
                        Label("\(forecast.cognitiveClashes.count) clash\(forecast.cognitiveClashes.count == 1 ? "" : "es")",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.zzzyncAccent)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.zzzyncSubtle)
            }
            .padding(16)
            .background(Color.zzzyncSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent meals

    private var recentMealsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(vm.recentFoodLogs.enumerated()), id: \.element.id) { idx, log in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.zzzyncGreen.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "fork.knife")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.zzzyncGreen)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.description)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(log.timestamp.timeString)
                            .font(.caption)
                            .foregroundStyle(Color.zzzyncMuted)
                    }
                    Spacer()
                    if let audit = log.auditResult {
                        verdictPill(audit.timingVerdict)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if idx < vm.recentFoodLogs.count - 1 {
                    Divider()
                        .background(Color.zzzyncSurface2)
                        .padding(.leading, 64)
                }
            }
        }
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func verdictPill(_ v: MetabolicAuditResult.TimingVerdict) -> some View {
        let color: Color = v == .onClock ? .zzzyncGreen : v == .borderline ? .zzzyncScoreWarn : .zzzyncRed
        return Text(v.label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}
