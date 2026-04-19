import SwiftUI
import MarkdownUI

struct BioProtocolView: View {
    @State private var vm = BioProtocolViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zzzyncBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let proto = vm.bioProtocol {
                            // Key windows summary
                            keyWindowsCard(proto)

                            // Timeline
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Today's Protocol")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(.bottom, 16)

                                ForEach(Array(proto.protocolItems.enumerated()), id: \.element.id) { index, item in
                                    ProtocolTimelineRow(
                                        item: item,
                                        isLast: index == proto.protocolItems.count - 1
                                    )
                                }
                            }
                            .padding()
                            .background(Color.zzzyncSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            // Claude narrative
                            Markdown(proto.claudeNarrative)
                                .markdownTheme(.zzzync)
                                .padding()
                                .background(Color.zzzyncSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                        } else if !vm.isLoading {
                            emptyState
                        }

                        if vm.isLoading {
                            LoadingCardView(message: "Building your Bio-Protocol with Claude...")
                        }

                        if let error = vm.error {
                            InsightBubble(text: error, icon: "exclamationmark.triangle.fill")
                        }
                    }
                    .padding()
                }
                .refreshable { await vm.generate() }
            }
            .navigationTitle("Bio-Protocol")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await vm.generate() } } label: {
                        Image(systemName: "arrow.clockwise").foregroundStyle(Color.zzzyncPrimary)
                    }
                    .disabled(vm.isLoading)
                }
            }
        }
        .onAppear {
            vm.load()
            if vm.bioProtocol == nil {
                Task { await vm.generate() }
            }
        }
    }

    private func keyWindowsCard(_ proto: BioProtocol) -> some View {
        VStack(spacing: 12) {
            Text("Optimal Windows")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                windowPill(
                    icon: "cup.and.saucer.fill",
                    label: "Caffeine",
                    time: proto.caffeineWindowStart.timeString,
                    color: Color(red: 0.9, green: 0.6, blue: 0.2)
                )
                windowPill(
                    icon: "brain.head.profile",
                    label: "Peak Brain",
                    time: "\(proto.peakBrainWindowStart.timeString)–\(proto.peakBrainWindowEnd.timeString)",
                    color: Color.zzzyncPrimary
                )
                windowPill(
                    icon: "sunset.fill",
                    label: "Eat Before",
                    time: proto.digestiveSunset.timeString,
                    color: Color.zzzyncAccent
                )
            }
        }
        .padding()
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func windowPill(icon: String, label: String, time: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.zzzyncMuted)
                .textCase(.uppercase)
                .tracking(0.5)
            Text(time)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 60))
                .foregroundStyle(Color.zzzyncMuted)
            Text("No Bio-Protocol yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            Text("Run the Social Jetlag analysis first, then pull to generate your optimized 24-hour protocol.")
                .font(.subheadline)
                .foregroundStyle(Color.zzzyncMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
}
