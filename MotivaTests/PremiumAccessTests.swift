import Testing
@testable import Motiva

struct PremiumAccessTests {
    @Test func freeTopicsAndClassicTheme() {
        #expect(PremiumAccess.canUse(topicName: nil, isPremium: false))
        #expect(PremiumAccess.canUse(topicName: "Motivation", isPremium: false))
        #expect(!PremiumAccess.canUse(topicName: "Confidence", isPremium: false))
        #expect(PremiumAccess.canUse(theme: .classic, isPremium: false))
        #expect(!PremiumAccess.canUse(theme: .paper, isPremium: false))
    }

    @Test func premiumUnlocksEverything() {
        #expect(PremiumAccess.canUse(topicName: "Confidence", isPremium: true))
        #expect(PremiumAccess.canUse(theme: .forest, isPremium: true))
    }

    @Test func clampResetsLockedSelections() {
        let app = AppState()
        app.topic = "Confidence"
        app.theme = .paper
        PremiumAccess.clampSelection(app: app, isPremium: false)
        #expect(app.topic == nil)
        #expect(app.theme == .classic)
    }
}
