import SwiftUI

@main
struct MotivaApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var app = AppState()
    @State private var store = SubscriptionStore()

    init() {
        SubscriptionStore.configureRevenueCat()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    HomeView()
                } else {
                    OnboardingView { profile in
                        profile.save()
                        app.applyOnboarding(profile)
                        hasCompletedOnboarding = true
                        Task {
                            await ReminderScheduler.schedule(
                                app.reminders,
                                quotes: QuoteLibrary.quotes(for: app.topic).shuffled()
                            )
                        }
                        WidgetQuoteSync.refresh(topic: app.topic, theme: app.theme)
                    }
                }
            }
            .environment(app)
            .environment(store)
            .task {
                await store.load()
                if hasCompletedOnboarding {
                    WidgetQuoteSync.refresh(topic: app.topic, theme: app.theme)
                }
            }
        }
    }
}
