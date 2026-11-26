import Foundation

/// A ready-made fasting length the user can pick with one tap.
public struct FastingPreset: Identifiable, Hashable, Sendable {
    public let hours: Int
    /// A short description, e.g. "16:8" (fasting hours : eating hours).
    public let subtitle: String

    public var id: Int { hours }
    public var seconds: TimeInterval { TimeInterval(hours) * 3600 }
    public var title: String { "\(hours)h" }

    public static let all: [FastingPreset] = [
        FastingPreset(hours: 12, subtitle: "12:12"),
        FastingPreset(hours: 14, subtitle: "14:10"),
        FastingPreset(hours: 16, subtitle: "16:8"),
        FastingPreset(hours: 18, subtitle: "18:6"),
        FastingPreset(hours: 20, subtitle: "20:4"),
        FastingPreset(hours: 24, subtitle: "One day"),
        FastingPreset(hours: 36, subtitle: "Extended"),
    ]

    /// The preset with exactly this length, if there is one.
    public static func matching(seconds: TimeInterval) -> FastingPreset? {
        all.first { abs($0.seconds - seconds) < 1 }
    }
}

/// Rules for a goal the user sets by hand.
public enum CustomDuration {
    public static let stepMinutes = 5
    public static let minSeconds: TimeInterval = 30 * 60
    public static let maxHours = 168
    public static let maxSeconds: TimeInterval = TimeInterval(maxHours) * 3600

    /// Rounds to the nearest 5 minutes and keeps the result between 30 minutes and 7 days.
    public static func clamp(_ seconds: TimeInterval) -> TimeInterval {
        let step = TimeInterval(stepMinutes * 60)
        let rounded = (seconds / step).rounded() * step
        return min(maxSeconds, max(minSeconds, rounded))
    }

    /// Whole hours and minutes (a multiple of 5) for a goal.
    public static func split(_ seconds: TimeInterval) -> (hours: Int, minutes: Int) {
        let totalMinutes = Int(clamp(seconds) / 60)
        return (totalMinutes / 60, totalMinutes % 60)
    }

    public static func combine(hours: Int, minutes: Int) -> TimeInterval {
        clamp(TimeInterval(hours * 3600 + minutes * 60))
    }
}
