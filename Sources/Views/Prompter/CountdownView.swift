import SwiftUI

/// 3-2-1 countdown displayed in the pill before prompting begins.
/// Fills the panel frame (notch-sized) to match the collapsed pill shape.
struct CountdownView: View {
    let remaining: Int

    var body: some View {
        HStack(spacing: 0) {
            // Left extension: countdown number in the visible button area
            Text("\(remaining)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: ScreenDetector.buttonExtension)

            // Right portion: overlaps the notch, effectively invisible
            Color.black
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 8,
                bottomTrailingRadius: 8,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
        .transition(.opacity)
    }
}
