import Foundation
import SwiftData
import WidgetKit
import UserNotifications
import FastingCore

/// Reads and writes fasts in the shared database (see `Persistence`),
/// so the app, the widgets and the Control (lock screen button) all see the same data.
enum FastStore {
    static let widgetKind = "FastingWidget"
    static let controlKind = "FastingControl"

    private static let goalKey = "defaultGoalSeconds"

    /// Goal given to the next fast that is started. Stored per device in the App Group.
    private static var defaultGoalSeconds: TimeInterval {
        get {
            let stored = AppGroup.defaults.double(forKey: goalKey)
            return stored > 0 ? stored : FastingData.defaultGoalSeconds
        }
        set { AppGroup.defaults.set(newValue, forKey: goalKey) }
    }

    static func load() -> FastingData {
        let context = ModelContext(Persistence.container)
        return snapshot(of: fetchRecords(in: context))
    }

    /// Load, change, save, and refresh every surface that shows fasting state.
    @discardableResult
    static func mutate(_ change: (inout FastingData) -> Void) -> FastingData {
        let context = ModelContext(Persistence.container)
        let records = fetchRecords(in: context)

        var data = snapshot(of: records)
        change(&data)
        data = data.resolvingDuplicates()

        // Make the stored records match `data`: update or insert what is in it, delete what is not.
        var wanted: [UUID: Fast] = [:]
        for fast in data.fasts { wanted[fast.id] = fast }
        for record in records {
            if let fast = wanted.removeValue(forKey: record.uuid) {
                if record.fast != fast { record.update(from: fast) }
            } else {
                context.delete(record)
            }
        }
        for fast in wanted.values {
            context.insert(FastRecord(fast))
        }
        try? context.save()
        defaultGoalSeconds = data.goalSeconds

        refreshSurfaces(with: data)
        return data
    }

    /// Reloads widgets and the control, and reschedules the goal notification.
    static func refreshSurfaces(with data: FastingData) {
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadControls(ofKind: controlKind)
        GoalNotifier.sync(with: data)
        LiveActivityController.sync(with: data)
    }

    private static func fetchRecords(in context: ModelContext) -> [FastRecord] {
        (try? context.fetch(FetchDescriptor<FastRecord>())) ?? []
    }

    private static func snapshot(of records: [FastRecord]) -> FastingData {
        FastingData(fasts: records.map(\.fast), goalSeconds: defaultGoalSeconds).resolvingDuplicates()
    }

    /// Starts a fast unless one is already running. Returns true if a fast was started.
    @discardableResult
    static func startFast(at date: Date = .now) -> Bool {
        var started = false
        mutate { data in
            guard data.activeFast == nil else { return }
            data.fasts.append(Fast(start: date, goalSeconds: data.goalSeconds))
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
    /// App Group defaults key for the "Goal reached" setting. On unless the user turns it off.
    static let enabledKey = "notifyGoalReached"

    private static var isEnabled: Bool {
        AppGroup.defaults.object(forKey: enabledKey) as? Bool ?? true
    }

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func sync(with data: FastingData) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard isEnabled, let fast = data.activeFast, fast.goalEnd.isAfter(.now) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Goal reached"
        content.body = "You've fasted for \(Format.goal(seconds: fast.goalSeconds)). End your fast whenever you're ready."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: fast.goalEnd.timeIntervalSinceNow, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
