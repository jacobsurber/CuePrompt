import SwiftUI

/// Settings for prompter behavior.
struct BehaviorSettingsView: View {
    @Binding var settings: AppSettings

    var body: some View {
        Form {
            Section("Countdown") {
                Stepper("Countdown: \(settings.countdownDuration)s",
                        value: $settings.countdownDuration, in: 0...10)
            }

            Section("Presentation") {
                Toggle("Auto-expand on start", isOn: $settings.autoExpandOnStart)
                Toggle("Collapse on finish", isOn: $settings.collapseOnFinish)

                if settings.collapseOnFinish {
                    HStack {
                        Text("Finish fade delay")
                        Spacer()
                        Slider(value: $settings.finishFadeDelay, in: 1...10, step: 0.5)
                            .frame(width: 200)
                        Text(String(format: "%.1fs", settings.finishFadeDelay))
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
