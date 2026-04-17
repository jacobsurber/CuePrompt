import SwiftUI

/// Root view for the prompter panel — switches between pill, countdown, and expanded.
struct PrompterContentView: View {
    @Bindable var appState: AppState

    var body: some View {
        Group {
            switch appState.prompterState.mode {
            case .idle:
                EmptyView()

            case .countdown(let remaining):
                CountdownView(remaining: remaining)

            case .collapsed:
                VStack(spacing: 4) {
                    PillView(
                        slideIndex: appState.engine.currentSlideIndex,
                        totalSlides: appState.prompterState.totalSlides,
                        progress: appState.engine.progress,
                        isListening: appState.speechCoordinator.isListening
                            && !appState.wasPausedBeforeCollapse,
                        wordsHeard: appState.speechCoordinator.wordCount,
                        onTap: { appState.toggleExpandCollapse() }
                    )
                    if let error = appState.speechCoordinator.error {
                        Text(error)
                            .font(.system(size: 10))
                            .foregroundStyle(CueColors.warning)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.8), in: Capsule())
                    }
                }

            case .expanded, .paused:
                PrompterOverlayView(
                    sections: appState.scriptSections,
                    scrollPosition: appState.engine.scrollPosition,
                    totalWords: appState.engine.totalWords,
                    settings: appState.settings,
                    slideIndex: appState.engine.currentSlideIndex,
                    totalSlides: appState.prompterState.totalSlides,
                    elapsedTime: appState.prompterState.elapsedTime,
                    isListening: appState.speechCoordinator.isListening
                        && appState.prompterState.mode != .paused,
                    isPaused: appState.prompterState.mode == .paused,
                    wordsHeard: appState.speechCoordinator.wordCount,
                    lastHeardWords: appState.speechCoordinator.lastHeardWords,
                    speechError: appState.speechCoordinator.error,
                    onCollapse: { appState.toggleExpandCollapse() },
                    onTogglePause: { appState.togglePause() }
                )

            case .finished:
                PillView(
                    slideIndex: appState.prompterState.totalSlides - 1,
                    totalSlides: appState.prompterState.totalSlides,
                    progress: 1.0,
                    isListening: false,
                    wordsHeard: appState.speechCoordinator.wordCount,
                    onTap: {}
                )
            }
        }
    }
}
