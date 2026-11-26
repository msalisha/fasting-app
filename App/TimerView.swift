import SwiftUI
import FastingCore

struct TimerView: View {
    @Environment(FastingModel.self) private var model
    @State private var editing: Fast?
    @State private var showingStartEarlier = false

    private let goalOptions: [Double] = [12, 13, 14, 15, 16, 18, 20, 24, 36, 48, 72]

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                // Only the clock and ring tick every second; the buttons and sheets stay put.
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(spacing: 28) {
                        Spacer(minLength: 0)
                        ring(now: context.date)
                        details(now: context.date)
                        Spacer(minLength: 0)
                    }
                }
                actions
            }
            .padding()
            .navigationTitle(model.activeFast == nil ? "Not fasting" : "Fasting")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { goalMenu }
            }
            .sheet(item: $editing) { fast in
                FastEditor(fast: fast)
                    .environment(model)
            }
            .sheet(isPresented: $showingStartEarlier) {
                StartEarlierSheet()
                    .environment(model)
            }
        }
    }

    // MARK: Ring

    @ViewBuilder
    private func ring(now: Date) -> some View {
        let fast = model.activeFast
        let progress = fast?.progress(at: now) ?? 0
        let met = fast?.metGoal(at: now) ?? false

        ZStack {
            ProgressRing(progress: progress, lineWidth: 22, colors: met ? [.green, .mint] : [.indigo, .purple, .pink])
            VStack(spacing: 6) {
                if let fast {
                    Text(met ? "Goal reached" : "Elapsed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(Format.clock(fast.duration(at: now)))
                        .font(.system(size: 46, weight: .bold, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText())
                    if !met {
                        Text("\(Format.hoursMinutes(fast.goalEnd.timeIntervalSince(now))) to go")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } else {
                        Text("+\(Format.hoursMinutes(now.timeIntervalSince(fast.goalEnd)))")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.green)
                    }
                } else if let last = model.completedFasts.first, let end = last.end {
                    Text("Eating for")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(Format.clock(now.timeIntervalSince(end)))
                        .font(.system(size: 46, weight: .bold, design: .rounded).monospacedDigit())
                    Text("Last fast \(Format.hoursMinutes(last.duration()))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("Ready when you are")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(.horizontal, 24)
    }

    // MARK: Details

    @ViewBuilder
    private func details(now: Date) -> some View {
        if let fast = model.activeFast {
            HStack {
                infoTile(title: "Started", value: fast.start.formatted(date: .omitted, time: .shortened),
                         subtitle: fast.start.formatted(.dateTime.weekday(.wide)))
                Divider().frame(height: 40)
                infoTile(title: "Goal \(Format.goal(fast.goalHours))", value: fast.goalEnd.formatted(date: .omitted, time: .shortened),
                         subtitle: fast.goalEnd.formatted(.dateTime.weekday(.wide)))
            }
            .padding()
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
            .onTapGesture { editing = fast }
        }
    }

    private func infoTile(title: String, value: String, subtitle: String) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.semibold))
            Text(subtitle).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Actions

    @ViewBuilder
    private var actions: some View {
        if let fast = model.activeFast {
            VStack(spacing: 12) {
                Button(role: .destructive) {
                    withAnimation { model.end() }
                } label: {
                    Label("End fast", systemImage: "stop.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.pink)

                Button("Edit start time") { editing = fast }
                    .font(.subheadline)
            }
        } else {
            VStack(spacing: 12) {
                Button {
                    withAnimation { model.start() }
                } label: {
                    Label("Start fast", systemImage: "play.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.indigo)

                Button("I started earlier…") { showingStartEarlier = true }
                    .font(.subheadline)
            }
        }
    }

    private var goalMenu: some View {
        Menu {
            Picker("Goal", selection: Binding(get: { model.goalHours }, set: { model.setGoal($0) })) {
                ForEach(goalOptions, id: \.self) { hours in
                    Text("\(Format.goal(hours)) fast").tag(hours)
                }
            }
        } label: {
            Label("Goal \(Format.goal(model.goalHours))", systemImage: "target")
                .labelStyle(.titleAndIcon)
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

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat
    var colors: [Color]

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    AngularGradient(colors: colors + [colors.first ?? .accentColor], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
