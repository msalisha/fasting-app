import WidgetKit
import SwiftUI
import AppIntents
import FastingCore

// MARK: - Timeline

struct FastingEntry: TimelineEntry {
    let date: Date
    let active: Fast?
    let lastFast: Fast?
    let goalSeconds: TimeInterval

    static let preview = FastingEntry(
        date: .now,
        active: Fast(start: .now.addingTimeInterval(-11.5 * 3600), goalHours: 16),
        lastFast: nil,
        goalSeconds: 16 * 3600)
}

struct FastingProvider: TimelineProvider {
    func placeholder(in context: Context) -> FastingEntry { .preview }

    func getSnapshot(in context: Context, completion: @escaping (FastingEntry) -> Void) {
        completion(context.isPreview ? .preview : entry(at: .now, data: FastStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastingEntry>) -> Void) {
        let data = FastStore.load()
        let now = Date.now

        guard data.activeFast != nil else {
            // Nothing changes on its own while not fasting; the app/intents reload us on change.
            completion(Timeline(entries: [entry(at: now, data: data)], policy: .after(now.addingTimeInterval(3600))))
            return
        }

        // Timers in the views tick live; these entries move the progress gauges along.
        let entries = (0..<48).map { i in
            entry(at: now.addingTimeInterval(Double(i) * 5 * 60), data: data)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(at date: Date, data: FastingData) -> FastingEntry {
        FastingEntry(date: date, active: data.activeFast, lastFast: data.lastCompletedFast, goalSeconds: data.goalSeconds)
    }
}

// MARK: - Widget

struct FastingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: FastStore.widgetKind, provider: FastingProvider()) { entry in
            FastingWidgetView(entry: entry)
                .widgetURL(URL(string: "stillfast://open"))
        }
        .configurationDisplayName("Stillfast")
        .description("See your fast at a glance, and start or end it.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .systemSmall, .systemMedium])
    }
}

struct FastingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FastingEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularView(entry: entry).containerBackground(for: .widget) { Color.clear }
        case .accessoryRectangular:
            RectangularView(entry: entry).containerBackground(for: .widget) { Color.clear }
        case .accessoryInline:
            InlineView(entry: entry).containerBackground(for: .widget) { Color.clear }
        case .systemMedium:
            MediumView(entry: entry).containerBackground(for: .widget) { Theme.background }
        default:
            SmallView(entry: entry).containerBackground(for: .widget) { Theme.background }
        }
    }
}

// MARK: - Lock screen: circular

private struct CircularView: View {
    let entry: FastingEntry

    var body: some View {
        if let fast = entry.active {
            let hours = Int(fast.duration(at: entry.date) / 3600)
            Gauge(value: fast.progress(at: entry.date)) {
                Image(systemName: fast.metGoal(at: entry.date) ? "checkmark" : "timer")
            } currentValueLabel: {
                Text("\(hours)h")
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: "fork.knife").font(.title3)
                    Text("Eat").font(.caption2)
                }
            }
        }
    }
}

// MARK: - Lock screen: rectangular

private struct RectangularView: View {
    let entry: FastingEntry

    var body: some View {
        // Three short rows: iOS gives this widget only about three lines of height.
        if let fast = entry.active {
            let met = fast.metGoal(at: entry.date)
            let goal = Format.goal(seconds: fast.goalSeconds)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: met ? "checkmark.circle.fill" : "timer")
                    Text(met ? "Goal reached" : "Fasting")
                    Spacer(minLength: 4)
                    // Longest version that fits: goal and end time, else just the goal.
                    ViewThatFits {
                        Text("\(goal) · \(fast.goalEnd, style: .time)")
                        Text(goal)
                    }
                    .foregroundStyle(.secondary)
                }
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .widgetAccentable()

