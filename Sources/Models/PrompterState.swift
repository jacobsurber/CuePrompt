import Foundation

/// The current mode of the prompter.
enum PrompterMode: Equatable, Sendable {
    case idle
    case countdown(remaining: Int)
    case collapsed
    case expanded
    case paused
    case finished
}

/// Observable state for the prompter UI.
@Observable
final class PrompterState {
    var mode: PrompterMode = .idle
    var currentSlideIndex: Int = 0
    var totalSlides: Int = 0
    var elapsedTime: TimeInterval = 0
    var progress: Double = 0

    var isActive: Bool {
        switch mode {
        case .collapsed, .expanded, .paused:
            return true
        default:
            return false
        }
    }

    var isPresenting: Bool {
        switch mode {
        case .collapsed, .expanded:
            return true
        default:
            return false
        }
    }
}
