import Foundation

enum AppConstants {
    static let appName = "CuePrompt"
    static let bundleId = "com.cueprompt.app"
    static let websocketPort: UInt16 = 19876

    // Panel level (above all windows, excluded from screen share)
    static let panelLevel = 25  // NSWindow.Level.floating + some

    // Animation durations (seconds) — aligned with DESIGN.md
    static let fadeInDuration: TimeInterval = CueDuration.short
    static let fadeOutDuration: TimeInterval = CueDuration.short
    static let expandDuration: TimeInterval = CueDuration.medium
    static let collapseDuration: TimeInterval = CueDuration.medium

    // MARK: - Formatting

    static func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
