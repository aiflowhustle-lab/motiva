import SwiftUI

enum HomeSheet: String, Identifiable {
    case topics, wallpapers, profile, favorites
    var id: String { rawValue }
}

struct HomeView: View {
    @Environment(AppState.self) private var app
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    @State private var sheet: HomeSheet?
    @State private var showsPaywall = false
    @State private var showsStreak = false
    @State private var showsFavoriteCelebration = false
    @State private var clampNotice: String?

    private var quotes: [String] { app.feedQuotes() }
    private var theme: FeedTheme { app.theme }
    private var feedIdentity: String {
        let topicKey = app.topic ?? "forYou"
        let followKey = app.followedTopics.joined(separator: "|")
        return "\(topicKey)::\(followKey)"
    }

    private var showsFavoriteProgress: Bool {
        app.favorites.count < AppState.favoriteGoal
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

            if showsFavoriteCelebration {
                favoriteCelebrationToast
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .foregroundStyle(theme.foreground)
        .animation(.easeInOut(duration: 0.3), value: theme)
        .animation(.easeInOut(duration: 0.25), value: showsFavoriteProgress)
        .preferredColorScheme(theme.isDark ? .dark : .light)
        .sheet(item: $sheet) { sheet in
            NavigationStack {
                switch sheet {
                case .topics: TopicsView { self.sheet = nil }
                case .wallpapers: WallpapersView { self.sheet = nil }
                case .profile: ProfileView { self.sheet = nil }
                case .favorites:
                    SavedQuotesView(list: .favorites)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                SheetCloseButton { self.sheet = nil }
                            }
                        }
                }
            }
            .tint(Color.motivaForeground)
            .preferredColorScheme(.light)
        }
        .fullScreenCover(isPresented: $showsPaywall) {
            PaywallView { showsPaywall = false }
        }
        .alert("Follows updated", isPresented: Binding(
            get: { clampNotice != nil },
            set: { if !$0 { clampNotice = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(clampNotice ?? "")
        }
        .onAppear {
            registerOpen()
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
            applyPremiumClamp(isPremium: isPremium)
            Task { await app.rescheduleReminders() }
        }
        .onChange(of: app.followedTopics) { _, _ in
            Task { await app.rescheduleReminders() }
        }
        .onChange(of: app.theme) { _, _ in
            WidgetQuoteSync.refresh(followedTopics: app.followedTopics, theme: app.theme)
        }
        .onChange(of: app.favorites.count) { oldCount, newCount in
            guard newCount >= AppState.favoriteGoal, oldCount < AppState.favoriteGoal else { return }
            guard !app.celebratedFavoriteGoal else { return }
            app.celebratedFavoriteGoal = true
            presentFavoriteCelebration()
        }
        .sensoryFeedback(.success, trigger: showsFavoriteCelebration)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Group {
                if showsFavoriteProgress {
                    favoriteProgressMeter
                } else {
                    favoritesShortcut
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if store.shouldShowPremiumChrome {
                FeedIconButton(symbol: "crown", label: "Premium", background: theme.control) {
                    showsPaywall = true
                }
            }
        }
    }

    private var favoriteProgressMeter: some View {
        let count = app.favorites.count
        return HStack(spacing: 11) {
            Image(systemName: count > 0 ? "heart.fill" : "heart")
                .font(.system(size: 19, weight: .light))
                .contentTransition(.symbolEffect(.replace))
            Text("\(count)/\(AppState.favoriteGoal)")
                .font(.system(size: 18))
                .monospacedDigit()
                .contentTransition(.numericText())
            Capsule()
                .fill(theme.track)
                .frame(width: 110, height: 7)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(theme.foreground)
                        .frame(width: 110 * CGFloat(count) / CGFloat(AppState.favoriteGoal))
                }
                .clipShape(Capsule())
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 9)
        .background(theme.pill, in: Capsule())
        .animation(.spring(duration: 0.4), value: count)
        .accessibilityElement()
        .accessibilityLabel("\(count) of \(AppState.favoriteGoal) quotes saved")
    }

    private var favoritesShortcut: some View {
        Button {
            sheet = .favorites
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 19, weight: .light))
                Text("\(app.favorites.count)")
                    .font(.system(size: 18))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 17)
            .padding(.vertical, 9)
            .background(theme.pill, in: Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("\(app.favorites.count) saved quotes, open favorites")
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

    private var favoriteCelebrationToast: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 36, weight: .light))
            Text("Five saved")
                .font(.system(size: 23, weight: .bold))
            Text("Open Favorites anytime from the heart at the top.")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.sheetMuted)
        }
        .foregroundStyle(Color.motivaForeground)
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .onTapGesture { dismissFavoriteCelebration() }
        .task {
            try? await Task.sleep(for: .seconds(4.8))
            dismissFavoriteCelebration()
        }
    }

    private func applyPremiumClamp(isPremium: Bool) {
        let removed = PremiumAccess.clampSelection(app: app, isPremium: isPremium)
        guard !removed.isEmpty else { return }
        let names = removed.joined(separator: ", ")
        clampNotice = "These topics need Motiva Premium to follow: \(names). They were removed from your follows."
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

    private func presentFavoriteCelebration() {
        Task {
            if showsStreak {
                try? await Task.sleep(for: .seconds(5))
            } else {
                try? await Task.sleep(for: .milliseconds(500))
            }
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) { showsFavoriteCelebration = true }
        }
    }

    private func dismissFavoriteCelebration() {
        withAnimation(.easeInOut(duration: 0.3)) { showsFavoriteCelebration = false }
    }
}

/// Full-screen vertical paging — one quote per screen, system snap (no 3-page recycle glitch).
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
