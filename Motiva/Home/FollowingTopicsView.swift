import SwiftUI

struct FollowingTopicsView: View {
    @Environment(AppState.self) private var app
    @Environment(SubscriptionStore.self) private var store
    var onDone: () -> Void

    @State private var selection: [String] = []
    @State private var showsPaywall = false

    private var topicNames: [String] {
        QuoteLibrary.topics.map(\.name)
    }

    var body: some View {
        SheetPage(title: "Topics you follow") {
            VStack(alignment: .leading, spacing: 0) {
                Text("Your For you feed mixes quotes from the topics you follow. Pick one topic in Explore to focus on it instead.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.sheetMuted)
                    .lineSpacing(3)
                    .padding(.top, 8)

                FlowLayout(spacing: 10, rowSpacing: 20) {
                    ForEach(topicNames, id: \.self) { name in
                        let selected = selection.contains(name)
                        let locked = PremiumAccess.isTopicLocked(name, isPremium: store.isPremium)
                        Button {
                            if locked {
                                showsPaywall = true
                            } else {
                                toggle(name)
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

                Button("Save") { save() }
                    .buttonStyle(.primary)
                    .padding(.top, 32)
                    .disabled(selection.isEmpty)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { SheetCloseButton(action: onDone) }
        }
        .onAppear {
            selection = app.followedTopics.filter { topicNames.contains($0) }
            if selection.isEmpty {
                selection = backfillFromOnboarding()
            }
            if selection.isEmpty {
                selection = ["Motivation"]
            }
        }
        .fullScreenCover(isPresented: $showsPaywall) {
            PaywallView { showsPaywall = false }
        }
    }

    private func toggle(_ name: String) {
        if let index = selection.firstIndex(of: name) {
            selection.remove(at: index)
        } else {
            selection.append(name)
        }
    }

    private func save() {
        var saved = selection.filter { topicNames.contains($0) }
        if saved.isEmpty { saved = ["Motivation"] }
        app.followedTopics = saved
        Task { await app.rescheduleReminders() }
        onDone()
    }

    private func backfillFromOnboarding() -> [String] {
        guard let profile = OnboardingProfile.load(),
              let picked = profile.answers[OnboardingStep.topics.rawValue] else { return [] }
        let allowed = Set(topicNames)
        return picked.filter { allowed.contains($0) }
    }
}
