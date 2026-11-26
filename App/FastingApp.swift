import SwiftUI

@main
struct FastingApp: App {
    @State private var model = FastingModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                // The widget/control may have changed the data while we were in the background.
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { model.reload() }
                }
                .onOpenURL { _ in model.reload() }
        }
    }
}

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        TabView {
            Tab("Today", systemImage: "circle.dotted") {
                TodayView()
            }
            Tab("History", systemImage: "chart.bar") {
                HistoryView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .tint(Theme.accent)
        .fullScreenCover(isPresented: Binding(get: { !hasCompletedOnboarding }, set: { _ in })) {
            OnboardingView { hasCompletedOnboarding = true }
        }
    }
}
