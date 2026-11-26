import SwiftUI
import FastingCore

struct SettingsView: View {
    @Environment(FastingModel.self) private var model
    @AppStorage(GoalNotifier.enabledKey, store: AppGroup.defaults) private var notifyGoalReached = true
    @State private var choosingGoal = false

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Fasting") {
                    Button {
                        choosingGoal = true
                    } label: {
                        LabeledContent("Default goal", value: Format.goal(seconds: model.goalSeconds))
                    }
                    .foregroundStyle(.primary)

                    NavigationLink("Fasting stages") {
                        StagesView()
                    }
                }

                Section {
                    Toggle("Goal reached", isOn: $notifyGoalReached)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get a notification when your fast reaches its goal.")
                }

                Section {
                    Text(FastingStage.disclaimer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Health")
                }

                Section {
                    LabeledContent("Version", value: version)
                } header: {
                    Text("About")
                } footer: {
                    Text("Your fasts are stored on this iPhone and in your own iCloud. Stillfast has no accounts and collects no data.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $choosingGoal) {
                DurationPicker().environment(model)
            }
            .onChange(of: notifyGoalReached) { _, enabled in
                if enabled { GoalNotifier.requestPermission() }
                GoalNotifier.sync(with: model.data)
            }
        }
        .tint(Theme.accent)
    }
}
