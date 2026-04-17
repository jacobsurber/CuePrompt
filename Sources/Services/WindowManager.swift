import AppKit
import SwiftUI

/// Manages the NSPanel that hosts the pill and expanded prompter.
///
/// The panel animates between pill (collapsed) and expanded states,
/// is excluded from screen sharing, and anchors at the camera notch.
/// Expand/collapse animations grow FROM the pill position (top-center)
/// so the panel appears to unfurl downward from the notch.
@Observable
final class WindowManager {
    private var panel: NSPanel?
    private var isPillMode: Bool = true
    private var keyMonitor: Any?

    private(set) var isVisible: Bool = false

    // Callbacks for key events (wired by AppState)
    var onSpacePressed: (() -> Void)?
    var onArrowUp: (() -> Void)?
    var onArrowDown: (() -> Void)?

    // MARK: - Panel Lifecycle

    func setupPanel() {
        // Start at the notch frame so there's no position flash on first show
        let initialFrame = ScreenDetector.notchFrame(for: ScreenDetector.cameraScreen)
        let panel = NSPanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(rawValue: AppConstants.panelLevel)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.sharingType = .none
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false

        self.panel = panel
    }

    // MARK: - Show / Hide

    func showPill(settings: AppSettings) {
        guard let panel else { return }
        isPillMode = true
        let screen = ScreenDetector.screen(forDisplayID: settings.targetDisplayID)
        // Start at exact notch frame — camouflaged, invisible against the notch
        let notch = ScreenDetector.notchFrame(for: screen)
        panel.setFrame(notch, display: true)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        isVisible = true
        installKeyMonitor()

        // Fade in
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = AppConstants.fadeInDuration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        guard let panel else { return }
        removeKeyMonitor()
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = AppConstants.fadeOutDuration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.isVisible = false
        })
    }

    // MARK: - Expand / Collapse

    /// Expand from notch to full panel. Smooth animation growing outward from notch origin.
    func expand(settings: AppSettings) {
        guard let panel else { return }
        isPillMode = false

        let screen = ScreenDetector.screen(forDisplayID: settings.targetDisplayID)
        let target = ScreenDetector.expandedFrame(
            for: screen,
            width: settings.expandedWidth,
            height: settings.expandedHeight
        )

        // Smooth expansion: both width and height grow from the notch center-top
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = AppConstants.expandDuration
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            panel.animator().setFrame(target, display: true)
        }
    }

    /// Collapse back into the notch. Shrinks to match notch size and position.
    func collapse(settings: AppSettings) {
        guard let panel else { return }
        isPillMode = true

        let screen = ScreenDetector.screen(forDisplayID: settings.targetDisplayID)
        let target = ScreenDetector.notchFrame(for: screen)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = AppConstants.collapseDuration
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
            panel.animator().setFrame(target, display: true)
        }
    }

    // MARK: - Content

    func setContentView<V: View>(_ view: V) {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = panel?.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        panel?.contentView = hostingView
    }

    // MARK: - Key Monitor

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isVisible else { return event }
            switch event.keyCode {
            case 49: // Space
                self.onSpacePressed?()
                return nil
            case 126: // Up arrow
                self.onArrowUp?()
                return nil
            case 125: // Down arrow
                self.onArrowDown?()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

}
