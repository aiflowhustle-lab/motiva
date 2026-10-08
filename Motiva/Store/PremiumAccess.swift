import Foundation

/// What free users can use without Motiva Premium.
enum PremiumAccess {
    static let freeThemes: Set<FeedTheme> = [.classic]
    static let freeTopicNames: Set<String> = ["Feeling sassy", "Self-respect", "Motivation"]

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

    /// Keeps selections valid when a subscription ends.
    static func clampSelection(app: AppState, isPremium: Bool) {
        if !canUse(theme: app.theme, isPremium: isPremium) {
            app.theme = .classic
        }
        if !canUse(topicName: app.topic, isPremium: isPremium) {
            app.topic = nil
        }
    }
}
