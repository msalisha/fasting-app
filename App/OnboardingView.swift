import SwiftUI
import FastingCore

/// Shown once on first launch.
struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0

    private struct Page {
        let symbol: String
        let title: String
        let text: String
    }

    private let pages = [
        Page(symbol: "leaf", title: "Fasting, kept simple",
             text: "Pick a goal, tap start, and Stillfast keeps time. End your fast whenever you're ready."),
        Page(symbol: "lock.iphone", title: "Always in view",
             text: "Add the Stillfast widget to your Lock Screen to see your fast at a glance, and start or stop with one tap."),
        Page(symbol: "heart.text.square", title: "A note on health",
             text: FastingStage.disclaimer),
    ]

    var body: some View {
        VStack(spacing: Theme.Space.l) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index]).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    onFinish()
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Get started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, Theme.Space.l)
            .padding(.bottom, Theme.Space.l)
        }
        .tint(Theme.accent)
        .background(Theme.background)
        .interactiveDismissDisabled()
    }

    private func pageView(_ page: Page) -> some View {
        ScrollView {
            VStack(spacing: Theme.Space.m) {
                Image(systemName: page.symbol)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 80)
                    .padding(.bottom, Theme.Space.s)
                    .accessibilityHidden(true)
                Text(page.title)
                    .font(.title.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(page.text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Space.xl)
            .padding(.bottom, 60)
        }
    }
}
