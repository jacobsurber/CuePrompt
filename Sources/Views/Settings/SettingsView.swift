import SwiftUI

/// Tabbed settings window.
struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        TabView {
            AppearanceSettingsView(settings: $appState.settings)
                .tabItem { Label("Appearance", systemImage: "paintbrush") }

            BehaviorSettingsView(settings: $appState.settings)
                .tabItem { Label("Behavior", systemImage: "gearshape") }

            SpeechSettingsView(
                settings: $appState.settings,
                modelManager: appState.modelManager
            )
                .tabItem { Label("Speech", systemImage: "mic") }
        }
        .frame(minWidth: 450, minHeight: 300)
        .onChange(of: appState.settings) { _, _ in
            appState.saveSettings()
        }
    }
}
