import SwiftUI
import Charts

struct HistoryView: View {
    @Environment(FastingModel.self) private var model
    @State private var chart: ChartKind = .timeline
    @State private var editing: Fast?

    enum ChartKind: String, CaseIterable, Identifiable {
        case timeline = "Timeline"
        case duration = "Duration"
        var id: Self { self }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    StatsGrid(stats: FastingStats(fasts: model.completedFasts))
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                Section {
                    Picker("Chart", selection: $chart) {
                        ForEach(ChartKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch chart {
                    case .timeline: TimelineChart(fasts: model.data.fasts)
                    case .duration: DurationChart(fasts: model.completedFasts, goalHours: model.goalHours)
                    }
                }

                Section("Fasts") {
                    if model.data.fasts.isEmpty {
                        ContentUnavailableView("No fasts yet", systemImage: "timer",
                                               description: Text("Start a fast, or add a past one with +."))
                    }
                    ForEach(model.data.fasts) { fast in
                        Button { editing = fast } label: { FastRow(fast: fast) }
                            .foregroundStyle(.primary)
                    }
                    .onDelete { offsets in
                        let fasts = model.data.fasts
                        offsets.forEach { model.delete(fasts[$0]) }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let end = Date.now
                        editing = Fast(start: end.addingTimeInterval(-model.goalHours * 3600), end: end, goalHours: model.goalHours)
                    } label: {
                        Label("Add past fast", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editing) { FastEditor(fast: $0) }
        }
    }
}

// MARK: - Stats

private struct StatsGrid: View {
    let stats: FastingStats

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            tile("Average", Format.hoursMinutes(stats.average), "chart.line.flattrend.xyaxis")
            tile("Longest", Format.hoursMinutes(stats.longest), "trophy")
            tile("Goal hit", "\(Int((stats.goalHitRate * 100).rounded()))%", "target")
            tile("Streak", "\(stats.streak) \(stats.streak == 1 ? "fast" : "fasts")", "flame")
        }
        .padding(.vertical, 4)
    }

    private func tile(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.semibold).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Charts

/// Each row is a day; bars show when during that day you were fasting.
private struct TimelineChart: View {
    let fasts: [Fast]
    private let dayCount = 14

    var body: some View {
        let days = DaySegment.days(dayCount)
        let segments = DaySegment.make(from: fasts, days: dayCount)

        VStack(alignment: .leading, spacing: 8) {
            chart(days: days, segments: segments)
            legend
        }
    }

    private func chart(days: [Date], segments: [DaySegment]) -> some View {
        Chart(segments) { segment in
            BarMark(
                xStart: .value("Start", segment.startHour),
                xEnd: .value("End", segment.endHour),
                y: .value("Day", label(segment.day)),
                height: .fixed(12))
            .foregroundStyle(color(for: segment))
            .cornerRadius(6)
        }
        .chartXScale(domain: 0.0...24.0)
        .chartYScale(domain: days.map(label))
        .chartXAxis {
            AxisMarks(values: [0.0, 6, 12, 18, 24]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let hour = value.as(Double.self) { Text(hourLabel(hour)) }
                }
            }
        }
        .frame(height: CGFloat(dayCount) * 22 + 30)
        .padding(.top, 8)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(.indigo, "In progress")
            legendItem(.green, "Goal met")
            legendItem(.orange, "Short of goal")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func legendItem(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
        }
    }

    private func color(for segment: DaySegment) -> Color {
        if segment.isActive { return .indigo }
        return segment.metGoal ? .green : .orange
    }

    private func label(_ day: Date) -> String {
        day.formatted(.dateTime.weekday(.abbreviated).day())
    }

    private func hourLabel(_ hour: Double) -> String {
        switch Int(hour) {
        case 0, 24: "12a"
        case 12: "12p"
        case let h where h < 12: "\(h)a"
        case let h: "\(h - 12)p"
        }
    }
}

/// Length of each recent fast compared to the goal.
private struct DurationChart: View {
    let fasts: [Fast]
    let goalHours: Double

    var body: some View {
        let recent = Array(fasts.prefix(14).reversed())

        if recent.isEmpty {
            Text("Finish a fast to see it here.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            Chart {
                ForEach(recent) { fast in
                    BarMark(
                        x: .value("Day", fast.start, unit: .day),
                        y: .value("Hours", fast.duration() / 3600))
                    .foregroundStyle(fast.metGoal() ? Color.green.gradient : Color.orange.gradient)
                    .cornerRadius(4)
                }
                RuleMark(y: .value("Goal", goalHours))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary)
                    .annotation(position: .top, alignment: .leading) {
                        Text("Goal \(Format.goal(goalHours))").font(.caption2).foregroundStyle(.secondary)
                    }
            }
            .chartYAxisLabel("hours")
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .frame(height: 220)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Row

private struct FastRow: View {
    let fast: Fast

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(fast.start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.headline)
                Text(timeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if fast.isActive {
                Text("In progress").font(.caption.weight(.semibold)).foregroundStyle(.indigo)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Format.hoursMinutes(fast.duration())).font(.body.monospacedDigit().weight(.semibold))
                    Label(fast.metGoal() ? "Goal met" : "Goal \(Format.goal(fast.goalHours))",
                          systemImage: fast.metGoal() ? "checkmark.circle.fill" : "circle")
                        .font(.caption2)
                        .foregroundStyle(fast.metGoal() ? .green : .secondary)
                }
            }
        }
    }

    private var timeRange: String {
        let start = fast.start.formatted(date: .omitted, time: .shortened)
        guard let end = fast.end else { return "\(start) – now" }
        return "\(start) – \(end.formatted(date: .omitted, time: .shortened))"
    }
}
