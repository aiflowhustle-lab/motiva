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
    @State private var clampNotice: String?

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
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            favoriteMeter.frame(maxWidth: .infinity)
            if store.shouldShowPremiumChrome {
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
