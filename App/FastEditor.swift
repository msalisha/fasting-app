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
    @State private var goalHours = 16.0
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
                    Stepper("Goal: \(Format.goal(goalHours))", value: $goalHours, in: 1...168, step: 1)
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
        .onAppear {
            guard !loaded else { return }
            loaded = true
            latest = .now
            start = Date.earlier(fast.start, latest)
            end = fast.end ?? latest
            goalHours = fast.goalHours
        }
    }

    private func save() {
        var updated = fast
        updated.start = start
        updated.end = fast.isActive ? nil : Date.later(end, start)
        updated.goalHours = goalHours
        model.save(updated)
        dismiss()
    }
}
