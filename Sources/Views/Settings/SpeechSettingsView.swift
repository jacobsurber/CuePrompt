import SwiftUI

/// Settings for speech recognition provider and model selection.
struct SpeechSettingsView: View {
    @Binding var settings: AppSettings
    var modelManager: ModelManager

    var body: some View {
        Form {
            Section("Speech Provider") {
                Picker("Provider", selection: $settings.preferredProvider) {
                    Text("WhisperKit").tag("WhisperKit")
                    Text("Apple Speech").tag("Apple Speech")
                }
                .pickerStyle(.segmented)

                if settings.preferredProvider == "WhisperKit" {
                    modelSection
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    @ViewBuilder
    private var modelSection: some View {
        switch modelManager.state {
        case .notDownloaded:
            VStack(alignment: .leading, spacing: 8) {
                Text("No local model found")
                    .foregroundStyle(.secondary)
                Button("Download \(settings.preferredModel)") {
                    modelManager.preferredModel = settings.preferredModel
                    Task { await modelManager.downloadModel() }
                }
            }

        case .downloading(let progress):
            VStack(alignment: .leading, spacing: 4) {
                Text("Downloading model...")
                ProgressView(value: progress)
            }

        case .downloaded:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(CueColors.micActive)
                Text("Model downloaded: \(settings.preferredModel)")
                    .foregroundStyle(.secondary)
            }

        case .loading:
            ProgressView("Loading model...")

        case .ready:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(CueColors.micActive)
                Text("Model ready")
            }

        case .error(let msg):
            VStack(alignment: .leading, spacing: 4) {
                Text(msg)
                    .foregroundStyle(CueColors.error)
                Button("Retry") {
                    modelManager.scanLocalModels()
                }
            }
        }
    }
}
