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
            .navigationTitle("Metabolic Audit")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLogEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.zzzyncPrimary)
                    }
                }
            }
            .sheet(isPresented: $showLogEntry) {
                FoodLogEntryView()
                    .onDisappear { vm.load() }
            }
        }
        .onAppear { vm.load() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundStyle(Color.zzzyncMuted)
            Text("No food logs yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            Text("Log a meal to see how your eating timing aligns with your biological clock.")
                .font(.subheadline)
                .foregroundStyle(Color.zzzyncMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showLogEntry = true
            } label: {
                Label("Log Your First Meal", systemImage: "plus")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.zzzyncPrimary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    private var logList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if vm.isLoggingFood {
                    LoadingCardView(message: "Auditing meal timing with Claude...")
                        .padding(.horizontal)
                }

                if let error = vm.error {
                    InsightBubble(text: error, icon: "exclamationmark.triangle.fill")
                        .padding(.horizontal)
                }

                ForEach(vm.foodLogs) { log in
                    MealCorrelationCard(log: log)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}
