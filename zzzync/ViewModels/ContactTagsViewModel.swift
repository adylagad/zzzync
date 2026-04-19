import Foundation
import Observation

@Observable
final class ContactTagsViewModel {
    var tags: [ContactTag] = []
    var latestSignals: [EmailStressSignal] = []
    var isLoading = false
    var error: String?

    func load() {
        if HackathonDemoScenario.isEnabled {
            HackathonDemoScenario.installFixedDataIfNeeded(force: false)
        }
        tags = LocalStore.shared.loadContactTags()
        if HackathonDemoScenario.isEnabled {
            latestSignals = LocalStore.shared.loadEmailStressSignals()
        } else {
            Task { await refresh() }
        }
    }

    func refresh() async {
        if HackathonDemoScenario.isEnabled {
            await MainActor.run {
                self.tags = LocalStore.shared.loadContactTags().sorted { $0.email < $1.email }
                self.latestSignals = LocalStore.shared.loadEmailStressSignals()
                self.isLoading = false
                self.error = nil
            }
            return
        }

        await MainActor.run {
            isLoading = true
            error = nil
        }
        do {
            let remote = try await SupabaseService.shared.fetchContactTags()
            LocalStore.shared.saveContactTags(remote)
            let signals = try await SupabaseService.shared.fetchEmailStressSignals(days: 7)
            LocalStore.shared.saveEmailStressSignals(signals)
            await MainActor.run {
                tags = remote.sorted { $0.email < $1.email }
                latestSignals = signals
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func add(email: String, priority: ContactPriority) async {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard isValidEmail(normalized) else {
            await MainActor.run { error = "Use a valid email." }
            return
        }

        if HackathonDemoScenario.isEnabled {
            await MainActor.run {
                var current = LocalStore.shared.loadContactTags()
                if let idx = current.firstIndex(where: { $0.email == normalized }) {
                    current[idx] = ContactTag(id: current[idx].id, email: normalized, priority: priority, createdAt: current[idx].createdAt, updatedAt: Date())
                } else {
                    current.append(ContactTag(email: normalized, priority: priority, createdAt: Date(), updatedAt: Date()))
                }
                LocalStore.shared.saveContactTags(current)
                tags = current.sorted { $0.email < $1.email }
                error = nil
                isLoading = false
            }
            return
        }

        await MainActor.run {
            isLoading = true
            error = nil
        }
        do {
            try await SupabaseService.shared.upsertContactTag(email: normalized, priority: priority)
            await refresh()
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func remove(_ tag: ContactTag) async {
        if HackathonDemoScenario.isEnabled {
            await MainActor.run {
                let current = LocalStore.shared.loadContactTags().filter { $0.id != tag.id }
                LocalStore.shared.saveContactTags(current)
                tags = current.sorted { $0.email < $1.email }
                error = nil
                isLoading = false
            }
            return
        }

        await MainActor.run {
            isLoading = true
            error = nil
        }
        do {
            try await SupabaseService.shared.deleteContactTag(id: tag.id)
            await refresh()
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func syncSignals(provider: EmailProvider, accessToken: String) async {
        if HackathonDemoScenario.isEnabled {
            await MainActor.run {
                latestSignals = LocalStore.shared.loadEmailStressSignals()
                error = "Demo mode: fixed hackathon signals loaded."
                isLoading = false
            }
            return
        }

        await MainActor.run {
            isLoading = true
            error = nil
        }
        do {
            let signals = try await SupabaseService.shared.syncEmailStressSignals(
                provider: provider,
                accessToken: accessToken,
                days: 7
            )
            LocalStore.shared.saveEmailStressSignals(signals)
            await MainActor.run {
                latestSignals = signals
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func isValidEmail(_ value: String) -> Bool {
        guard value.count >= 5 else { return false }
        return value.contains("@") && value.contains(".")
    }
}
