import Foundation

/// Codable wrapper for NSRect, avoiding retroactive conformance.
struct CodableRect: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var nsRect: NSRect {
        NSRect(x: x, y: y, width: width, height: height)
    }

    init(_ rect: NSRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}
