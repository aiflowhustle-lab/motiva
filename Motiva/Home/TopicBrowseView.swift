import SwiftUI

/// Full-screen topic feed from Explore — swipe quotes, Follow, no home chrome.
struct TopicBrowseView: View {
    let topicName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var app
    @Environment(SubscriptionStore.self) private var store

    @State private var showsPaywall = false

    private var theme: FeedTheme { app.theme }
    private var quotes: [String] {
        QuoteLibrary.topics.first(where: { $0.name == topicName })?.quotes ?? []
    }

    private var isFollowing: Bool {
        app.followedTopics.contains(topicName)
    }

    var body: some View {
        ZStack(alignment: .top) {
            theme.background.ignoresSafeArea()

            CircularQuoteFeed(quotes: quotes) { quote in
                app.visit(quote)
            }

            topicHeader
        }
        .foregroundStyle(theme.foreground)
        .preferredColorScheme(theme.isDark ? .dark : .light)
        .fullScreenCover(isPresented: $showsPaywall) {
            PaywallView { showsPaywall = false }
        }
    }

    private var topicHeader: some View {
        VStack(spacing: 0) {
            topicChrome
                .padding(.horizontal, 22)
                .padding(.top, 10)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background {
            theme.background
                .ignoresSafeArea(edges: .top)
        }
    }

    private var topicChrome: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                    Text(topicName)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to topics")

            Button(action: toggleFollow) {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .overlay {
                        Capsule()
                            .strokeBorder(theme.foreground.opacity(isFollowing ? 0.5 : 1), lineWidth: 1.5)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFollowing ? "Unfollow \(topicName)" : "Follow \(topicName)")
            .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.85), trigger: isFollowing)
        }
    }

    private func toggleFollow() {
        let locked = PremiumAccess.isTopicLocked(topicName, isPremium: store.isPremium)
        if locked, !isFollowing {
            showsPaywall = true
            return
        }
        app.toggleFollowedTopic(topicName)
    }
}
