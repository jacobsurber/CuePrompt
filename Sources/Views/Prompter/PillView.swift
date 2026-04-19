import SwiftUI

/// The collapsed pill: camouflages with the notch on the right,
/// with a visible expand button extending to the left.
struct PillView: View {
    let slideIndex: Int
    let totalSlides: Int
    let progress: Double
    let isListening: Bool
    let wordsHeard: Int
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Left extension: visible expand button beside the notch
                expandButton
                    .frame(width: ScreenDetector.buttonExtension)

                // Right portion: overlaps the notch, effectively invisible
                Color.black
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .buttonStyle(.plain)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 8,
                bottomTrailingRadius: 8,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: CueDuration.micro)) {
                isHovering = hovering
            }
        }
    }

    private var expandButton: some View {
        ZStack {
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(isHovering ? 0.8 : 0.3))

            VStack {
                Spacer()
                Circle()
                    .fill(isListening ? CueColors.micActive : Color.clear)
                    .frame(width: 5, height: 5)
                    .padding(.bottom, 4)
            }
        }
    }
}
