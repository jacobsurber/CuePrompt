import SwiftUI

@main
struct CuePromptApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            RootView(
                appState: appState,
                hasCompletedOnboarding: $hasCompletedOnboarding
            )
            .onAppear {
                // Wire the appState into the AppDelegate for menubar access
                appDelegate.appState = appState
            }
        }
        .defaultSize(width: 800, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Prompter") {
                Button("Present") {
                    appState.startPresenting()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(appState.currentContent == nil)

                Button("Stop Presenting") {
                    appState.stopPresenting()
                }
                .keyboardShortcut(.escape, modifiers: .command)
                .disabled(!appState.prompterState.isActive)

                Divider()

                Button(appState.prompterState.mode == .paused ? "Resume" : "Pause") {
                    appState.togglePause()
                }
                .keyboardShortcut("p", modifiers: .command)
                .disabled(!appState.prompterState.isActive)

                Button(appState.prompterState.mode == .expanded ? "Collapse" : "Expand") {
                    appState.toggleExpandCollapse()
                }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(!appState.prompterState.isActive)
            }

            CommandMenu("Text") {
                Button("Increase Font Size") {
                    appState.settings.fontSize = min(72, appState.settings.fontSize + 2)
                    appState.saveSettings()
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Decrease Font Size") {
                    appState.settings.fontSize = max(14, appState.settings.fontSize - 2)
                    appState.saveSettings()
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Reset Font Size") {
                    appState.settings.fontSize = 28
                    appState.saveSettings()
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }

        Settings {
            SettingsView(appState: appState)
        }
    }
}

/// Root view that handles onboarding vs main app state.
private struct RootView: View {
    @Bindable var appState: AppState
    @Binding var hasCompletedOnboarding: Bool
    @State private var didSetup = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                HomeView(appState: appState)
            } else {
                OnboardingView(appState: appState, isComplete: $hasCompletedOnboarding)
            }
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            if completed && !didSetup {
                performSetup()
            }
        }
        .onAppear {
            if hasCompletedOnboarding && !didSetup {
                performSetup()
            }
        }
    }

    private func performSetup() {
        appState.setup()
        appState.windowManager.setContentView(
            PrompterContentView(appState: appState)
        )
        didSetup = true

        // --simulate flag: auto-load test text and start simulated speech
        if CommandLine.arguments.contains("--simulate") {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000) // let window settle
                let testText = """
                Welcome to CuePrompt, the intelligent teleprompter application. \
                This is a test of the scrolling and highlight system. \
                The words should advance automatically at a steady pace. \
                As each word is spoken, the highlight should move forward \
                and the text should scroll smoothly to keep the current word visible. \
                If you are reading this, the simulation mode is working correctly. \
                The quick brown fox jumps over the lazy dog near the river bank. \
                We need enough text here to require scrolling past the first screen. \
                Technology continues to reshape how we communicate and collaborate. \
                Remote teams rely on tools like this to deliver presentations effectively. \
                The sun sets behind the mountains casting long shadows across the valley. \
                Engineers build bridges between ideas and implementation every single day. \
                Music fills the room as the orchestra performs the final movement. \
                Data flows through pipelines transforming raw numbers into actionable insights. \
                The garden grows wild with roses and lilies blooming in every direction. \
                Stars appear one by one as twilight fades into the deep night sky.
                """
                appState.loadText(testText)
                appState.startSimulatedPresenting()
            }
        }
    }
}
