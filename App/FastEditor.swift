import SwiftUI

/// Edit an existing fast's times, or add a fast you forgot to log.
struct FastEditor: View {
    @Environment(FastingModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    private let original: Fast
    @State private var start: Date
    @State private var end: Date
    @State private var goalHours: Double
    /// Fixed when the editor opens, so the pickers' limits don't shift while you're using them.
    @State private var latest = Date.now

    init(fast: Fast) {
        original = fast
        _start = State(initialValue: fast.start)
        _end = State(initialValue: fast.end ?? .now)
        _goalHours = State(initialValue: fast.goalHours)
    }

    private var existsInStore: Bool {
        model.data.fasts.contains { $0.id == original.id }
    }

    private var isValid: Bool {
        original.isActive ? start <= latest : end > start
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Started", selection: $start, in: ...latest)
                    if !original.isActive {
                        DatePicker("Ended", selection: $end, in: min(start, latest)...latest)
                    }
                } footer: {
                    if !original.isActive {
                        Text("Duration: \(Format.hoursMinutes(max(0, end.timeIntervalSince(start))))")
                    }
                }

                Section {
                    Stepper("Goal: \(Format.goal(goalHours))", value: $goalHours, in: 1...168, step: 1)
                }

                if existsInStore {
                    Section {
                        Button("Delete fast", role: .destructive) {
                            model.delete(original)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(existsInStore ? "Edit fast" : "Add fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var fast = original
                        fast.start = start
                        fast.end = original.isActive ? nil : end
                        fast.goalHours = goalHours
                        model.save(fast)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
