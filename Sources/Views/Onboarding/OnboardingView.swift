import SwiftUI
import AVFoundation

/// Onboarding flow: welcome -> mic permission -> model download.
struct OnboardingView: View {
    @Bindable var appState: AppState
    @Binding var isComplete: Bool

    @State private var step: OnboardingStep = .welcome

    enum OnboardingStep {
        case welcome
        case micPermission
        case modelDownload
    }

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .welcome:
                WelcomeStepView {
                    step = .micPermission
                }

            case .micPermission:
                MicPermissionStepView {
                    step = .modelDownload
                }

            case .modelDownload:
                ModelDownloadStepView(modelManager: appState.modelManager) {
                    isComplete = true
                }
            }
        }
        .frame(width: 480, height: 360)
    }
}

// MARK: - Welcome

private struct WelcomeStepView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "text.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Welcome to CuePrompt")
                .font(.title.bold())

            Text("A smart teleprompter that follows your voice.\nSpeak naturally — it keeps up.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Get Started", action: onContinue)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(32)
    }
}

// MARK: - Mic Permission

private struct MicPermissionStepView: View {
    let onContinue: () -> Void

    @State private var permissionGranted = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "mic.circle")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Microphone Access")
                .font(.title2.bold())

            Text("CuePrompt listens to your voice to track where you are in the script. Audio is processed on-device — nothing is sent to the cloud.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()

            if permissionGranted {
                Label("Permission granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            HStack(spacing: 12) {
                if !permissionGranted {
                    Button("Grant Access") {
                        AVCaptureDevice.requestAccess(for: .audio) { granted in
                            Task { @MainActor in
                                permissionGranted = granted
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                if permissionGranted {
                    Button("Continue", action: onContinue)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                } else {
                    Button("Skip for Now", action: onContinue)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
            }
        }
        .padding(32)
        .onAppear {
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            permissionGranted = (status == .authorized)
        }
    }
}

// MARK: - Model Download

private struct ModelDownloadStepView: View {
    var modelManager: ModelManager
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.down.circle")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Speech Model")
                .font(.title2.bold())

            Text("CuePrompt uses a local AI model for speech recognition. Download one now, or use Apple's built-in speech recognition.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            modelStatusView

            Spacer()

            HStack(spacing: 12) {
                if case .notDownloaded = modelManager.state {
                    Button("Download Model") {
                        Task { await modelManager.downloadModel() }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                if modelReady {
                    Button("Continue", action: onComplete)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                } else {
                    Button("Skip (Use Apple Speech)", action: onComplete)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
            }
        }
        .padding(32)
    }

    @ViewBuilder
    private var modelStatusView: some View {
        switch modelManager.state {
        case .notDownloaded:
            EmptyView()
        case .downloading(let progress):
            VStack(spacing: 4) {
                ProgressView(value: progress)
                    .frame(width: 200)
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .downloaded, .ready:
            Label("Model ready", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .loading:
            ProgressView("Loading...")
        case .error(let msg):
            Text(msg)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private var modelReady: Bool {
        if case .downloaded = modelManager.state { return true }
        if case .ready = modelManager.state { return true }
        return false
    }
}
