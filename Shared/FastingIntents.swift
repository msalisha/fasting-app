import AppIntents
import FastingCore

// These are LiveActivityIntents so they run in the app, which can start and end the Live Activity,
// even when tapped in a widget, the Lock Screen control or the Live Activity itself.

/// Used by the home-screen widget button, Siri and Shortcuts.
struct StartFastIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Start Fast"
    static let description = IntentDescription("Starts a new fast now.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let started = FastStore.startFast()
        let dialog: IntentDialog = started ? "Fast started. Good luck!" : "You're already fasting."
        return .result(dialog: dialog)
    }
}

struct EndFastIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "End Fast"
    static let description = IntentDescription("Ends the current fast now.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let fast = FastStore.endFast() else {
            return .result(dialog: "You're not fasting right now.")
        }
        let length = Format.hoursMinutes(fast.duration())
        return .result(dialog: "Fast ended after \(length).")
    }
}

/// Backs the lock screen / Control Center toggle.
struct SetFastingIntent: SetValueIntent, LiveActivityIntent {
    static let title: LocalizedStringResource = "Set Fasting"

    @Parameter(title: "Fasting")
    var value: Bool

    func perform() async throws -> some IntentResult {
        if value {
            FastStore.startFast()
        } else {
            FastStore.endFast()
        }
        return .result()
    }
}
