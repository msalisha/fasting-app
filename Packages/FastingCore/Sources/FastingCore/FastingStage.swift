import Foundation

/// A rough guide to what the body is commonly doing at a point in a fast.
/// Timings vary a lot between people; this is general information, not medical advice.
public struct FastingStage: Identifiable, Hashable, Sendable {
    public let id: Int
    /// Hours into the fast at which this stage commonly begins.
    public let startHour: Double
    public let name: String
    /// SF Symbol name.
    public let symbol: String
    public let summary: String

    public var startSeconds: TimeInterval { startHour * 3600 }

    public static let disclaimer =
        "Stages are a general guide. Timing varies from person to person, and this is not medical advice. "
        + "Talk to a health professional before fasting if you are pregnant, have a medical condition, "
        + "take medication, or have a history of disordered eating."

    public static let all: [FastingStage] = [
        FastingStage(id: 0, startHour: 0, name: "Fed", symbol: "fork.knife",
                     summary: "Your body is digesting and using energy from your last meal."),
        FastingStage(id: 1, startHour: 4, name: "Settling", symbol: "leaf",
                     summary: "Digestion winds down. Blood sugar and insulin commonly ease back toward resting levels."),
        FastingStage(id: 2, startHour: 12, name: "Switching fuel", symbol: "arrow.triangle.swap",
                     summary: "With less glucose on hand, the body commonly starts drawing more on stored fat."),
        FastingStage(id: 3, startHour: 18, name: "Fat burning", symbol: "flame",
                     summary: "Stored fat is commonly the main fuel by now, and ketone levels tend to rise."),
        FastingStage(id: 4, startHour: 24, name: "Ketosis", symbol: "bolt",
                     summary: "Ketones are commonly a significant fuel source. Research into longer-fast effects in people is still early."),
        FastingStage(id: 5, startHour: 48, name: "Extended fast", symbol: "cross.case",
                     summary: "Fasts this long are best done with guidance from a health professional."),
    ]

    /// The stage for a fast that has been running this long.
    public static func stage(atElapsed seconds: TimeInterval) -> FastingStage {
        all.last { $0.startSeconds <= max(0, seconds) } ?? all[0]
    }

    /// The stage that comes next, or nil in the final stage.
    public static func next(afterElapsed seconds: TimeInterval) -> FastingStage? {
        all.first { $0.startSeconds > max(0, seconds) }
    }
}
