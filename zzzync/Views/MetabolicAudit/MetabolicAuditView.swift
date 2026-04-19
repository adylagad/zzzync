import SwiftUI

struct MetabolicAuditView: View {
    @State private var vm = MetabolicViewModel()
    @State private var showLogEntry = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zzzyncBackground.ignoresSafeArea()

                Group {
                    if vm.foodLogs.isEmpty && !vm.isLoggingFood {
                        emptyState
                    } else {
                        logList
                    }
                }
            }
            .navigationTitle("Meals")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.zzzyncBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showLogEntry = true } label: {
                        ZStack {
                            Circle()
                                .fill(Color.zzzyncGreen.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.zzzyncGreen)
                        }
                    }
                }
            }
            .sheet(isPresented: $showLogEntry) {
                FoodLogEntryView()
                    .presentationDetents([.large])
                    .presentationBackground(Color.zzzyncBackground)
                    .onDisappear { vm.load() }
            }
        }
        .onAppear { vm.load() }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Color.zzzyncGreen.opacity(0.10)).frame(width: 90, height: 90)
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.zzzyncGreen)
            }
            VStack(spacing: 8) {
                Text("No meals logged")
                    .font(.title3).fontWeight(.bold).foregroundStyle(.white)
                Text("Add a meal to check timing.")
                    .font(.subheadline).foregroundStyle(Color.zzzyncMuted)
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
            }
            Button { showLogEntry = true } label: {
                Label("Log Meal", systemImage: "plus")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28).padding(.vertical, 13)
                    .background(Color.zzzyncGreen)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    // MARK: - Log list

    private var logList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if vm.isLoggingFood {
                    LoadingCardView(message: "Checking meal timing...")
                        .padding(.horizontal, 20)
                }
                if let error = vm.error {
                    InsightBubble(text: error, icon: "exclamationmark.triangle.fill", color: .zzzyncRed)
                        .padding(.horizontal, 20)
                }
                ForEach(vm.foodLogs) { log in
                    MealCorrelationCard(log: log)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 16)
        }
    }
}
