import Foundation

/// What free users can use without Motiva Premium.
enum PremiumAccess {
    static let freeThemes: Set<FeedTheme> = [.classic]
    static let freeTopicNames: Set<String> = ["Featured", "Feeling sassy", "Self-esteem", "Motivation"]

    static func canUse(theme: FeedTheme, isPremium: Bool) -> Bool {
        isPremium || freeThemes.contains(theme)
    }

    static func canUse(topicName: String?, isPremium: Bool) -> Bool {
        guard let topicName else { return true }
        return isPremium || freeTopicNames.contains(topicName)
    }

    static func isTopicLocked(_ name: String, isPremium: Bool) -> Bool {
        !canUse(topicName: name, isPremium: isPremium)
    }

    static func isThemeLocked(_ theme: FeedTheme, isPremium: Bool) -> Bool {
        !canUse(theme: theme, isPremium: isPremium)
    }

    /// Keeps selections valid when a subscription ends. Returns topic names removed from follows.
    @discardableResult
    static func clampSelection(app: AppState, isPremium: Bool) -> [String] {
        if !canUse(theme: app.theme, isPremium: isPremium) {
            app.theme = .classic
        }
        if !canUse(theme: app.widgetTheme, isPremium: isPremium) {
            app.widgetTheme = .classic
        }
        if !canUse(topicName: app.topic, isPremium: isPremium) {
            app.topic = nil
        }
        let before = app.followedTopics
        let allowed = before.filter { canUse(topicName: $0, isPremium: isPremium) }
        if allowed != before {
            app.followedTopics = allowed
        }
        return before.filter { !allowed.contains($0) }
    }
}
