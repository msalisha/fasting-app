import SwiftUI
import WidgetKit
import FastingCore

struct SettingsView: View {
    @Environment(FastingModel.self) private var model
    @AppStorage(GoalNotifier.enabledKey, store: AppGroup.defaults) private var notifyGoalReached = true
    @AppStorage(AccentTheme.storageKey, store: AppGroup.defaults) private var accentTheme = AccentTheme.sage.rawValue
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system.rawValue
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

                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Colour")
                        HStack(spacing: 14) {
                            ForEach(AccentTheme.allCases) { theme in
                                swatch(theme)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    Picker("Mode", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { mode in
                            Text(mode.name).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
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

    private func swatch(_ theme: AccentTheme) -> some View {
        let selected = theme.rawValue == accentTheme

        return Button {
            accentTheme = theme.rawValue
            WidgetCenter.shared.reloadAllTimelines()
        } label: {
            Circle()
                .fill(theme.color)
                .frame(width: 34, height: 34)
                .overlay {
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.onAccent)
                    }
                }
                .padding(4)
                .overlay {
                    Circle().strokeBorder(selected ? theme.color : Color.clear, lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(theme.name)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
