import SwiftUI
import UIKit

/// Stillfast's look: calm and minimal. One soft accent colour, generous spacing, rounded numerals.
enum Theme {
    /// Soft sage green.
    static let accent = dynamic(light: (0.33, 0.53, 0.44), dark: (0.56, 0.78, 0.67))
    /// A goal that was reached.
    static let success = accent
    /// A fast that ended short of its goal: a muted amber, not an alarming red.
    static let shortfall = dynamic(light: (0.80, 0.58, 0.30), dark: (0.90, 0.70, 0.42))
    /// The empty part of the ring and other quiet fills.
    static let track = Color(UIColor.tertiarySystemFill)

    /// White in light mode, true black in dark mode.
    static let background = Color(UIColor.systemBackground)
    static let card = Color(UIColor.secondarySystemBackground)

    enum Space {
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 36
    }

    static let cornerRadius: CGFloat = 22

    /// Large rounded digits that don't jiggle as they change.
    static func numerals(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    private static func dynamic(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        Color(UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }
}

extension View {
    /// The standard rounded card.
    func card(padding: CGFloat = Theme.Space.m) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

/// A small uppercase label, used above numbers.
struct Eyebrow: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.medium))
            .tracking(1.2)
            .foregroundStyle(.secondary)
    }
}

/// The thin progress ring used across the app.
struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 14
    var color: Color = Theme.accent

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0.0001, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
        }
        .padding(lineWidth / 2)
        .aspectRatio(1, contentMode: .fit)
    }
}
