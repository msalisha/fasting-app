import ActivityKit
import Foundation
import FastingCore

/// What the Live Activity (Lock Screen banner and Dynamic Island) shows for a running fast.
struct FastingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var start: Date
        var goalSeconds: Double

        var goalEnd: Date { start.addingTimeInterval(goalSeconds) }
    }

    var fastID: UUID
}

/// Starts, updates and ends the Live Activity so it always matches the running fast.
/// Safe to call often; it only changes what differs.
enum LiveActivityController {
    /// App Group defaults key for the Settings switch. On unless the user turns it off.
    static let enabledKey = "liveActivityEnabled"

    static var isEnabled: Bool {
        AppGroup.defaults.object(forKey: enabledKey) as? Bool ?? true
    }

    static func sync(with data: FastingData) {
        let activities = Activity<FastingActivityAttributes>.activities

        guard isEnabled, let fast = data.activeFast else {
            for activity in activities {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }
            return
        }

        let state = FastingActivityAttributes.ContentState(start: fast.start, goalSeconds: fast.goalSeconds)
        let content = ActivityContent(state: state, staleDate: nil)

        var hasCurrent = false
        for activity in activities {
            if activity.attributes.fastID == fast.id, !hasCurrent {
                hasCurrent = true
                if activity.content.state != state {
                    Task { await activity.update(content) }
                }
            } else {
                // A finished or duplicate fast.
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }
        }

        guard !hasCurrent, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        _ = try? Activity.request(
            attributes: FastingActivityAttributes(fastID: fast.id),
            content: content,
            pushType: nil)
    }
}
