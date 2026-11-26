import WidgetKit
import SwiftUI
import AppIntents
import FastingCore

// MARK: - Timeline

struct FastingEntry: TimelineEntry {
    let date: Date
    let active: Fast?
    let lastFast: Fast?
    let goalHours: Double

    static let preview = FastingEntry(
        date: .now,
        active: Fast(start: .now.addingTimeInterval(-11.5 * 3600), goalHours: 16),
        lastFast: nil,
        goalHours: 16)
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
        FastingEntry(date: date, active: data.activeFast, lastFast: data.lastCompletedFast, goalHours: data.goalHours)
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
        .description("See how long you've been fasting.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .systemSmall])
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
        default:
            SmallView(entry: entry).containerBackground(for: .widget) {
                LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
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
        if let fast = entry.active {
            VStack(alignment: .leading, spacing: 1) {
                Label(fast.metGoal(at: entry.date) ? "Goal reached" : "Fasting",
                      systemImage: fast.metGoal(at: entry.date) ? "checkmark.circle.fill" : "timer")
                    .font(.headline)
                    .widgetAccentable()
                Text(fast.start, style: .timer)
                    .font(.title3.monospacedDigit().weight(.semibold))
                ProgressView(value: fast.progress(at: entry.date))
                    .tint(.primary)
                Text("Goal \(Format.goal(fast.goalHours)) · \(fast.goalEnd, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Label("Not fasting", systemImage: "fork.knife")
                    .font(.headline)
                    .widgetAccentable()
                if let last = entry.lastFast, let end = last.end {
                    Text("Last: \(Format.hoursMinutes(last.duration()))")
                        .font(.body.monospacedDigit())
                    Text("Ate \(end, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Tap to start a fast")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                Text(fast.start, style: .timer)
            } icon: {
                Image(systemName: "timer")
            }
        } else {
            Label("Not fasting", systemImage: "fork.knife")
        }
    }
}

// MARK: - Home screen: small, with a start/stop button

private struct SmallView: View {
    let entry: FastingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let fast = entry.active {
                Label(fast.metGoal(at: entry.date) ? "Goal reached" : "Fasting", systemImage: "timer")
                    .font(.caption.weight(.semibold))
                Text(fast.start, style: .timer)
                    .font(.title2.monospacedDigit().weight(.bold))
                ProgressView(value: fast.progress(at: entry.date))
                    .tint(.white)
                Spacer(minLength: 0)
                Button(intent: EndFastIntent()) {
                    Label("End", systemImage: "stop.fill").frame(maxWidth: .infinity)
                }
                .tint(.white.opacity(0.25))
            } else {
                Label("Not fasting", systemImage: "fork.knife")
                    .font(.caption.weight(.semibold))
                if let last = entry.lastFast {
                    Text(Format.hoursMinutes(last.duration()))
                        .font(.title2.monospacedDigit().weight(.bold))
                    Text("last fast").font(.caption2).opacity(0.8)
                }
                Spacer(minLength: 0)
                Button(intent: StartFastIntent()) {
                    Label("Start", systemImage: "play.fill").frame(maxWidth: .infinity)
                }
                .tint(.white.opacity(0.25))
            }
        }
        .foregroundStyle(.white)
    }
}

#Preview("Rectangular", as: .accessoryRectangular) {
    FastingWidget()
} timeline: {
    FastingEntry.preview
    FastingEntry(date: .now, active: nil,
                 lastFast: Fast(start: .now.addingTimeInterval(-20 * 3600), end: .now.addingTimeInterval(-3 * 3600), goalHours: 16),
                 goalHours: 16)
}

#Preview("Circular", as: .accessoryCircular) {
    FastingWidget()
} timeline: {
    FastingEntry.preview
}
