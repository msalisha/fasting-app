import Foundation

/// One fasting session. `end == nil` means the fast is still running.
public struct Fast: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var start: Date
    public var end: Date?
    /// Planned length of the fast, in seconds.
    public var goalSeconds: TimeInterval

    public init(id: UUID = UUID(), start: Date, end: Date? = nil, goalSeconds: TimeInterval) {
        self.id = id
        self.start = start
        self.end = end
        self.goalSeconds = goalSeconds
    }

    public init(id: UUID = UUID(), start: Date, end: Date? = nil, goalHours: Double) {
        self.init(id: id, start: start, end: end, goalSeconds: goalHours * 3600)
    }

    /// The goal in hours. Kept for screens that still think in whole hours.
    public var goalHours: Double {
        get { goalSeconds / 3600 }
        set { goalSeconds = newValue * 3600 }
    }

    public var isActive: Bool { end == nil }

    public var goalEnd: Date { start.addingTimeInterval(goalSeconds) }

    public func duration(at now: Date = Date()) -> TimeInterval {
        max(0, (end ?? now).timeIntervalSince(start))
    }

    /// 0...1 progress towards the goal.
    public func progress(at now: Date = Date()) -> Double {
        guard goalSeconds > 0 else { return 1 }
        return min(1, duration(at: now) / goalSeconds)
    }

    public func metGoal(at now: Date = Date()) -> Bool {
        duration(at: now) >= goalSeconds
    }
}

/// A snapshot of everything the app stores: all fasts plus the default goal for new ones.
public struct FastingData: Codable, Sendable {
    public static let defaultGoalSeconds: TimeInterval = 16 * 3600

    public var fasts: [Fast]
    /// Goal given to the next fast that is started, in seconds.
    public var goalSeconds: TimeInterval

    public init(fasts: [Fast] = [], goalSeconds: TimeInterval = FastingData.defaultGoalSeconds) {
        self.fasts = fasts
        self.goalSeconds = goalSeconds
    }

    public var goalHours: Double {
        get { goalSeconds / 3600 }
        set { goalSeconds = newValue * 3600 }
    }

    public var activeFast: Fast? { fasts.first(where: \.isActive) }

    /// Completed fasts, newest first.
    public var completedFasts: [Fast] {
        fasts.filter { !$0.isActive }.sorted { $0.start.isAfter($1.start) }
    }

    public var lastCompletedFast: Fast? { completedFasts.first }

    /// Two devices can each start a fast before they sync, leaving more than one running.
    /// Returns the IDs of the extra running fasts: every running fast except the earliest.
    public var duplicateActiveFastIDs: [UUID] {
        let active = fasts.filter(\.isActive).sorted { $0.start.isBefore($1.start) }
        return active.dropFirst().map(\.id)
    }

    /// A copy with the extra running fasts removed, sorted newest first.
    public func resolvingDuplicates() -> FastingData {
        let extra = Set(duplicateActiveFastIDs)
        var copy = self
        copy.fasts = fasts.filter { !extra.contains($0.id) }.sorted { $0.start.isAfter($1.start) }
        return copy
    }
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

    /// A goal length: "16h", "16h 30m" or "45m".
    public static func goal(seconds: TimeInterval) -> String {
        let totalMinutes = Int((max(0, seconds) / 60).rounded())
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if m == 0 { return "\(h)h" }
        if h == 0 { return "\(m)m" }
        return "\(h)h \(m)m"
    }

    /// A goal length given in hours: "16h" or "16h 30m".
    public static func goal(_ hours: Double) -> String {
        goal(seconds: hours * 3600)
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
