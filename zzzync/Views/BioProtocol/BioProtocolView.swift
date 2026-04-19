import SwiftUI
import MarkdownUI

struct BioProtocolView: View {
    @State private var vm = BioProtocolViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zzzyncBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        if let proto = vm.bioProtocol {
                            // Windows banner
                            windowsBanner(proto)
                                .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 20)

                            // Timeline
                            sectionLabel("Today's Schedule")
                            timelineCard(proto)
                                .padding(.horizontal, 20).padding(.bottom, 20)

                            // Narrative
                            sectionLabel("Claude's Rationale")
                            narrativeCard(proto.claudeNarrative)
                                .padding(.horizontal, 20).padding(.bottom, 20)

                        } else if !vm.isLoading {
                            emptyState
                        }

                        if vm.isLoading {
                            LoadingCardView(message: "Building your Bio-Protocol with Claude...")
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
                .refreshable { await vm.generate() }
            }
            .navigationTitle("Bio-Protocol")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.zzzyncBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await vm.generate() } } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.zzzyncPrimary)
                    }
                    .disabled(vm.isLoading)
                }
            }
        }
        .onAppear {
            vm.load()
            if vm.bioProtocol == nil { Task { await vm.generate() } }
        }
    }

    // MARK: - Windows banner

    private func windowsBanner(_ proto: BioProtocol) -> some View {
        VStack(spacing: 14) {
            Text("Optimal Windows")
                .font(.footnote).fontWeight(.semibold)
                .foregroundStyle(Color.zzzyncMuted)
                .tracking(0.8).textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                windowChip(
                    icon: "cup.and.saucer.fill",
                    label: "Caffeine",
                    time: proto.caffeineWindowStart.timeString,
                    color: .zzzyncAccent
                )
                windowChip(
                    icon: "brain.head.profile",
                    label: "Peak Brain",
                    time: proto.peakBrainWindowStart.timeString,
                    color: .zzzyncPrimary
                )
                windowChip(
                    icon: "moon.fill",
                    label: "Last Meal",
                    time: proto.digestiveSunset.timeString,
                    color: .zzzyncTeal
                )
            }
        }
        .padding(16)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func windowChip(icon: String, label: String, time: String, color: Color) -> some View {
        VStack(spacing: 7) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(color)
            }
            Text(label)
                .font(.system(size: 9, weight: .semibold)).foregroundStyle(Color.zzzyncMuted)
                .tracking(0.5).textCase(.uppercase)
            Text(time)
                .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Timeline

    private func timelineCard(_ proto: BioProtocol) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(proto.protocolItems.enumerated()), id: \.element.id) { idx, item in
                ProtocolTimelineRow(item: item, isLast: idx == proto.protocolItems.count - 1)
            }
        }
        .padding(16)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Narrative

    private func narrativeCard(_ narrative: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").foregroundStyle(Color.zzzyncPrimary)
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
                Circle().fill(Color.zzzyncPrimary.opacity(0.10)).frame(width: 90, height: 90)
                Image(systemName: "clock.badge.checkmark.fill")
                    .font(.system(size: 40)).foregroundStyle(Color.zzzyncPrimary)
            }
            VStack(spacing: 8) {
                Text("No Protocol yet")
                    .font(.title3).fontWeight(.bold).foregroundStyle(.white)
                Text("Complete the Jetlag analysis first, then pull down to generate your optimized 24-hour protocol.")
                    .font(.subheadline).foregroundStyle(Color.zzzyncMuted)
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
            }
            Spacer()
        }
        .padding(.top, 60)
    }
}
