import Foundation
import SwiftData
import FastingCore

/// How a fast is stored on disk and synced through iCloud.
/// The rest of the app works with the plain `Fast` value from FastingCore; only `FastStore` touches this.
///
/// CloudKit rules this model follows: every property has a default or is optional,
/// and there are no unique constraints.
@Model
final class FastRecord {
    var uuid: UUID = UUID()
    var start: Date = Date()
    var end: Date?
    var goalSeconds: Double = 57_600

    init(_ fast: Fast) {
        uuid = fast.id
        start = fast.start
        end = fast.end
        goalSeconds = fast.goalSeconds
    }

    var fast: Fast {
        Fast(id: uuid, start: start, end: end, goalSeconds: goalSeconds)
    }

    func update(from fast: Fast) {
        start = fast.start
        end = fast.end
        goalSeconds = fast.goalSeconds
    }
}
