import SwiftUI

enum HomeSheet: String, Identifiable {
    case topics, wallpapers, profile
    var id: String { rawValue }
}

struct HomeView: View {
    @Environment(AppState.self) private var app
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    @State private var sheet: HomeSheet?
    @State private var showsPaywall = false
    @State private var showsStreak = false

    private static let favoriteGoal = 5

    private var quotes: [String] { app.feedQuotes() }
    private var theme: FeedTheme { app.theme }
    private var feedIdentity: String {
        let topicKey = app.topic ?? "forYou"
        let followKey = app.followedTopics.joined(separator: "|")
        return "\(topicKey)::\(followKey)"
    }

    var body: some View {
        ZStack(alignment: .top) {
            theme.background.ignoresSafeArea()

            CircularQuoteFeed(quotes: quotes) { quote in
                app.visit(quote)
            }
            .id(feedIdentity)

            VStack {
                topBar
                Spacer()
                bottomBar
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 8)

            if showsStreak {
                streakToast
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .foregroundStyle(theme.foreground)
        .animation(.easeInOut(duration: 0.3), value: theme)
        .preferredColorScheme(theme.isDark ? .dark : .light)
        .sheet(item: $sheet) { sheet in
            NavigationStack {
                switch sheet {
                case .topics: TopicsView { self.sheet = nil }
                case .wallpapers: WallpapersView { self.sheet = nil }
                case .profile: ProfileView { self.sheet = nil }
                }
            }
            .tint(Color.motivaForeground)
            .preferredColorScheme(.light)
        }
        .fullScreenCover(isPresented: $showsPaywall) {
            PaywallView { showsPaywall = false }
        }
        .onAppear {
            registerOpen()
            PremiumAccess.clampSelection(app: app, isPremium: store.isPremium)
            Task { await store.refreshEntitlements() }
            #if DEBUG
            // Launch with `-homeSheet topics|wallpapers|profile` to open a sheet directly.
            if let raw = UserDefaults.standard.string(forKey: "homeSheet") { sheet = HomeSheet(rawValue: raw) }
            #endif
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                registerOpen()
                Task { await store.refreshEntitlements() }
            }
        }
        .onChange(of: store.isPremium) { _, isPremium in
            PremiumAccess.clampSelection(app: app, isPremium: isPremium)
            Task { await app.rescheduleReminders() }
        }
        .onChange(of: app.topic) { _, _ in
            Task { await app.rescheduleReminders() }
        }
        .onChange(of: app.followedTopics) { _, _ in
            Task { await app.rescheduleReminders() }
        }
        .onChange(of: app.theme) { _, _ in
            WidgetQuoteSync.refresh(
                topic: app.topic,
                followedTopics: app.followedTopics,
                theme: app.theme
            )
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            favoriteMeter.frame(maxWidth: .infinity)
            if !store.isPremium {
                FeedIconButton(symbol: "crown", label: "Premium", background: theme.control) {
                    showsPaywall = true
                }
            }
        }
    }

    private var favoriteMeter: some View {
        let count = min(app.favorites.count, Self.favoriteGoal)
        return HStack(spacing: 11) {
            Image(systemName: count > 0 ? "heart.fill" : "heart")
                .font(.system(size: 19, weight: .light))
                .contentTransition(.symbolEffect(.replace))
            Text("\(count)/\(Self.favoriteGoal)")
                .font(.system(size: 18))
                .monospacedDigit()
                .contentTransition(.numericText())
            Capsule()
                .fill(theme.track)
                .frame(width: 110, height: 7)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(theme.foreground)
                        .frame(width: 110 * CGFloat(count) / CGFloat(Self.favoriteGoal))
                }
                .clipShape(Capsule())
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 9)
        .background(theme.pill, in: Capsule())
        .animation(.spring(duration: 0.4), value: count)
        .accessibilityElement()
        .accessibilityLabel("\(count) of \(Self.favoriteGoal) quotes favorited")
    }

    private var bottomBar: some View {
        HStack {
            FeedIconButton(symbol: "square.grid.2x2", label: "Explore topics", background: theme.control) { sheet = .topics }
            Spacer()
            HStack(spacing: 20) {
                FeedIconButton(symbol: "paintbrush.pointed", label: "Wallpapers", background: theme.control) { sheet = .wallpapers }
                FeedIconButton(symbol: "person", label: "Profile", background: theme.control) { sheet = .profile }
            }
        }
    }

