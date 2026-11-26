import SwiftUI
import FastingCore

/// The main screen: the ring, the live timer, the current stage, and one button.
struct TodayView: View {
    @Environment(FastingModel.self) private var model
    @State private var sheet: TodaySheet?
    @State private var confirmingEnd = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.l) {
                    goalChip

                    // Only this part refreshes every second.
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        VStack(spacing: Theme.Space.l) {
                            ring(now: context.date)
                            if let fast = model.activeFast {
                                stageCard(fast: fast, now: context.date)
                                timesCard(fast: fast)
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Space.m)
                .padding(.bottom, Theme.Space.l)
            }
            .background(Theme.background)
            .navigationTitle(model.activeFast == nil ? "Ready to fast" : "Fasting")
            .safeAreaInset(edge: .bottom) { actions }
            .sheet(item: $sheet) { sheet in
                sheetContent(sheet).environment(model)
            }
            .confirmationDialog("End this fast?", isPresented: $confirmingEnd, titleVisibility: .visible) {
                Button("End fast") { model.end() }
                Button("Keep fasting", role: .cancel) {}
            }
            .sensoryFeedback(.impact, trigger: model.activeFast?.id)
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: TodaySheet) -> some View {
        switch sheet {
        case .goal:
            DurationPicker()
        case .stages:
            NavigationStack {
                StagesView(showsDoneButton: true)
            }
        case .startEarlier:
            StartEarlierSheet()
        case .edit(let fast):
            FastEditor(fast: fast)
        }
    }

    // MARK: Goal chip

    private var goalChip: some View {
        Button {
            sheet = .goal
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "target")
                Text("Goal \(Format.goal(seconds: model.goalSeconds))")
                Image(systemName: "chevron.down").font(.caption2.weight(.semibold))
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.card, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Fasting goal, \(Format.goal(seconds: model.goalSeconds))")
        .accessibilityHint("Changes how long you plan to fast")
    }

    // MARK: Ring

    private func ring(now: Date) -> some View {
        let fast = model.activeFast
        let met = fast?.metGoal(at: now) ?? false

        return ZStack {
            ProgressRing(progress: fast?.progress(at: now) ?? 0)
            VStack(spacing: 6) {
                if let fast {
                    Eyebrow(met ? "Goal reached" : "Elapsed")
                    bigClock(fast.duration(at: now))
                    if met {
                        Text("+\(Format.hoursMinutes(now.timeIntervalSince(fast.goalEnd))) past goal")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Theme.accent)
                    } else {
                        Text("\(Format.hoursMinutes(fast.goalEnd.timeIntervalSince(now))) to go")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                } else if let last = model.completedFasts.first, let end = last.end {
                    Eyebrow("Since last fast")
                    bigClock(now.timeIntervalSince(end))
                    Text("Last fast \(Format.hoursMinutes(last.duration()))")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "leaf")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(Theme.accent)
                    Text("Ready when you are")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Theme.Space.xl)
        }
        .frame(maxWidth: 300)
        .padding(.vertical, Theme.Space.s)
        .accessibilityElement(children: .combine)
    }

    private func bigClock(_ interval: TimeInterval) -> some View {
        Text(Format.clock(interval))
            .font(Theme.numerals(48))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    // MARK: Cards

    private func stageCard(fast: Fast, now: Date) -> some View {
        let elapsed = fast.duration(at: now)
        let stage = FastingStage.stage(atElapsed: elapsed)
        let next = FastingStage.next(afterElapsed: elapsed)

        return Button {
            sheet = .stages
        } label: {
            HStack(alignment: .top, spacing: Theme.Space.m) {
                Image(systemName: stage.symbol)
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(stage.name).font(.headline)
                    Text(stage.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                    if let next {
                        Text("Next: \(next.name) in \(Format.hoursMinutes(next.startSeconds - elapsed))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .card()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows all fasting stages")
    }

    private func timesCard(fast: Fast) -> some View {
        HStack(spacing: 0) {
            timeTile(title: "Started", date: fast.start)
            Divider().frame(height: 36)
            timeTile(title: "Goal", date: fast.goalEnd)
        }
        .card()
    }

    private func timeTile(title: String, date: Date) -> some View {
        VStack(spacing: 4) {
            Eyebrow(title)
            Text(date.formatted(date: .omitted, time: .shortened))
                .font(.title3.weight(.semibold))
            Text(date.formatted(.dateTime.weekday(.wide)))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: 10) {
            if let fast = model.activeFast {
                Button {
                    confirmingEnd = true
                } label: {
                    Text("End fast").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Edit start time") { sheet = .edit(fast) }
                    .font(.subheadline)
            } else {
                Button {
                    model.start()
                } label: {
                    Text("Start fast").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("I started earlier…") { sheet = .startEarlier }
                    .font(.subheadline)
            }
        }
        .tint(Theme.accent)
        .padding(.horizontal, Theme.Space.m)
        .padding(.top, Theme.Space.s)
        .padding(.bottom, Theme.Space.s)
        .background(Theme.background)
    }
}

/// The sheets the Today screen can show. One `sheet` modifier handles them all.
enum TodaySheet: Identifiable {
    case goal
    case stages
    case startEarlier
    case edit(Fast)

    var id: String {
        switch self {
        case .goal: "goal"
        case .stages: "stages"
        case .startEarlier: "startEarlier"
        case .edit(let fast): "edit-\(fast.id.uuidString)"
        }
    }
}

/// Start a fast with a start time in the past (e.g. "my last meal was at 8pm").
private struct StartEarlierSheet: View {
    @Environment(FastingModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var start = Date.now.addingTimeInterval(-3600)
    @State private var latest = Date.now

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Last meal", selection: $start, in: ...latest)
            }
            .navigationTitle("Start earlier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        model.start(at: start)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
