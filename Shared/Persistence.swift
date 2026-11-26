import Foundation
import SwiftData

/// The App Group shared by the app and the widget extension.
/// Its identifier comes from the `AppGroupID` key in each target's Info.plist (set in project.yml).
enum AppGroup {
    static let id: String =
        Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String ?? "group.com.alishasutcliffe.stillfast"

    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }
}

/// The one database, stored in the App Group so the app, widgets and intents all read the same file.
enum Persistence {
    static let container: ModelContainer = makeContainer()

    /// True in the main app, false in the widget extension.
    private static var isMainApp: Bool {
        Bundle.main.bundleURL.pathExtension != "appex"
    }

    /// The iCloud container, from the `CloudContainerID` Info.plist key. Only the app has one.
    private static var cloudContainerID: String? {
        Bundle.main.object(forInfoDictionaryKey: "CloudContainerID") as? String
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([FastRecord.self])
        let url = AppGroup.containerURL.appendingPathComponent("Stillfast.store")

        // Only the app syncs with iCloud. The widget extension opens the same file with sync off
        // and the app uploads its changes the next time it runs.
        if isMainApp, let cloudContainerID {
            let synced = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .private(cloudContainerID))
            if let container = try? ModelContainer(for: schema, configurations: [synced]) {
                return container
            }
        }

        // No iCloud available (or the extension): the same file, kept on this device only.
        let local = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        if let container = try? ModelContainer(for: schema, configurations: [local]) {
            return container
        }

        // Last resort so the app still opens: nothing is saved between launches.
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [memory])
        } catch {
            fatalError("Could not create any data store: \(error)")
        }
    }
}
