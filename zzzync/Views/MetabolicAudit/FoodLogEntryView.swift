import SwiftUI
import PhotosUI

struct FoodLogEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = MetabolicViewModel()
    @State private var textInput = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zzzyncBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Photo picker
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.zzzyncSurface)
                                    .frame(height: 180)

                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                } else {
                                    VStack(spacing: 10) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(Color.zzzyncMuted)
                                        Text("Add photo")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.zzzyncMuted)
                                    }
                                }
                            }
                        }
                        .onChange(of: selectedPhoto) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    selectedImage = image
                                }
                            }
                        }

                        // Text description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meal notes")
                                .font(.subheadline)
                                .foregroundStyle(Color.zzzyncMuted)
                            TextField("e.g. Chicken salad with olive oil dressing", text: $textInput, axis: .vertical)
                                .lineLimit(3...5)
                                .padding(12)
                                .background(Color.zzzyncSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }

                        // Analyze button
                        Button {
                            Task { await analyzeFood() }
                        } label: {
                            Label("Analyze", systemImage: "sparkles")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.zzzyncPrimary)
                                .foregroundStyle(Color.zzzyncOnPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isAnalyzing || (textInput.isEmpty && selectedImage == nil))

                        if isAnalyzing {
                            LoadingCardView(message: "Analyzing...")
                        }

                        if let error = analysisError {
                            InsightBubble(text: error, icon: "exclamationmark.triangle.fill")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.zzzyncMuted)
                }
            }
        }
    }

    private func analyzeFood() async {
        isAnalyzing = true
        analysisError = nil
        do {
            if let image = selectedImage {
                _ = try await FoodLogService.shared.logFood(
                    image: image,
                    textDescription: textInput
                )
            } else {
                _ = try await FoodLogService.shared.logFoodByText(textInput)
            }
            dismiss()
        } catch {
            analysisError = error.localizedDescription
        }
        isAnalyzing = false
    }
}
