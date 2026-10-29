import WidgetKit

enum WidgetQuoteSync {
    static func refresh(topic: String?, followedTopics: [String] = [], theme: FeedTheme) {
        let quotes = Array(QuoteLibrary.quotes(for: topic, followedTopics: followedTopics).shuffled().prefix(48))
        guard !quotes.isEmpty else { return }
        WidgetSharedStore.save(
            WidgetSnapshot(quotes: quotes, theme: theme.rawValue, updatedAt: .now)
        )
        WidgetCenter.shared.reloadAllTimelines()
    }
}
