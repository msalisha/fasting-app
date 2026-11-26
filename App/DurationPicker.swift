import SwiftUI
import FastingCore

/// Choose how long to fast: a preset, or any length from 30 minutes to 7 days.
struct DurationPicker: View {
    @Environment(FastingModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var seconds: TimeInterval = FastingData.defaultGoalSeconds
    @State private var showingCustom = false
    @State private var loaded = false

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(FastingPreset.all) { preset in
                            presetButton(preset)
                        }
                    }

                    customCard

                    Text(model.activeFast == nil
                         ? "Your next fast will use this goal."
                         : "This changes the goal for your current fast and for future fasts.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(Theme.Space.m)
            }
            .background(Theme.background)
            .navigationTitle("Fasting goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        model.setGoal(seconds: seconds)
                        dismiss()
                    }
                }
            }
        }
        .tint(Theme.accent)
        .onAppear {
            guard !loaded else { return }
            loaded = true
            seconds = CustomDuration.clamp(model.goalSeconds)
            showingCustom = FastingPreset.matching(seconds: seconds) == nil
        }
    }

    private func presetButton(_ preset: FastingPreset) -> some View {
        let selected = !showingCustom && FastingPreset.matching(seconds: seconds) == preset

        return Button {
            seconds = preset.seconds
            showingCustom = false
        } label: {
            VStack(spacing: 4) {
                Text(preset.title).font(Theme.numerals(24))
                Text(preset.subtitle).font(.caption).foregroundStyle(selected ? Color.white.opacity(0.85) : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .foregroundStyle(selected ? Color.white : Color.primary)
            .background(selected ? Theme.accent : Theme.card,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.hours) hours, \(preset.subtitle)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var customCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Button {
                withAnimation { showingCustom.toggle() }
            } label: {
                HStack {
                    Label("Custom", systemImage: "slider.horizontal.3")
                        .font(.headline)
                    Spacer()
                    if showingCustom {
                        Text(Format.goal(seconds: seconds))
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Theme.accent)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showingCustom ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showingCustom {
                DurationWheels(seconds: $seconds)
            }
        }
        .card()
    }
}

/// Hour and minute wheels bound to a length in seconds.
struct DurationWheels: View {
    @Binding var seconds: TimeInterval

    var body: some View {
        let parts = CustomDuration.split(seconds)

        HStack(spacing: 0) {
            Picker("Hours", selection: Binding(
                get: { parts.hours },
                set: { seconds = CustomDuration.combine(hours: $0, minutes: parts.minutes) })) {
                ForEach(0...CustomDuration.maxHours, id: \.self) { hour in
                    Text("\(hour) h").tag(hour)
                }
            }
            .pickerStyle(.wheel)

            Picker("Minutes", selection: Binding(
                get: { parts.minutes },
                set: { seconds = CustomDuration.combine(hours: parts.hours, minutes: $0) })) {
                ForEach(Array(stride(from: 0, to: 60, by: CustomDuration.stepMinutes)), id: \.self) { minute in
                    Text("\(minute) min").tag(minute)
                }
            }
            .pickerStyle(.wheel)
        }
        .frame(height: 130)
    }
}
