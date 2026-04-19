import SwiftUI

struct AICausalView: View {
    @State private var vm = AICausalViewModel()

    private let quickPrompts = [
        "Why am I tired?",
        "What should I eat now?",
        "How do I recover in 2 hours?",
        "When should I take caffeine?"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zzzyncBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    signalsStrip
                        .padding(.top, 8)

                    quickPromptsStrip
                        .padding(.top, 10)

                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(vm.messages) { message in
                                    messageBubble(message)
                                        .id(message.id)
                                }

                                if vm.isLoading {
                                    typingBubble
                                }

                                if let error = vm.error, !error.isEmpty {
                                    InsightBubble(
                                        text: error.conciseInsight(maxWords: 20),
                                        icon: "exclamationmark.triangle.fill",
                                        color: .zzzyncRed
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 16)
                        }
                        .onChange(of: vm.messages.count) {
                            if let last = vm.messages.last {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: vm.isLoading) {
                            if vm.isLoading, let last = vm.messages.last {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.zzzyncBackground, for: .navigationBar)
            .safeAreaInset(edge: .bottom) { composerBar }
        }
        .onAppear { vm.load() }
    }

    private var signalsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.signalChips) { chip in
                    HStack(spacing: 6) {
                        Text(chip.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.zzzyncMuted)
                        Text(chip.value)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(chip.color)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.zzzyncSurface)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var quickPromptsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button {
                        Task { await vm.sendQuickPrompt(prompt) }
                    } label: {
                        Text(prompt)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.zzzyncPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.zzzyncPrimary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func messageBubble(_ message: AICausalViewModel.ChatMessage) -> some View {
        HStack {
            if message.role == .assistant {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.zzzyncPrimary)
                    Text(message.text)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                    if let metadata = message.metadata, !metadata.isEmpty {
                        Text(metadata)
                            .font(.caption2)
                            .foregroundStyle(Color.zzzyncMuted)
                    }
                }
                .padding(12)
                .background(Color.zzzyncSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .frame(maxWidth: 300, alignment: .leading)

                Spacer(minLength: 36)
            } else {
                Spacer(minLength: 36)

                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(Color.zzzyncOnPrimary)
                    .padding(12)
                    .background(Color.zzzyncPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .frame(maxWidth: 300, alignment: .trailing)
            }
        }
    }

    private var typingBubble: some View {
        HStack {
            HStack(spacing: 8) {
                ProgressView().tint(Color.zzzyncPrimary).scaleEffect(0.75)
                Text("Thinking…")
                    .font(.caption)
                    .foregroundStyle(Color.zzzyncMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.zzzyncSurface)
            .clipShape(Capsule())
            Spacer(minLength: 36)
        }
    }

    private var composerBar: some View {
        HStack(spacing: 10) {
            TextField("Ask anything...", text: $vm.inputText, axis: .vertical)
                .lineLimit(1...4)
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.zzzyncSurface2)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                Task { await vm.send() }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.zzzyncOnPrimary)
                    .frame(width: 34, height: 34)
                    .background(Color.zzzyncPrimary)
                    .clipShape(Circle())
            }
            .disabled(vm.isLoading || vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(vm.isLoading || vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.zzzyncSurface)
    }
}
