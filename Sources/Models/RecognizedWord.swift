import Foundation

/// A recognized word with timing and confidence metadata from a speech provider.
struct RecognizedWord: Sendable {
    let text: String
    let timestamp: TimeInterval
    let confidence: Float
}
