import SwiftUI

struct ContactTagsView: View {
    @State private var vm = ContactTagsViewModel()
    @State private var email = ""
    @State private var priority: ContactPriority = .high
    @State private var gmailToken = ""
    @State private var outlookToken = ""

    var body: some View {
        ZStack {
            Color.zzzyncBackground.ignoresSafeArea()

            VStack(spacing: 12) {
                addCard
                syncCard

                if vm.tags.isEmpty {
                    Text("No tags yet.")
                        .font(.subheadline)
                        .foregroundStyle(Color.zzzyncMuted)
                        .padding(.top, 16)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(vm.tags.enumerated()), id: \.element.id) { index, tag in
                                tagRow(tag)
                                if index < vm.tags.count - 1 {
                                    Divider().background(Color.zzzyncSurface2).padding(.leading, 44)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.zzzyncSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }

                if vm.isLoading {
                    ProgressView().tint(Color.zzzyncPrimary)
                }

                if !vm.latestSignals.isEmpty {
                    Text("\(vm.latestSignals.count) signals ready.")
                        .font(.caption)
                        .foregroundStyle(Color.zzzyncGreen)
                }

                if let error = vm.error, !error.isEmpty {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.zzzyncRed)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .navigationTitle("Sender Tags")
        .onAppear { vm.load() }
    }

    private var syncCard: some View {
        VStack(spacing: 10) {
            TextField("Gmail token", text: $gmailToken)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color.zzzyncSurface2)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button {
                let token = gmailToken.trimmingCharacters(in: .whitespacesAndNewlines)
                Task { await vm.syncSignals(provider: .gmail, accessToken: token) }
            } label: {
                Text("Sync Gmail")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.zzzyncBlue)
                    .foregroundStyle(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(gmailToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading)

            TextField("Outlook token", text: $outlookToken)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color.zzzyncSurface2)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button {
                let token = outlookToken.trimmingCharacters(in: .whitespacesAndNewlines)
                Task { await vm.syncSignals(provider: .outlook, accessToken: token) }
            } label: {
                Text("Sync Outlook")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.zzzyncBlue)
                    .foregroundStyle(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(outlookToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading)

            Text("Tokens are used for one sync only.")
                .font(.caption2)
                .foregroundStyle(Color.zzzyncMuted)
        }
        .padding(14)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var addCard: some View {
        VStack(spacing: 10) {
            HStack {
                TextField("name@company.com", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color.zzzyncSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Picker("Priority", selection: $priority) {
                    ForEach(ContactPriority.allCases, id: \.self) { value in
                        Text(value.label).tag(value)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }

            Button {
                let targetEmail = email
                email = ""
                Task { await vm.add(email: targetEmail, priority: priority) }
            } label: {
                Text("Add")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.zzzyncPrimary)
                    .foregroundStyle(Color.zzzyncOnPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading)
        }
        .padding(14)
        .background(Color.zzzyncSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func tagRow(_ tag: ContactTag) -> some View {
        let color: Color = tag.priority == .high ? .zzzyncRed : .zzzyncAccent
        return HStack(spacing: 12) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(tag.email)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer()
            Text(tag.priority.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            Button(role: .destructive) {
                Task { await vm.remove(tag) }
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Color.zzzyncMuted)
            }
            .buttonStyle(.plain)
            .disabled(vm.isLoading)
        }
        .padding(.vertical, 10)
    }
}
