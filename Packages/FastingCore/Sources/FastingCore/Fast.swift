import Foundation

/// One fasting session. `end == nil` means the fast is still running.
public struct Fast: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var start: Date
    public var end: Date?
    public var goalHours: Double

    public init(id: UUID = UUID(), start: Date, end: Date? = nil, goalHours: Double) {
        self.id = id
        self.start = start
        self.end = end
        self.goalHours = goalHours
    }

    public var isActive: Bool { end == nil }

    public var goalEnd: Date { start.addingTimeInterval(goalHours * 3600) }

    public func duration(at now: Date = Date()) -> TimeInterval {
        max(0, (end ?? now).timeIntervalSince(start))
    }

    /// 0...1 progress towards the goal.
    public func progress(at now: Date = Date()) -> Double {
        guard goalHours > 0 else { return 1 }
        return min(1, duration(at: now) / (goalHours * 3600))
    }

    public func metGoal(at now: Date = Date()) -> Bool {
        duration(at: now) >= goalHours * 3600
    }
}

/// Everything the app persists.
public struct FastingData: Codable, Sendable {
    public var fasts: [Fast]
    public var goalHours: Double

    public init(fasts: [Fast] = [], goalHours: Double = 16) {
        self.fasts = fasts
        self.goalHours = goalHours
    }

    public var activeFast: Fast? { fasts.first(where: \.isActive) }

    /// Completed fasts, newest first.
    public var completedFasts: [Fast] {
        fasts.filter { !$0.isActive }.sorted { $0.start.isAfter($1.start) }
    }

    public var lastCompletedFast: Fast? { completedFasts.first }
}

public enum Format {
    /// "16h 05m"
    public static func hoursMinutes(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(max(0, interval) / 60)
        return "\(totalMinutes / 60)h \(twoDigits(totalMinutes % 60))m"
    }

    /// "16:05:32"
    public static func clock(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        return "\(total / 3600):\(twoDigits((total % 3600) / 60)):\(twoDigits(total % 60))"
    }

    /// "16h" or "16.5h"
    public static func goal(_ hours: Double) -> String {
        if hours == hours.rounded() { return "\(Int(hours))h" }
        return "\((hours * 10).rounded() / 10)h"
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
