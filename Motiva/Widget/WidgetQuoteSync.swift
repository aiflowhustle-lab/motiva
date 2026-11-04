import WidgetKit

enum WidgetQuoteSync {
    /// Widget pool follows **followed topics** (or For you), not the ephemeral home topic filter.
    static func refresh(followedTopics: [String] = [], theme: FeedTheme) {
        let quotes = Array(QuoteLibrary.quotes(for: nil, followedTopics: followedTopics).shuffled().prefix(48))
        guard !quotes.isEmpty else { return }
        WidgetSharedStore.save(
            WidgetSnapshot(quotes: quotes, theme: theme.rawValue, updatedAt: .now)
        )
        WidgetCenter.shared.reloadAllTimelines()
    }
}
