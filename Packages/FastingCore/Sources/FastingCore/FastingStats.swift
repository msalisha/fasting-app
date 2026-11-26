import Foundation

public struct FastingStats: Sendable {
    public let count: Int
    public let average: TimeInterval
    public let longest: TimeInterval
    public let goalHitRate: Double
    /// Consecutive most-recent completed fasts that met their goal.
    public let streak: Int

    /// `fasts` is expected newest first, completed only.
    public init(fasts: [Fast]) {
        count = fasts.count
        let durations = fasts.map { $0.duration() }
        average = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)
        longest = durations.max() ?? 0
        goalHitRate = fasts.isEmpty ? 0 : Double(fasts.filter { $0.metGoal() }.count) / Double(fasts.count)
        streak = fasts.prefix { $0.metGoal() }.count
    }
}

/// The part of one fast that falls on one calendar day — used by the 24-hour timeline chart.
public struct DaySegment: Identifiable, Sendable {
    public let id = UUID()
    public let day: Date
    public let startHour: Double
    public let endHour: Double
    public let metGoal: Bool
    public let isActive: Bool

    public init(day: Date, startHour: Double, endHour: Double, metGoal: Bool, isActive: Bool) {
        self.day = day
        self.startHour = startHour
        self.endHour = endHour
        self.metGoal = metGoal
        self.isActive = isActive
    }

    /// Splits fasts into per-day pieces for the last `days` days (including today).
    public static func make(from fasts: [Fast], days: Int, now: Date = Date(), calendar: Calendar = .current) -> [DaySegment] {
        let today = calendar.startOfDay(for: now)
        guard let rangeStart = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return [] }

        var result: [DaySegment] = []
        for fast in fasts {
            let fastEnd = fast.end ?? now
            guard fastEnd.isAfter(rangeStart) else { continue }
            var cursor = Date.later(fast.start, rangeStart)
            while cursor.isBefore(fastEnd) {
                let dayStart = calendar.startOfDay(for: cursor)
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else { break }
                let segmentEnd = Date.earlier(fastEnd, nextDay)
                result.append(DaySegment(
                    day: dayStart,
                    startHour: cursor.timeIntervalSince(dayStart) / 3600,
                    endHour: min(24, segmentEnd.timeIntervalSince(dayStart) / 3600),
                    metGoal: fast.metGoal(at: now),
                    isActive: fast.isActive))
                cursor = segmentEnd
            }
        }
        return result
    }

    /// The days shown on the timeline chart, newest first.
    public static func days(_ count: Int, now: Date = Date(), calendar: Calendar = .current) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }
}
