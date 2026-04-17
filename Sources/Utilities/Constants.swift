import Foundation

enum AppConstants {
    static let appName = "CuePrompt"
    static let bundleId = "com.cueprompt.app"
    static let websocketPort: UInt16 = 19876

    // Panel level (above all windows, excluded from screen share)
    static let panelLevel = 25 // NSWindow.Level.floating + some

    // Animation durations (seconds)
    static let fadeInDuration: TimeInterval = 0.2
    static let fadeOutDuration: TimeInterval = 0.2
    static let expandDuration: TimeInterval = 0.4
    static let collapseDuration: TimeInterval = 0.35

    // MARK: - Formatting

    static func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
