import SwiftUI

struct FollowingTopicsView: View {
    @Environment(AppState.self) private var app
    @Environment(SubscriptionStore.self) private var store

    @State private var showsPaywall = false

    private var topicNames: [String] {
        QuoteLibrary.topics.map(\.name)
    }

    var body: some View {
        SheetPage(title: "Topics you follow") {
            VStack(alignment: .leading, spacing: 0) {
                Text("Tap a topic to follow or unfollow. Your For you feed, widgets, and reminders update right away.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.sheetMuted)
                    .lineSpacing(3)
                    .padding(.top, 8)

                if app.followedTopics.isEmpty {
                    Text("You’re not following any topics yet. Pick at least one, or use Follow while browsing in Explore.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.sheetMuted)
                        .lineSpacing(3)
                        .padding(.top, 20)
                }

                FlowLayout(spacing: 10, rowSpacing: 20) {
                    ForEach(topicNames, id: \.self) { name in
                        let selected = app.followedTopics.contains(name)
                        let locked = PremiumAccess.isTopicLocked(name, isPremium: store.isPremium)
                        Button {
                            if locked {
                                showsPaywall = true
                            } else {
                                app.toggleFollowedTopic(name)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: locked ? "lock.fill" : (selected ? "checkmark" : "plus"))
                                    .font(.system(size: 14, weight: .semibold))
                                Text(name)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(TopicChipButtonStyle(selected: selected && !locked))
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 28)
            }
        }
        .fullScreenCover(isPresented: $showsPaywall) {
            PaywallView { showsPaywall = false }
        }
    }
}
