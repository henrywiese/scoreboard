import SwiftUI

struct ContentView: View {
    @State private var blueScore = 0
    @State private var redScore = 0
    /// Whether blue is on the left (sideways) or top (upright).
    @State private var blueFirst = true
    @State private var clock = GameClock()

    var body: some View {
        GeometryReader { geo in
            // Sideways: side by side with the tab (play/pause, timer, menu) on the top edge.
            // Upright: one above the other with just the menu tab on the left edge.
            let upright = geo.size.height > geo.size.width
            ZStack(alignment: upright ? .leading : .top) {
                let layout = upright ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
                layout {
                    ForEach(blueFirst ? [Team.blue, .red] : [.red, .blue], id: \.self) { team in
                        ScoreSide(score: team == .blue ? $blueScore : $redScore, color: team.color)
                    }
                }
                .ignoresSafeArea()

                if upright {
                    menu
                        .frame(width: 36, height: 64)
                        .background { tabBackground(upright: true) }
                        // Line the tab up with the dividing line, which sits at the full screen's middle.
                        .offset(y: (geo.safeAreaInsets.bottom - geo.safeAreaInsets.top) / 2)
                } else {
                    HStack(spacing: 0) {
                        Button {
                            clock.toggle()
                        } label: {
                            Image(systemName: clock.isRunning ? "pause.fill" : "play.fill")
                                .font(.body.weight(.semibold))
                                .frame(width: 44, height: 36)
                        }
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Text(GameClock.format(clock.elapsed(at: context.date)))
                                .font(.headline.monospacedDigit())
                        }
                        menu
                            .frame(width: 44, height: 36)
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 4)
                    .background { tabBackground(upright: false) }
                }
            }
            // Swap layouts instantly on rotation so the whole screen turns as one,
            // instead of each half and the tab sliding separately to their new spots.
            .transaction(value: upright) { $0.animation = nil }
        }
    }

    private var menu: some View {
        Menu {
            Button {
                blueScore = 0
                redScore = 0
                clock.reset()
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// A tab attached to the screen edge: rounded on the inner side, square where it meets the edge.
    /// Dark frosted glass so the white controls stand out.
    private func tabBackground(upright: Bool) -> some View {
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

/// A count-up game timer. Starts running as soon as it's created.
struct GameClock {
    /// Time banked from earlier running stretches.
    private var banked: TimeInterval = 0
    /// When the current running stretch began; nil while paused.
    private var runningSince: Date? = .now

    var isRunning: Bool { runningSince != nil }

    func elapsed(at date: Date) -> TimeInterval {
        banked + (runningSince.map { date.timeIntervalSince($0) } ?? 0)
    }

    mutating func toggle() {
        if let start = runningSince {
            banked += Date.now.timeIntervalSince(start)
            runningSince = nil
        } else {
            runningSince = .now
        }
    }

    /// Back to 0:00, keeping whether it's running or paused.
    mutating func reset() {
        banked = 0
        if isRunning { runningSince = .now }
    }

    /// mm:ss, or h:mm:ss once past an hour.
    static func format(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600, m = total / 60 % 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
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
