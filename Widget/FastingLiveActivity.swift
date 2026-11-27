import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents
import FastingCore

/// The live timer on the Lock Screen and in the Dynamic Island while a fast is running.
/// iOS ends Live Activities after about 8 hours; the Lock Screen widget keeps going after that.
struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingActivityAttributes.self) { context in
            LiveActivityBanner(state: context.state)
                .padding(Theme.Space.m)
                .widgetURL(URL(string: "stillfast://open"))
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    GoalRing(state: state)
                        .frame(width: 44, height: 44)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("Fasting")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ElapsedText(start: state.start)
                            .font(Theme.numerals(28))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Goal \(Format.goal(seconds: state.goalSeconds))")
                            .font(.caption.weight(.semibold))
                        Text(state.goalEnd, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button(intent: EndFastIntent()) {
                        Label("End fast", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.accent)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(Theme.accent)
            } compactTrailing: {
                ElapsedText(start: state.start)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 58)
            } minimal: {
                GoalRing(state: state)
            }
            .widgetURL(URL(string: "stillfast://open"))
            .keylineTint(Theme.accent)
        }
    }
}

/// Counts up from the start of the fast, always as h:mm:ss.
private struct ElapsedText: View {
    let start: Date

    var body: some View {
        Text(timerInterval: Date.span(start, .distantFuture), countsDown: false, showsHours: true)
            .monospacedDigit()
            .lineLimit(1)
    }
}

/// A ring that fills by itself between the start and the goal time.
private struct GoalRing: View {
    let state: FastingActivityAttributes.ContentState

    var body: some View {
        ProgressView(timerInterval: Date.span(state.start, state.goalEnd), countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            Image(systemName: "timer")
                .font(.caption2)
        }
        .progressViewStyle(.circular)
        .tint(Theme.accent)
    }
}

private struct LiveActivityBanner: View {
    let state: FastingActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            GoalRing(state: state)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text("Fasting · goal \(Format.goal(seconds: state.goalSeconds))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                ElapsedText(start: state.start)
                    .font(Theme.numerals(30))
                Text("Goal at \(state.goalEnd, style: .time)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button(intent: EndFastIntent()) {
                Image(systemName: "stop.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(Theme.accent)
            .accessibilityLabel("End fast")
        }
    }
}

#Preview("Live Activity", as: .content, using: FastingActivityAttributes(fastID: UUID())) {
    FastingLiveActivity()
} contentStates: {
    FastingActivityAttributes.ContentState(start: .now.addingTimeInterval(-5 * 3600), goalSeconds: 16 * 3600)
}
