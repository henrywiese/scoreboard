import SwiftUI

struct ContentView: View {
    @State private var blueScore = 0
    @State private var redScore = 0
    /// Whether blue is on the left (sideways) or top (upright).
    @State private var blueFirst = true

    var body: some View {
        GeometryReader { geo in
            // Sideways: side by side with the menu tab on the top edge.
            // Upright: one above the other with the tab on the left edge.
            let upright = geo.size.height > geo.size.width
            ZStack(alignment: upright ? .leading : .top) {
                let layout = upright ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
                layout {
                    ForEach(blueFirst ? [Team.blue, .red] : [.red, .blue], id: \.self) { team in
                        ScoreSide(score: team == .blue ? $blueScore : $redScore, color: team.color)
                    }
                }
                .ignoresSafeArea()

                menu(upright: upright)
                    // Line the upright tab up with the dividing line, which sits at the full screen's middle.
                    .offset(y: upright ? (geo.safeAreaInsets.bottom - geo.safeAreaInsets.top) / 2 : 0)
            }
            // Swap layouts instantly on rotation so the whole screen turns as one,
            // instead of each half and the tab sliding separately to their new spots.
            .transaction(value: upright) { $0.animation = nil }
        }
    }

    private func menu(upright: Bool) -> some View {
        Menu {
            Button {
                blueScore = 0
                redScore = 0
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            Button {
                withAnimation { blueFirst.toggle() }
            } label: {
                Label("Switch", systemImage: "arrow.left.arrow.right")
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.white)
                .frame(width: upright ? 36 : 64, height: upright ? 64 : 36)
        }
        .background {
            // A tab attached to the screen edge: rounded on the inner side, square where it meets the edge.
            // Dark frosted glass so the white lines stand out.
            Group {
                if upright {
                    UnevenRoundedRectangle(bottomTrailingRadius: 12, topTrailingRadius: 12)
                        .ignoresSafeArea(edges: .leading)
                } else {
                    UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12)
                        .ignoresSafeArea(edges: .top)
                }
            }
            .foregroundStyle(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
        }
    }
}

enum Team {
    case blue, red

    var color: Color {
        switch self {
        case .blue: .blue
        case .red: .red
        }
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
