import Foundation

struct FastingStats {
    let count: Int
    let average: TimeInterval
    let longest: TimeInterval
    let goalHitRate: Double
    /// Consecutive most-recent completed fasts that met their goal.
    let streak: Int

    init(fasts: [Fast]) {
        // `fasts` is expected newest first, completed only.
        count = fasts.count
        let durations = fasts.map { $0.duration() }
        average = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)
        longest = durations.max() ?? 0
        goalHitRate = fasts.isEmpty ? 0 : Double(fasts.filter { $0.metGoal() }.count) / Double(fasts.count)
        streak = fasts.prefix { $0.metGoal() }.count
    }
}

/// The part of one fast that falls on one calendar day — used by the 24-hour timeline chart.
struct DaySegment: Identifiable {
    let id = UUID()
    let day: Date
    let startHour: Double
    let endHour: Double
    let metGoal: Bool
    let isActive: Bool

    /// Splits fasts into per-day pieces for the last `days` days (including today).
    static func make(from fasts: [Fast], days: Int, now: Date = .now, calendar: Calendar = .current) -> [DaySegment] {
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
    static func days(_ count: Int, now: Date = .now, calendar: Calendar = .current) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }
}
