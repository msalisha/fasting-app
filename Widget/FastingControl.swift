import WidgetKit
import SwiftUI
import AppIntents

/// A one-tap toggle you can put on the Lock Screen (in place of the flashlight/camera buttons),
/// in Control Center, or on the Action button.
struct FastingControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: FastStore.controlKind, provider: Provider()) { isFasting in
            ControlWidgetToggle("Fasting", isOn: isFasting, action: SetFastingIntent()) { on in
                Label(on ? "Fasting" : "Not fasting", systemImage: on ? "timer" : "fork.knife")
            }
        }
        .displayName("Fasting")
        .description("Start or end a fast with one tap.")
    }

    struct Provider: ControlValueProvider {
        var previewValue: Bool { false }

        func currentValue() async throws -> Bool {
            FastStore.load().activeFast != nil
        }
    }
}
