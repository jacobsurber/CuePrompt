import AppKit

/// Custom layout manager that draws word highlights with rounded corners
/// and soft gradient edges instead of hard rectangles.
final class PrompterLayoutManager: NSLayoutManager {

    /// How far the glow extends beyond the character background rect (in points).
    /// Shared with PrompterTextCoordinator for dirty-rect invalidation.
    static let glowExtent: CGFloat = 4.0

    /// The highlight color used by the coordinator — when detected,
    /// draw a soft rounded rect instead of a hard fill.
    static let highlightColor = NSColor.white.withAlphaComponent(0.18)

    override func fillBackgroundRectArray(
        _ rectArray: UnsafePointer<NSRect>,
        count rectCount: Int,
        forCharacterRange charRange: NSRange,
        color: NSColor
    ) {
        // Only customize our highlight color; pass everything else to default
        guard isHighlightColor(color) else {
            super.fillBackgroundRectArray(rectArray, count: rectCount, forCharacterRange: charRange, color: color)
            return
        }

        guard let context = NSGraphicsContext.current?.cgContext else {
            super.fillBackgroundRectArray(rectArray, count: rectCount, forCharacterRange: charRange, color: color)
            return
        }

        for i in 0..<rectCount {
            let rect = rectArray[i]
            guard rect.width > 0, rect.height > 0 else { continue }

            let cornerRadius = min(5.0, rect.height / 2)

            context.saveGState()

            // Draw soft outer glow (larger, faded)
            let glowRect = rect.insetBy(dx: -Self.glowExtent, dy: -Self.glowExtent)
            let glowRadius = min(cornerRadius + 3, glowRect.height / 2)
            let glowPath = CGPath(roundedRect: glowRect, cornerWidth: glowRadius, cornerHeight: glowRadius, transform: nil)
            context.addPath(glowPath)
            context.setFillColor(NSColor.white.withAlphaComponent(0.06).cgColor)
            context.fillPath()

            // Draw main rounded highlight (visually expanded beyond character bounds)
            let mainRect = rect.insetBy(dx: -2, dy: -2)
            let mainRadius = min(cornerRadius, mainRect.height / 2)
            let mainPath = CGPath(roundedRect: mainRect, cornerWidth: mainRadius, cornerHeight: mainRadius, transform: nil)
            context.addPath(mainPath)
            context.setFillColor(color.cgColor)
            context.fillPath()

            context.restoreGState()
        }
    }

    /// Check if a color is close to our highlight color.
    private func isHighlightColor(_ color: NSColor) -> Bool {
        guard let c = color.usingColorSpace(.deviceRGB) else { return false }
        // Our highlight is white (1,1,1) at 0.18 alpha
        return c.redComponent > 0.9 && c.greenComponent > 0.9 && c.blueComponent > 0.9
            && c.alphaComponent > 0.1 && c.alphaComponent < 0.3
    }
}
