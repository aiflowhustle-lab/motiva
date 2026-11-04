import SwiftUI

struct SheetCloseButton: View {
    @Environment(\.dismiss) private var dismiss
    var action: (() -> Void)?

    var body: some View {
        Button {
            if let action { action() } else { dismiss() }
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityLabel("Close")
    }
}

/// Light grey sheet chrome shared by Topics, Profile and Wallpapers.
struct SheetPage<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 16)
                .padding(.bottom, 50)
        }
        .background(Color.sheetBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .foregroundStyle(Color.motivaForeground)
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 23, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 34)
            .padding(.bottom, 18)
    }
}

struct UnlockBanner: View {
    var title = "Unlock all"
    var message = "Unlock every topic, theme, and the full quote library."
    var symbol = "lock.open"

    @Environment(SubscriptionStore.self) private var store
    @State private var showsPaywall = false

    var body: some View {
        if store.shouldShowPremiumChrome { banner }
    }

    private var banner: some View {
        Button { showsPaywall = true } label: {
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(title).font(.system(size: 23, weight: .bold))
                    Text(message)
                        .font(.system(size: 15))
                        .opacity(0.65)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: symbol)
                    .font(.system(size: 50, weight: .ultraLight))
                    .frame(width: 70)
            }
            .multilineTextAlignment(.leading)
            .foregroundStyle(.white)
            .padding(.horizontal, 23)
            .padding(.vertical, 29)
            .frame(minHeight: 132)
            .background(
                RadialGradient(colors: [Color(hex: 0x4F4C45), Color(hex: 0x262626)], center: .center, startRadius: 0, endRadius: 220),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .fullScreenCover(isPresented: $showsPaywall) {
            PaywallView { showsPaywall = false }
        }
    }
}

struct PaywallView: View {
    var onClose: () -> Void
    @Environment(SubscriptionStore.self) private var store
    @State private var trialReminder = false

    var body: some View {
        TrialOfferScreen(trialReminder: $trialReminder, onClose: onClose)
            .padding(.horizontal, Metrics.screenPadding)
            .foregroundStyle(Color.motivaForeground)
            .background(Color.motivaBackground.ignoresSafeArea())
            .environment(\.colorScheme, .light)
            .task {
                await store.refreshEntitlements()
                if store.isPremium { onClose() }
            }
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .pressHaptic(.impact(weight: .light), isPressed: configuration.isPressed)
    }
}

/// White rounded card used for the grid tiles and topic rows.
struct CardButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 28

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.motivaForeground)
            .background(
                configuration.isPressed ? Color.sheetFill : Color.white,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .shadow(color: .black.opacity(0.035), radius: 5, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .pressHaptic(.impact(weight: .light), isPressed: configuration.isPressed)
    }
}

struct StreakWeek: View {
    let count: Int
    var foreground: Color = .motivaForeground
    var muted: Color = .sheetMuted
    var fillContrast: Color = .white

    private var completedIndex: Int { max(count - 1, 0) % 7 }

    private var days: [String] {
        let calendar = Calendar.current
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let today = calendar.component(.weekday, from: .now) - 1
        let start = today - completedIndex
        return (0..<7).map { String(symbols[((start + $0) % 7 + 7) % 7].prefix(2)) }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            StreakFlameBadge(count: count, foreground: foreground)
                .frame(width: 62, alignment: .center)

            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    let complete = count > 0 && index <= completedIndex
                    VStack(spacing: 8) {
                        Text(day)
                            .font(.system(size: 13))
                            .foregroundStyle(index == completedIndex ? foreground : muted)
                        ZStack {
                            if complete {
                                Circle().fill(foreground)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(fillContrast)
                            } else {
                                Circle().strokeBorder(Color(hex: 0xC7C7C7), lineWidth: 1.5)
                            }
                        }
                        .frame(width: 29, height: 29)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
        }
        .foregroundStyle(foreground)
    }
}

// MARK: - Quote feed (home + topic browse)

struct CircularQuoteFeed: View {
    let quotes: [String]
    let onQuoteShown: (String) -> Void

    @State private var pageIndex: Int?
    @State private var lastReportedIndex: Int?

    var body: some View {
        Group {
            if quotes.isEmpty {
                Color.clear
            } else {
                GeometryReader { geometry in
                    let pageHeight = geometry.size.height
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(quotes.enumerated()), id: \.offset) { index, quote in
                                QuotePage(quote: quote)
                                    .frame(width: geometry.size.width, height: pageHeight)
                                    .id(index)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollIndicators(.hidden)
                    .scrollPosition(id: $pageIndex, anchor: .top)
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            if pageIndex == nil { pageIndex = 0 }
            reportQuoteIfNeeded()
        }
        .onChange(of: quotes) { _, _ in
            pageIndex = 0
            lastReportedIndex = nil
            reportQuoteIfNeeded()
        }
        .onChange(of: pageIndex) { _, _ in
            reportQuoteIfNeeded()
        }
        .sensoryFeedback(.selection, trigger: pageIndex)
    }

    private func reportQuoteIfNeeded() {
        guard let index = pageIndex, quotes.indices.contains(index) else { return }
        guard index != lastReportedIndex else { return }
        lastReportedIndex = index
        onQuoteShown(quotes[index])
    }
}

struct QuotePage: View {
    @Environment(AppState.self) private var app
    let quote: String

    @State private var burst = false
    @State private var shareImage: UIImage?
    @State private var showsShareSheet = false

    private var liked: Bool { app.isFavorite(quote) }
    private var shareText: String { quote.replacingOccurrences(of: "\n", with: " ") }

    var body: some View {
        VStack(spacing: 64) {
            Text(quote)
                .font(.custom("BricolageGrotesque-SemiBold", size: 28))
                .lineSpacing(10)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)

            HStack(spacing: 44) {
                Button {
                    shareImage = QuoteShareRenderer.image(for: quote)
                    showsShareSheet = shareImage != nil
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 30, weight: .light))
                        .frame(width: 58, height: 58)
                }
                .accessibilityLabel("Share quote")
                .sheet(isPresented: $showsShareSheet) {
                    if let shareImage {
                        ActivityShareSheet(items: [shareImage, shareText])
                            .presentationDetents([.medium, .large])
                    }
                }

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
