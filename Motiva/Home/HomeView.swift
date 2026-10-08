import SwiftUI

enum HomeSheet: String, Identifiable {
    case topics, wallpapers, profile
    var id: String { rawValue }
}

struct HomeView: View {
    @Environment(AppState.self) private var app
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    @State private var page: Int? = 0
    @State private var sheet: HomeSheet?
    @State private var showsPaywall = false
    @State private var showsStreak = false

    private static let favoriteGoal = 5
    private static let loops = 200

    private var quotes: [String] { QuoteLibrary.quotes(for: app.topic) }
    private var theme: FeedTheme { app.theme }
    private var currentQuote: String { quotes[(page ?? 0) % quotes.count] }

    var body: some View {
        ZStack(alignment: .top) {
            theme.background.ignoresSafeArea()

            feed
                .id(app.topic ?? "")

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
            app.visit(currentQuote)
            registerOpen()
            #if DEBUG
            // Launch with `-homeSheet topics|wallpapers|profile` to open a sheet directly.
            if let raw = UserDefaults.standard.string(forKey: "homeSheet") { sheet = HomeSheet(rawValue: raw) }
            #endif
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { registerOpen() }
        }
        .onChange(of: page) { app.visit(currentQuote) }
        .onChange(of: app.topic) { page = 0 }
    }

    private var feed: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(0..<(quotes.count * Self.loops)), id: \.self) { index in
                    QuotePage(quote: quotes[index % quotes.count])
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
                .sensoryFeedback(.impact(weight: .light), trigger: liked)
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