                // Always h:mm:ss, so 51 minutes reads "0:51:35" rather than "51:35".
                Text(timerInterval: Date.span(fast.start, .distantFuture), countsDown: false, showsHours: true)
                    .font(.system(size: 26, weight: .semibold, design: .rounded).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Gauge(value: fast.progress(at: entry.date)) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryLinearCapacity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Label("Not fasting", systemImage: "fork.knife")
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .widgetAccentable()
                if let last = entry.lastFast, let end = last.end {
                    Text("Last \(Format.hoursMinutes(last.duration()))")
                        .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("Ate \(end, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Tap to start a fast")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Lock screen: inline (above the clock)

private struct InlineView: View {
    let entry: FastingEntry

    var body: some View {
        if let fast = entry.active {
            Label {
                Text(timerInterval: Date.span(fast.start, .distantFuture), countsDown: false, showsHours: true)
            } icon: {
                Image(systemName: "timer")
            }
        } else {
            Label("Not fasting", systemImage: "fork.knife")
        }
    }
}

// MARK: - Home screen

/// Start or end button for the Home Screen widgets. Runs in the app so the Live Activity follows.
private struct FastButton: View {
    let isFasting: Bool

    var body: some View {
        if isFasting {
            Button(intent: EndFastIntent()) {
                Text("End fast").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(Theme.accent)
        } else {
            Button(intent: StartFastIntent()) {
                Text("Start fast")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Theme.onAccent)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
        }
    }
}

private struct SmallView: View {
    let entry: FastingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let fast = entry.active {
                HStack {
                    Text(fast.metGoal(at: entry.date) ? "Goal reached" : "Fasting")
                    Spacer(minLength: 4)
                    Text(Format.goal(seconds: fast.goalSeconds))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

                Text(timerInterval: Date.span(fast.start, .distantFuture), countsDown: false, showsHours: true)
                    .font(Theme.numerals(26))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                ProgressView(value: fast.progress(at: entry.date))
                    .tint(Theme.accent)
            } else {
                Text("Not fasting")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let last = entry.lastFast {
                    Text(Format.hoursMinutes(last.duration()))
                        .font(Theme.numerals(26))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("last fast")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            FastButton(isFasting: entry.active != nil)
        }
    }
}

private struct MediumView: View {
    let entry: FastingEntry

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            ring
                .frame(width: 112, height: 112)

            VStack(alignment: .leading, spacing: 4) {
                if let fast = entry.active {
                    let stage = FastingStage.stage(atElapsed: fast.duration(at: entry.date))

                    Text(fast.metGoal(at: entry.date) ? "Goal reached" : "Fasting")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(timerInterval: Date.span(fast.start, .distantFuture), countsDown: false, showsHours: true)
                        .font(Theme.numerals(28))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Label(stage.name, systemImage: stage.symbol)
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                        .lineLimit(1)
                    Text("Goal \(Format.goal(seconds: fast.goalSeconds)) · \(fast.goalEnd, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Not fasting")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if let last = entry.lastFast, let end = last.end {
                        Text("Last \(Format.hoursMinutes(last.duration()))")
                            .font(Theme.numerals(24))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("Ate \(end, style: .relative) ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Goal \(Format.goal(seconds: entry.goalSeconds))")
                            .font(Theme.numerals(24))
                    }
                }
                Spacer(minLength: 0)
                FastButton(isFasting: entry.active != nil)
            }
        }
    }

    private var ring: some View {
        ZStack {
            ProgressRing(progress: entry.active?.progress(at: entry.date) ?? 0, lineWidth: 10)
            if let fast = entry.active {
                Text("\(Int((fast.progress(at: entry.date) * 100).rounded()))%")
                    .font(Theme.numerals(20))
            } else {
                Image(systemName: "leaf")
                    .font(.title2.weight(.light))
                    .foregroundStyle(Theme.accent)
            }
        }
    }
}

#Preview("Rectangular", as: .accessoryRectangular) {
    FastingWidget()
} timeline: {
    FastingEntry.preview
    FastingEntry(date: .now, active: nil,
                 lastFast: Fast(start: .now.addingTimeInterval(-20 * 3600), end: .now.addingTimeInterval(-3 * 3600), goalHours: 16),
                 goalSeconds: 16 * 3600)
}

#Preview("Circular", as: .accessoryCircular) {
    FastingWidget()
} timeline: {
    FastingEntry.preview
}

#Preview("Medium", as: .systemMedium) {
    FastingWidget()
} timeline: {
    FastingEntry.preview
}
