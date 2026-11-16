import Foundation

/// One fasting session. `end == nil` means the fast is still running.
struct Fast: Codable, Identifiable, Hashable {
    var id: UUID
    var start: Date
    var end: Date?
    var goalHours: Double

    init(id: UUID = UUID(), start: Date, end: Date? = nil, goalHours: Double) {
        self.id = id
        self.start = start
        self.end = end
        self.goalHours = goalHours
    }

    var isActive: Bool { end == nil }

    var goalEnd: Date { start.addingTimeInterval(goalHours * 3600) }

    func duration(at now: Date = .now) -> TimeInterval {
        max(0, (end ?? now).timeIntervalSince(start))
    }

    /// 0...1 progress towards the goal.
    func progress(at now: Date = .now) -> Double {
        guard goalHours > 0 else { return 1 }
        return min(1, duration(at: now) / (goalHours * 3600))
    }

    func metGoal(at now: Date = .now) -> Bool {
        duration(at: now) >= goalHours * 3600
    }
}

/// Everything the app persists.
struct FastingData: Codable {
    var fasts: [Fast] = []
    var goalHours: Double = 16

    var activeFast: Fast? { fasts.first(where: \.isActive) }

    /// Completed fasts, newest first.
    var completedFasts: [Fast] {
        fasts.filter { !$0.isActive }.sorted { $0.start.isAfter($1.start) }
    }

    var lastCompletedFast: Fast? { completedFasts.first }
}

enum Format {
    /// "16h 05m"
    static func hoursMinutes(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return String(format: "%dh %02dm", h, m)
    }

    /// "16:05:32"
    static func clock(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    static func goal(_ hours: Double) -> String {
        hours == hours.rounded() ? "\(Int(hours))h" : String(format: "%.1fh", hours)
    }
}
