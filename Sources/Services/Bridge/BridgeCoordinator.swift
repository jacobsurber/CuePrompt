import Foundation

/// Coordinates the WebSocket bridge to the Chrome extension.
///
/// Manages connection state, parses incoming messages, and converts
/// them into Presentation objects for the engine.
@Observable
final class BridgeCoordinator {

    enum ConnectionState: Equatable {
        case disconnected
        case listening
        case connected
        case error(String)
    }

    private(set) var state: ConnectionState = .disconnected
    private(set) var currentPresentation: Presentation?
    private(set) var currentSlideIndex: Int = 0

    /// Called when a full sync or slide update is received.
    var onPresentationUpdate: ((Presentation) -> Void)?
    var onSlideChange: ((Int) -> Void)?

    private let server = WebSocketServer()

    func startListening() {
        do {
            try server.start { [weak self] data in
                self?.handleMessage(data)
            }
            state = .listening
        } catch {
            state = .error("Failed to start server: \(error.localizedDescription)")
        }
    }

    func stopListening() {
        server.stop()
        state = .disconnected
        currentPresentation = nil
    }

    private func handleMessage(_ data: Data) {
        do {
            let message = try JSONDecoder().decode(BridgeMessage.self, from: data)

            Task { @MainActor in
                switch message {
                case .fullSync(let sync):
                    self.handleFullSync(sync)
                case .slideUpdate(let update):
                    self.handleSlideUpdate(update)
                case .disconnect:
                    self.state = .disconnected
                    self.currentPresentation = nil
                }
            }
        } catch {
            print("[Bridge] Failed to decode message: \(error)")
        }
    }

    private func handleFullSync(_ sync: FullSyncMessage) {
        state = .connected

        let slides = sync.slides.map { syncSlide in
            Slide(
                slideIndex: syncSlide.slideIndex,
                speakerNotes: syncSlide.speakerNotes,
                slideTitle: syncSlide.slideTitle,
                thumbnailPath: nil // Thumbnails from the extension are not persisted (not yet needed)
            )
        }

        let presentation = Presentation(
            slides: slides,
            title: nil,
            source: .chromeExtension
        )

        currentPresentation = presentation
        currentSlideIndex = 0
        onPresentationUpdate?(presentation)
    }

    private func handleSlideUpdate(_ update: SlideUpdateMessage) {
        state = .connected
        currentSlideIndex = update.slideIndex

        // Update the slide in the current presentation
        if var pres = currentPresentation,
           update.slideIndex < pres.slides.count {
            pres.slides[update.slideIndex].speakerNotes = update.speakerNotes
            pres.slides[update.slideIndex].slideTitle = update.slideTitle
            currentPresentation = pres
        }

        onSlideChange?(update.slideIndex)
    }
}
