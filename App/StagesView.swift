import SwiftUI
import FastingCore

/// All fasting stages, with the current one highlighted while a fast is running.
struct StagesView: View {
    @Environment(FastingModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var showsDoneButton = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let elapsed = model.activeFast?.duration(at: context.date)
            let current = elapsed.map { FastingStage.stage(atElapsed: $0) }

            List {
                Section {
                    ForEach(FastingStage.all) { stage in
                        row(stage, isCurrent: stage == current)
                    }
                } footer: {
                    Text(FastingStage.disclaimer)
                        .padding(.top, Theme.Space.s)
                }
            }
        }
        .navigationTitle("Fasting stages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .tint(Theme.accent)
    }

    private func row(_ stage: FastingStage, isCurrent: Bool) -> some View {
        HStack(alignment: .top, spacing: Theme.Space.m) {
            Image(systemName: stage.symbol)
                .font(.title3)
                .foregroundStyle(isCurrent ? Theme.accent : Color.secondary)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stage.name).font(.headline)
                    if isCurrent {
                        Text("Now")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .foregroundStyle(Theme.onAccent)
                            .background(Theme.accent, in: Capsule())
                    }
                }
                Text(stage.startHour == 0 ? "From the start" : "From about \(Format.goal(stage.startHour))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(stage.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
