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
    @AppStorage(AccentTheme.storageKey, store: AppGroup.defaults) private var accentTheme = AccentTheme.sage.rawValue
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system.rawValue
    @State private var tab = AppTab.today

    enum AppTab: Hashable {
        case today, history, settings
    }

    var body: some View {
        TabView(selection: $tab) {
            Tab("Today", systemImage: "circle.dotted", value: AppTab.today) {
                TodayView()
            }
            Tab("History", systemImage: "chart.bar", value: AppTab.history) {
                HistoryView()
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                SettingsView()
            }
        }
        // Rebuild every screen when the colour scheme changes, so they all pick up the new accent.
        .id(accentTheme)
        .tint(Theme.accent)
        .preferredColorScheme(AppAppearance(rawValue: appearance)?.colorScheme)
        .fullScreenCover(isPresented: Binding(get: { !hasCompletedOnboarding }, set: { _ in })) {
            OnboardingView { hasCompletedOnboarding = true }
        }
    }
}
