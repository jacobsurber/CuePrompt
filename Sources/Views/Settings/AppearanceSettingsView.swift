import SwiftUI

/// Settings for text appearance in the prompter.
struct AppearanceSettingsView: View {
    @Binding var settings: AppSettings

    var body: some View {
        Form {
            Section("Text") {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Slider(value: $settings.fontSize, in: 16...64, step: 2) {
                        Text("Font Size")
                    }
                    .frame(width: 200)
                    Text("\(Int(settings.fontSize))pt")
                        .monospacedDigit()
                        .frame(width: 40)
                }

                HStack {
                    Text("Line Spacing")
                    Spacer()
                    Slider(value: $settings.lineSpacing, in: 1.0...2.5, step: 0.1)
                        .frame(width: 200)
                    Text(String(format: "%.1f", settings.lineSpacing))
                        .monospacedDigit()
                        .frame(width: 40)
                }

                HStack {
                    Text("Read Text Opacity")
                    Spacer()
                    Slider(value: $settings.textOpacity, in: 0.1...0.8, step: 0.05)
                        .frame(width: 200)
                    Text(String(format: "%.0f%%", settings.textOpacity * 100))
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }

            Section("Window") {
                HStack {
                    Text("Expanded Width")
                    Spacer()
                    Slider(value: $settings.expandedWidth, in: 400...1200, step: 50)
                        .frame(width: 200)
                    Text("\(Int(settings.expandedWidth))px")
                        .monospacedDigit()
                        .frame(width: 50)
                }

                HStack {
                    Text("Expanded Height")
                    Spacer()
                    Slider(value: $settings.expandedHeight, in: 200...800, step: 50)
                        .frame(width: 200)
                    Text("\(Int(settings.expandedHeight))px")
                        .monospacedDigit()
                        .frame(width: 50)
                }

                Picker("Thumbnail Position", selection: $settings.thumbnailPosition) {
                    ForEach(AppSettings.ThumbnailPosition.allCases, id: \.self) { pos in
                        Text(pos.rawValue.capitalized).tag(pos)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Show Thumbnails", isOn: $settings.showThumbnails)
            }

            Section("Display") {
                Picker("Prompter Screen", selection: $settings.targetDisplayID) {
                    Text("Camera Screen (Auto)")
                        .tag(nil as UInt32?)
                    ForEach(ScreenDetector.allScreens) { screen in
                        HStack {
                            Text(screen.name)
                            if screen.hasCamera {
                                Image(systemName: "camera.fill")
                                    .font(.caption2)
                            }
                        }
                        .tag(screen.id as UInt32?)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
