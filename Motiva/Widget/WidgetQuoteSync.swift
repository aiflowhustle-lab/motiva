import WidgetKit

enum WidgetQuoteSync {
    static func refresh(
        followedTopics: [String] = [],
        widgetTheme: FeedTheme,
        topicMode: WidgetTopicMode,
        refresh: WidgetRefreshInterval
    ) {
        let pool = quotes(followedTopics: followedTopics, topicMode: topicMode)
        let quotes = Array(pool.shuffled().prefix(48))
        guard !quotes.isEmpty else { return }
        WidgetSharedStore.save(
            WidgetSnapshot(
                quotes: quotes,
                theme: widgetTheme.rawValue,
                refresh: refresh.rawValue,
                updatedAt: .now
            )
        )
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func quotes(followedTopics: [String], topicMode: WidgetTopicMode) -> [String] {
        switch topicMode {
        case .mix:
            return QuoteLibrary.quotes(for: nil, followedTopics: followedTopics)
        case .forYou:
            return QuoteLibrary.quotes(for: nil, followedTopics: [])
        }
    }
}
