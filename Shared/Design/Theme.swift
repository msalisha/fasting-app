import SwiftUI
import UIKit

/// Stillfast's look: calm and minimal. One soft accent colour, generous spacing, rounded numerals.
enum Theme {
    /// The colour scheme the user picked in Settings (sage green unless changed).
    static var accent: Color { AccentTheme.current.color }
    /// Text and icons drawn on top of the accent colour: white in light mode, black in dark mode,
    /// because the dark-mode accents are light.
    static let onAccent = dynamic(light: (1, 1, 1), dark: (0, 0, 0))
    /// A goal that was reached.
    static var success: Color { accent }
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

    static func dynamic(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        Color(UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }
}

/// The colour schemes offered in Settings. Each has a light-mode and a dark-mode shade.
enum AccentTheme: String, CaseIterable, Identifiable {
    case sage, ocean, lavender, rose, graphite

    /// App Group defaults key, so widgets can follow the same choice.
    static let storageKey = "accentTheme"

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .sage: Theme.dynamic(light: (0.33, 0.53, 0.44), dark: (0.56, 0.78, 0.67))
        case .ocean: Theme.dynamic(light: (0.20, 0.47, 0.66), dark: (0.47, 0.72, 0.90))
        case .lavender: Theme.dynamic(light: (0.48, 0.42, 0.72), dark: (0.71, 0.66, 0.93))
        case .rose: Theme.dynamic(light: (0.74, 0.38, 0.47), dark: (0.93, 0.60, 0.68))
        case .graphite: Theme.dynamic(light: (0.30, 0.32, 0.35), dark: (0.78, 0.80, 0.83))
        }
    }

    static var current: AccentTheme {
        AccentTheme(rawValue: AppGroup.defaults.string(forKey: storageKey) ?? "") ?? .sage
    }
}

/// Light, dark, or whatever the phone is set to.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    static let storageKey = "appAppearance"

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
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
