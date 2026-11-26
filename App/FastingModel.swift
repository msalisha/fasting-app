import Foundation
import Observation
import FastingCore

@Observable
@MainActor
final class FastingModel {
    private(set) var data: FastingData = FastStore.load()

    var activeFast: Fast? { data.activeFast }
    var completedFasts: [Fast] { data.completedFasts }
    var goalHours: Double { data.goalHours }

    func reload() {
        data = FastStore.load()
    }

    func start(at date: Date = .now) {
        GoalNotifier.requestPermission()
        FastStore.startFast(at: date)
        reload()
    }

    func end(at date: Date = .now) {
        FastStore.endFast(at: date)
        reload()
    }

    /// Changes the default goal, and the running fast's goal too.
    func setGoal(_ hours: Double) {
        data = FastStore.mutate { data in
            data.goalHours = hours
            if let i = data.fasts.firstIndex(where: \.isActive) {
                data.fasts[i].goalHours = hours
            }
        }
    }

    /// Insert or replace a fast (used by the editor and "add past fast").
    func save(_ fast: Fast) {
        data = FastStore.mutate { data in
            if let i = data.fasts.firstIndex(where: { $0.id == fast.id }) {
                data.fasts[i] = fast
            } else {
                data.fasts.append(fast)
            }
        }
    }

    func delete(_ fast: Fast) {
        data = FastStore.mutate { data in
            data.fasts.removeAll { $0.id == fast.id }
        }
    }
}
