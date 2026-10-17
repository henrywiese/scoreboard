import SwiftUI

struct ContentView: View {
    @State private var blueScore = 0
    @State private var redScore = 0

    var body: some View {
        HStack(spacing: 0) {
            ScoreSide(score: $blueScore, color: .blue)
            ScoreSide(score: $redScore, color: .red)
        }
        .ignoresSafeArea()
    }
}

/// One half of the scoreboard. Tap or swipe up adds a point, swipe down removes one.
struct ScoreSide: View {
    @Binding var score: Int
    let color: Color

    /// Vertical drag distance (in points) needed for a gesture to count as a swipe rather than a tap.
    private let swipeThreshold: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            ZStack {
                color
                Text("\(score)")
                    .font(.system(size: min(geo.size.width, geo.size.height) * 0.5, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .padding()
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        if abs(dx) > swipeThreshold && abs(dx) > abs(dy) {
                            return // Sideways swipe: ignore.
                        } else if dy > swipeThreshold {
                            score = max(0, score - 1)
                        } else {
                            // Swipe up, or a tap (little to no movement).
                            score += 1
                        }
                    }
            )
        }
    }
}

#Preview {
    ContentView()
}
