import Foundation

// Comparing two `Date`s with `<=`, `>`, `>=`, `min`, `max` or `a...b` can crash with
// EXC_BAD_ACCESS (address 0x0) when the app is built with a newer iOS SDK than the iPhone runs:
// the compiled code calls a Date operator that the phone's Foundation doesn't have.
// These helpers compare the raw seconds (plain Doubles) instead, which works on every iOS version.
// Use them for every Date comparison in this app.

public extension Date {
    var seconds: TimeInterval { timeIntervalSinceReferenceDate }

    func isBefore(_ other: Date) -> Bool { seconds < other.seconds }
    func isAfter(_ other: Date) -> Bool { seconds > other.seconds }
    func isOnOrBefore(_ other: Date) -> Bool { seconds <= other.seconds }

    static func earlier(_ a: Date, _ b: Date) -> Date { a.seconds <= b.seconds ? a : b }
    static func later(_ a: Date, _ b: Date) -> Date { a.seconds >= b.seconds ? a : b }

    /// A closed range from the earlier to the later date, built without comparing Dates directly.
    static func span(_ a: Date, _ b: Date) -> ClosedRange<Date> {
        ClosedRange(uncheckedBounds: (lower: earlier(a, b), upper: later(a, b)))
    }
}
