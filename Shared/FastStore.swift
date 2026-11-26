import Foundation
import WidgetKit
import UserNotifications
import FastingCore

/// The App Group shared by the app and the widget extension.
/// Its identifier comes from the `AppGroupID` key in each target's Info.plist (set in project.yml).
enum AppGroup {
    static let id: String =
        Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String ?? "group.com.example.fasting"

    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

/// Reads and writes `FastingData` as JSON in the shared App Group container,
/// so the app, the widgets and the Control (lock screen button) all see the same data.
enum FastStore {
    static let widgetKind = "FastingWidget"
    static let controlKind = "FastingControl"

    private static var fileURL: URL {
        AppGroup.containerURL.appendingPathComponent("fasting.json")
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func load() -> FastingData {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode(FastingData.self, from: data)
        else { return FastingData() }
        return decoded
    }

    /// Load, change, save, and refresh every surface that shows fasting state.
    @discardableResult
    static func mutate(_ change: (inout FastingData) -> Void) -> FastingData {
        var data = load()
        change(&data)
        data.fasts.sort { $0.start.isAfter($1.start) }
        if let encoded = try? encoder.encode(data) {
            try? encoded.write(to: fileURL, options: .atomic)
        }
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadControls(ofKind: controlKind)
        GoalNotifier.sync(with: data)
        return data
    }

    /// Starts a fast unless one is already running. Returns true if a fast was started.
    @discardableResult
    static func startFast(at date: Date = .now) -> Bool {
        var started = false
        mutate { data in
            guard data.activeFast == nil else { return }
            data.fasts.append(Fast(start: date, goalHours: data.goalHours))
            started = true
        }
        return started
    }

    /// Ends the running fast. Returns the finished fast, or nil if none was running.
    @discardableResult
    static func endFast(at date: Date = .now) -> Fast? {
        var finished: Fast?
        mutate { data in
            guard let i = data.fasts.firstIndex(where: \.isActive) else { return }
            data.fasts[i].end = Date.later(date, data.fasts[i].start)
            finished = data.fasts[i]
        }
        return finished
    }
}

/// Schedules a local notification for when the running fast reaches its goal.
enum GoalNotifier {
    private static let id = "fasting.goal-reached"

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func sync(with data: FastingData) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard let fast = data.activeFast, fast.goalEnd.isAfter(.now) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Goal reached 🎉"
        content.body = "You've fasted for \(Format.goal(fast.goalHours)). End your fast whenever you're ready."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: fast.goalEnd.timeIntervalSinceNow, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
