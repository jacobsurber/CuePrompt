import Foundation

/// Protocol for speech recognition providers.
///
/// Providers are NOT @Observable — the SpeechCoordinator handles observation.
/// Each provider outputs recognized words via an AsyncStream.
protocol SpeechProvider: AnyObject, Sendable {
    /// Human-readable name for this provider.
    var name: String { get }

    /// Whether the provider is currently listening.
    var isListening: Bool { get }

    /// Start listening and return a stream of recognized words.
    func startListening() async throws -> AsyncStream<[RecognizedWord]>

    /// Stop listening. Closes the stream.
    func stopListening() async
}
