import SwiftUI

struct AICausalView: View {
    @State private var vm = AICausalViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zzzyncBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        questionCard
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 20)

                        sectionLabel("Signals")
                        signalsGrid
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)

                        if let answer = vm.answer {
                            sectionLabel("Answer")
                            summaryCard(answer)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 14)

                            causesCard(answer.causes)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 14)

                            actionsCard(answer.actions)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                        }

                        if vm.isLoading {
                            LoadingCardView(message: "Finding causes...")
                                .padding(.horizontal, 20)
                                .padding(.bottom, 14)
                        }

                        if let error = vm.error, !error.isEmpty {
                            InsightBubble(text: error, icon: "exclamationmark.triangle.fill", color: .zzzyncRed)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 14)
                        }
                    }
                }
                .refreshable { await vm.ask() }
            }
            .navigationTitle("AI")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.zzzyncBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await vm.ask() } } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.zzzyncPrimary)
                    }
                    .disabled(vm.isLoading)
                }
            }
        }
        .onAppear { vm.load() }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Causal Engine")
                .font(.headline)
                .foregroundStyle(.white)

            TextField("Ask: Why am I tired?", text: $vm.question, axis: .vertical)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .lineLimit(1...3)
                .padding(12)
                .background(Color.zzzyncSurface2)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 10) {
                Button {
                    vm.useDefaultQuestion()
                } label: {
                    Text("Why am I tired?")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.zzzyncPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.zzzyncPrimary.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer()

                Button {
                    Task { await vm.ask() }
                } label: {
                    Text("Ask AI")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.zzzyncOnPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.zzzyncPrimary)
                        .clipShape(Capsule())
                }
                .disabled(vm.isLoading)
            }
        }
        .padding(16)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var signalsGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(vm.signalChips) { chip in
                VStack(alignment: .leading, spacing: 4) {
                    Text(chip.title)
                        .font(.caption)
                        .foregroundStyle(Color.zzzyncMuted)
                    Text(chip.value)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(chip.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.zzzyncSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func summaryCard(_ answer: FatigueAnswer) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.zzzyncPrimary.opacity(0.16)).frame(width: 36, height: 36)
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.zzzyncPrimary)
            }
            Text(answer.summary.conciseInsight(maxWords: 14))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(14)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func causesCard(_ causes: [FatigueCause]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(causes.prefix(4).enumerated()), id: \.element.id) { index, cause in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(cause.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(cause.impactScore)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.zzzyncAccent)
                    }

                    Text(cause.evidence.conciseInsight(maxWords: 10))
                        .font(.caption)
                        .foregroundStyle(Color.zzzyncMuted)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.zzzyncSurface2)
                                .frame(height: 6)
                            Capsule()
                                .fill(Color.zzzyncAccent)
                                .frame(
                                    width: geo.size.width * CGFloat(cause.impactScore) / 100.0,
                                    height: 6
                                )
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.vertical, 12)

                if index < min(causes.count, 4) - 1 {
                    Divider().background(Color.zzzyncSurface2)
                }
            }
        }
        .padding(.horizontal, 14)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func actionsCard(_ actions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Do Next")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            ForEach(Array(actions.prefix(3).enumerated()), id: \.offset) { idx, action in
                HStack(spacing: 10) {
                    Text("\(idx + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.zzzyncOnPrimary)
                        .frame(width: 18, height: 18)
                        .background(Color.zzzyncPrimary)
                        .clipShape(Circle())
                    Text(action.conciseInsight(maxWords: 7))
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
    }
}
