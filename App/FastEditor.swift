import SwiftUI
import FastingCore

/// Edit an existing fast's times, or add a fast you forgot to log.
struct FastEditor: View {
    let fast: Fast

    @Environment(FastingModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    // Plain defaults here; the real values are copied in from `fast` in `onAppear`.
    @State private var start = Date.now
    @State private var end = Date.now
    @State private var goalSeconds: TimeInterval = FastingData.defaultGoalSeconds
    @State private var editingGoal = false
    /// Fixed when the editor opens, so the pickers' limits don't shift while you're using them.
    @State private var latest = Date.now
    @State private var loaded = false

    init(fast: Fast) {
        self.fast = fast
    }

    var body: some View {
        let isValid = fast.isActive ? start.isOnOrBefore(latest) : end.isAfter(start)
        let existsInStore = model.data.fasts.contains { $0.id == fast.id }

        NavigationStack {
            Form {
                Section {
                    DatePicker("Started", selection: $start, in: ...latest)
                    if !fast.isActive {
                        DatePicker("Ended", selection: $end, in: Date.span(Date.earlier(start, latest), latest))
                    }
                } footer: {
                    if !fast.isActive {
                        Text("Duration: \(Format.hoursMinutes(max(0, end.timeIntervalSince(start))))")
                    }
                }

                Section {
                    DisclosureGroup(isExpanded: $editingGoal) {
                        DurationWheels(seconds: $goalSeconds)
                    } label: {
                        LabeledContent("Goal", value: Format.goal(seconds: goalSeconds))
                    }
                }

                if existsInStore {
                    Section {
                        Button("Delete fast", role: .destructive) {
                            model.delete(fast)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(existsInStore ? "Edit fast" : "Add fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                }
            }
        }
        .tint(Theme.accent)
        .onAppear {
            guard !loaded else { return }
            loaded = true
            latest = .now
            start = Date.earlier(fast.start, latest)
            end = fast.end ?? latest
            goalSeconds = CustomDuration.clamp(fast.goalSeconds)
        }
    }

    private func save() {
        var updated = fast
        updated.start = start
        updated.end = fast.isActive ? nil : Date.later(end, start)
        updated.goalSeconds = goalSeconds
        model.save(updated)
        dismiss()
    }
}
