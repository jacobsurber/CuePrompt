import AppKit

/// Detects display properties, including notch/camera presence and screen enumeration.
enum ScreenDetector {

    /// Identifies available screens and their properties.
    struct ScreenInfo: Identifiable, Equatable {
        let id: UInt32 // CGDirectDisplayID
        let name: String
        let hasCamera: Bool
        let frame: NSRect

        static func == (lhs: ScreenInfo, rhs: ScreenInfo) -> Bool {
            lhs.id == rhs.id
        }
    }

    /// All connected screens with metadata.
    static var allScreens: [ScreenInfo] {
        NSScreen.screens.compactMap { screen in
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32 else {
                return nil
            }

            let hasCamera: Bool
            if #available(macOS 12.0, *) {
                hasCamera = screen.safeAreaInsets.top > 0
            } else {
                // Built-in display heuristic: it's usually the first screen
                hasCamera = (screen == NSScreen.screens.first)
            }

            return ScreenInfo(
                id: id,
                name: screen.localizedName,
                hasCamera: hasCamera,
                frame: screen.frame
            )
        }
    }

    /// The screen that has the built-in camera (notched display), or main screen as fallback.
    static var cameraScreen: NSScreen {
        if #available(macOS 12.0, *) {
            if let notched = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) {
                return notched
            }
        }
        return NSScreen.main ?? NSScreen.screens.first!
    }

    /// Find a screen by its display ID, falling back to camera screen.
    static func screen(forDisplayID id: UInt32?) -> NSScreen {
        guard let id else { return cameraScreen }
        return NSScreen.screens.first { screen in
            (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32) == id
        } ?? cameraScreen
    }

    /// Whether a given screen has a notch.
    static func hasNotch(_ screen: NSScreen) -> Bool {
        if #available(macOS 12.0, *) {
            return screen.safeAreaInsets.top > 0
        }
        return false
    }

    /// Width of the expand button that extends left of the notch.
    static let buttonExtension: CGFloat = 36

    /// Known notch width for MacBook Pro (~180pt).
    static let notchWidth: CGFloat = 180

    /// Returns a frame matching the physical notch, extended left by
    /// `buttonExtension` for a visible expand/collapse button.
    /// The right portion camouflages with the notch; the left is visible.
    static func notchFrame(for screen: NSScreen) -> NSRect {
        let frame = screen.frame
        let nw = notchWidth
        let bw = buttonExtension
        let totalWidth = nw + bw

        if #available(macOS 12.0, *), screen.safeAreaInsets.top > 0 {
            let nh = screen.safeAreaInsets.top
            // Center the notch portion on screen, extend left for button
            let x = frame.midX - nw / 2 - bw
            let y = frame.maxY - nh
            return NSRect(x: x, y: y, width: totalWidth, height: nh)
        } else {
            let h: CGFloat = 32
            let x = frame.midX - nw / 2 - bw
            let y = frame.maxY - h
            return NSRect(x: x, y: y, width: totalWidth, height: h)
        }
    }

    /// Frame for the expanded prompter panel.
    /// Starts from the very top of the screen so the "ears" flank the notch.
    /// The NotchCutoutShape clips out the notch area.
    static func expandedFrame(for screen: NSScreen, width: CGFloat, height: CGFloat) -> NSRect {
        let frame = screen.frame
        let x = frame.midX - width / 2
        let y = frame.maxY - height
        return NSRect(x: x, y: y, width: width, height: height)
    }
}
