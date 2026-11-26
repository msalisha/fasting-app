import XCTest
@testable import FastingCore

final class FastTests: XCTestCase {
    private let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func testActiveFastProgressAndGoal() {
        let fast = Fast(start: t0, goalHours: 16)
        XCTAssertTrue(fast.isActive)
        XCTAssertEqual(fast.progress(at: t0.addingTimeInterval(8 * 3600)), 0.5, accuracy: 0.0001)
        XCTAssertFalse(fast.metGoal(at: t0.addingTimeInterval(15.9 * 3600)))
        XCTAssertTrue(fast.metGoal(at: t0.addingTimeInterval(16 * 3600)))
        XCTAssertEqual(fast.progress(at: t0.addingTimeInterval(40 * 3600)), 1)
        XCTAssertEqual(fast.goalEnd, t0.addingTimeInterval(16 * 3600))
    }

    func testCompletedFastIgnoresNow() {
        let fast = Fast(start: t0, end: t0.addingTimeInterval(3600), goalHours: 16)
        XCTAssertFalse(fast.isActive)
        XCTAssertEqual(fast.duration(at: t0.addingTimeInterval(99 * 3600)), 3600)
    }

    func testDurationNeverNegative() {
        let fast = Fast(start: t0, goalHours: 16)
        XCTAssertEqual(fast.duration(at: t0.addingTimeInterval(-500)), 0)
    }

    func testFastingDataOrdering() {
        let old = Fast(start: t0, end: t0.addingTimeInterval(3600), goalHours: 16)
        let new = Fast(start: t0.addingTimeInterval(86_400), end: t0.addingTimeInterval(90_000), goalHours: 16)
        let active = Fast(start: t0.addingTimeInterval(200_000), goalHours: 16)
        let data = FastingData(fasts: [old, active, new])
        XCTAssertEqual(data.activeFast, active)
        XCTAssertEqual(data.completedFasts, [new, old])
        XCTAssertEqual(data.lastCompletedFast, new)
    }

    func testCodableRoundTrip() throws {
        let data = FastingData(fasts: [Fast(start: t0, end: t0.addingTimeInterval(60), goalHours: 18)], goalHours: 18)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(FastingData.self, from: encoder.encode(data))
        XCTAssertEqual(decoded.fasts, data.fasts)
        XCTAssertEqual(decoded.goalHours, 18)
    }
}

final class FormatTests: XCTestCase {
    func testHoursMinutes() {
        XCTAssertEqual(Format.hoursMinutes(0), "0h 00m")
        XCTAssertEqual(Format.hoursMinutes(16 * 3600 + 5 * 60 + 59), "16h 05m")
        XCTAssertEqual(Format.hoursMinutes(-10), "0h 00m")
    }

    func testClock() {
        XCTAssertEqual(Format.clock(16 * 3600 + 5 * 60 + 32), "16:05:32")
        XCTAssertEqual(Format.clock(59), "0:00:59")
    }

    func testGoal() {
        XCTAssertEqual(Format.goal(16), "16h")
        XCTAssertEqual(Format.goal(16.5), "16.5h")
    }
}

final class DateCompareTests: XCTestCase {
    private let a = Date(timeIntervalSinceReferenceDate: 100)
    private let b = Date(timeIntervalSinceReferenceDate: 200)

    func testComparisons() {
        XCTAssertTrue(a.isBefore(b))
        XCTAssertTrue(b.isAfter(a))
        XCTAssertTrue(a.isOnOrBefore(a))
        XCTAssertFalse(b.isOnOrBefore(a))
        XCTAssertEqual(Date.earlier(a, b), a)
        XCTAssertEqual(Date.later(a, b), b)
    }

    func testSpanIsOrderedEitherWay() {
        XCTAssertEqual(Date.span(b, a).lowerBound, a)
        XCTAssertEqual(Date.span(b, a).upperBound, b)
    }
}

final class StatsTests: XCTestCase {
    private let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func fast(daysAgo: Double, hours: Double, goal: Double = 16) -> Fast {
        let start = t0.addingTimeInterval(-daysAgo * 86_400)
        return Fast(start: start, end: start.addingTimeInterval(hours * 3600), goalHours: goal)
    }

    func testEmpty() {
        let stats = FastingStats(fasts: [])
        XCTAssertEqual(stats.count, 0)
        XCTAssertEqual(stats.average, 0)
        XCTAssertEqual(stats.longest, 0)
        XCTAssertEqual(stats.goalHitRate, 0)
        XCTAssertEqual(stats.streak, 0)
    }

    func testStatsNewestFirst() {
        // Newest first: two that met the goal, then a miss, then another hit.
        let fasts = [fast(daysAgo: 1, hours: 16), fast(daysAgo: 2, hours: 18), fast(daysAgo: 3, hours: 10), fast(daysAgo: 4, hours: 20)]
        let stats = FastingStats(fasts: fasts)
        XCTAssertEqual(stats.count, 4)
        XCTAssertEqual(stats.average, 16 * 3600, accuracy: 0.001)
        XCTAssertEqual(stats.longest, 20 * 3600, accuracy: 0.001)
        XCTAssertEqual(stats.goalHitRate, 0.75, accuracy: 0.0001)
        XCTAssertEqual(stats.streak, 2)
    }
}

final class DaySegmentTests: XCTestCase {
    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    func testFastAcrossMidnightSplitsIntoTwoDays() {
        let fast = Fast(start: date(10, 20), end: date(11, 12), goalHours: 16)
        let segments = DaySegment.make(from: [fast], days: 14, now: date(12, 9), calendar: calendar)
        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[0].day, date(10, 0))
        XCTAssertEqual(segments[0].startHour, 20, accuracy: 0.0001)
        XCTAssertEqual(segments[0].endHour, 24, accuracy: 0.0001)
        XCTAssertEqual(segments[1].day, date(11, 0))
        XCTAssertEqual(segments[1].startHour, 0, accuracy: 0.0001)
        XCTAssertEqual(segments[1].endHour, 12, accuracy: 0.0001)
        XCTAssertTrue(segments.allSatisfy { $0.metGoal && !$0.isActive })
    }

    func testActiveFastRunsUntilNow() {
        let fast = Fast(start: date(12, 6), goalHours: 16)
        let segments = DaySegment.make(from: [fast], days: 14, now: date(12, 9), calendar: calendar)
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].endHour, 9, accuracy: 0.0001)
        XCTAssertTrue(segments[0].isActive)
        XCTAssertFalse(segments[0].metGoal)
    }

    func testFastsOutsideWindowAreClippedOrDropped() {
        let old = Fast(start: date(1, 8), end: date(1, 20), goalHours: 12)
        let straddling = Fast(start: date(9, 18), end: date(10, 6), goalHours: 12)
        // 3-day window ending on the 12th starts at midnight on the 10th.
        let segments = DaySegment.make(from: [old, straddling], days: 3, now: date(12, 9), calendar: calendar)
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].day, date(10, 0))
        XCTAssertEqual(segments[0].startHour, 0, accuracy: 0.0001)
        XCTAssertEqual(segments[0].endHour, 6, accuracy: 0.0001)
    }

    func testDaysListNewestFirst() {
        let days = DaySegment.days(3, now: date(12, 9), calendar: calendar)
        XCTAssertEqual(days, [date(12, 0), date(11, 0), date(10, 0)])
    }
}