    private var streakToast: some View {
        VStack(spacing: 22) {
            Text(app.streakCount <= 1 ? "New daily streak started" : "You’re on a \(app.streakCount)-day streak")
                .font(.system(size: 23, weight: .bold))
                .multilineTextAlignment(.center)
            StreakWeek(count: app.streakCount)
        }
        .foregroundStyle(Color.motivaForeground)
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .onTapGesture { dismissStreak() }
        .task {
            try? await Task.sleep(for: .seconds(4.8))
            dismissStreak()
        }
    }

    private func registerOpen() {
        guard app.registerOpen() else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) { showsStreak = true }
        }
    }

    private func dismissStreak() {
        withAnimation(.easeInOut(duration: 0.3)) { showsStreak = false }
    }
}

/// Fixed-size paging window so the feed stays infinite without materializing tens of thousands of pages.
private struct CircularQuoteFeed: View {
    let quotes: [String]
    let onQuoteShown: (String) -> Void

    private static let window = 5
    private static let center = window / 2

    @State private var page: Int?
    @State private var anchorIndex = 0

    var body: some View {
        Group {
            if quotes.isEmpty {
                Color.clear
            } else {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<Self.window, id: \.self) { pageIndex in
                            QuotePage(quote: quote(at: pageIndex))
                                .containerRelativeFrame([.horizontal, .vertical])
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $page)
                .scrollIndicators(.hidden)
                .ignoresSafeArea()
            }
        }
        .onAppear {
            page = Self.center
            onQuoteShown(quotes[anchorIndex])
        }
        .onChange(of: quotes) { _, newQuotes in
            anchorIndex = 0
            page = Self.center
            if let first = newQuotes.first {
                onQuoteShown(first)
            }
        }
        .onChange(of: page) { _, newPage in
            guard let newPage, !quotes.isEmpty else { return }
            let delta = newPage - Self.center
            guard delta != 0 else { return }

            let count = quotes.count
            anchorIndex = (anchorIndex + delta % count + count) % count
            onQuoteShown(quotes[anchorIndex])

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                page = Self.center
            }
        }
    }

    private func quote(at pageIndex: Int) -> String {
        let count = quotes.count
        guard count > 0 else { return "" }
        let offset = pageIndex - Self.center
        let index = (anchorIndex + offset % count + count) % count
        return quotes[index]
    }
}

private struct QuotePage: View {
    @Environment(AppState.self) private var app
    let quote: String

    @State private var burst = false

    private var liked: Bool { app.isFavorite(quote) }
    private var shareText: String { quote.replacingOccurrences(of: "\n", with: " ") }

    var body: some View {
        VStack(spacing: 64) {
            Text(quote)
                .font(.system(size: 28))
                .lineSpacing(10)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)

            HStack(spacing: 44) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 30, weight: .light))
                        .frame(width: 58, height: 58)
                }
                .accessibilityLabel("Share quote")

                Button {
                    app.toggleFavorite(quote)
                } label: {
                    Image(systemName: liked ? "heart.fill" : "heart")
                        .font(.system(size: 31, weight: .light))
                        .contentTransition(.symbolEffect(.replace))
                        .symbolEffect(.bounce, value: liked)
                        .frame(width: 58, height: 58)
                }
                .accessibilityLabel(liked ? "Unfavorite quote" : "Favorite quote")
                .sensoryFeedback(.impact(weight: .medium), trigger: liked)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .offset(y: 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if !liked { app.toggleFavorite(quote) }
            burst = true
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: burst) { _, active in active }
        .overlay {
            Image(systemName: "heart.fill")
                .font(.system(size: 110))
                .scaleEffect(burst ? 1 : 0.4)
                .opacity(burst ? 0.9 : 0)
                .allowsHitTesting(false)
                .animation(.spring(duration: 0.35, bounce: 0.5), value: burst)
                .task(id: burst) {
                    guard burst else { return }
                    try? await Task.sleep(for: .milliseconds(650))
                    burst = false
                }
        }
    }
}

private struct FeedIconButton: View {
    let symbol: String
    let label: String
    let background: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .light))
                .frame(width: 58, height: 58)
                .background(background, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(label)
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .environment(SubscriptionStore())
}
