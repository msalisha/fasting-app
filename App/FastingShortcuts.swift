import AppIntents

/// Makes "Start a fast" / "End my fast" available to Siri, Spotlight, Shortcuts and the Action button.
struct FastingShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFastIntent(),
            phrases: ["Start a fast in \(.applicationName)", "Start fasting in \(.applicationName)"],
            shortTitle: "Start Fast",
            systemImageName: "play.circle")
        AppShortcut(
            intent: EndFastIntent(),
            phrases: ["End my fast in \(.applicationName)", "Stop fasting in \(.applicationName)"],
            shortTitle: "End Fast",
            systemImageName: "stop.circle")
    }
}
