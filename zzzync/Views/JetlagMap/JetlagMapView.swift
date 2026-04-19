import SwiftUI

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
                    VStack(spacing: 0) {
                        // Score banner
                        if let result = vm.result {
                            scoreBanner(result)
                                .padding(.horizontal, 20)
                                .padding(.top, 4)
                                .padding(.bottom, 20)
                        }

                        // Chart section
                        sectionLabel("7-Day Drift")
                        chartCard
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)

                        // Narrative
                        if let result = vm.result {
                            sectionLabel("Insight")
                            narrativeCard(result)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                        }

                        if vm.isLoading {
                            LoadingCardView(message: "Calculating...")
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
                .refreshable { await vm.analyze() }
            }
            .navigationTitle("Jetlag")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.zzzyncBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await vm.analyze() } } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.zzzyncPrimary)
                    }
                    .disabled(vm.isLoading)
                }
            }
        }
        .onAppear { vm.load() }
    }

    // MARK: - Score banner

    private func scoreBanner(_ result: SocialJetlagResult) -> some View {
        HStack(spacing: 20) {
            // Big jetlag number
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "%.1f", abs(result.jetlagHours)))
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("jetlag hrs")
                    .font(.caption)
                    .foregroundStyle(Color.zzzyncMuted)
                    .tracking(0.5)
            }

            Spacer()

            // Sync score ring
            ZStack {
                Circle()
                    .stroke(Color.zzzyncSurface2, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: Double(result.score) / 100)
                    .stroke(Color.syncScoreColor(score: result.score),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 1) {
                    Text("\(result.score)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("sync")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.zzzyncMuted)
                        .tracking(1)
                }
            }
            .frame(width: 70, height: 70)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.zzzyncPrimary.opacity(0.18), Color.zzzyncSurface],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Chart card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if chartData.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "moon.zzz").font(.system(size: 32)).foregroundStyle(Color.zzzyncMuted)
                        Text("No sleep data").font(.subheadline).foregroundStyle(Color.zzzyncMuted)
                    }
                    .frame(height: 180)
                    Spacer()
                }
            } else {
                SleepMidpointChart(data: chartData)
            }

            // Legend
            HStack(spacing: 20) {
                legendDot(color: .zzzyncPrimary, label: "Body")
                legendDot(color: .zzzyncAccent, label: "Calendar")
                Spacer()
            }
        }
        .padding(16)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func narrativeCard(_ result: SocialJetlagResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(Color.zzzyncPrimary)
                Text("Quick Insight")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            Divider().background(Color.zzzyncSurface2)
            Text(result.claudeNarrative.conciseInsight(maxWords: 14))
                .font(.subheadline)
                .foregroundStyle(Color(white: 0.85))
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

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption).foregroundStyle(Color.zzzyncMuted)
        }
    }
}
