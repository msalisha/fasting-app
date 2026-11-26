import Foundation
import CoreData
import Observation
import FastingCore

@Observable
@MainActor
final class FastingModel {
    private(set) var data: FastingData = FastStore.load()

    var activeFast: Fast? { data.activeFast }
    var completedFasts: [Fast] { data.completedFasts }
    var goalHours: Double { data.goalHours }

    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init() {
        let center = NotificationCenter.default

        // Another process (the widget or control) or iCloud changed the database.
        observers.append(center.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        })

        // iCloud finished downloading changes from another device: the widgets need to hear about it too.
        observers.append(center.addObserver(forName: NSPersistentCloudKitContainer.eventChangedNotification, object: nil, queue: .main) { [weak self] note in
            guard let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event,
                  event.type == .import, event.endDate != nil, event.succeeded
            else { return }
            Task { @MainActor in
                guard let self else { return }
                self.reload()
                FastStore.refreshSurfaces(with: self.data)
            }
        })
    }

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
