import SwiftUI

struct WidgetSettingsView: View {
    @Environment(AppState.self) private var app
    @Environment(SubscriptionStore.self) private var store

    @State private var previewSize: WidgetPreviewSize = .medium
    @State private var showsPaywall = false

    private var previewQuote: String {
        let pool = WidgetQuoteSync.quotes(followedTopics: app.followedTopics, topicMode: app.widgetTopicMode)
        return pool.first ?? "Make room\nfor yourself."
    }

    var body: some View {
        SheetPage(title: "Widgets") {
            VStack(alignment: .leading, spacing: 0) {
                Text("Set up your Home Screen widget")
                    .font(.system(size: 23, weight: .bold))
                    .padding(.top, 8)

                widgetPreview
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22)

                sizePicker
                    .padding(.top, 20)

                sectionLabel("Theme")
                themePicker
                    .padding(.top, 12)

                settingsRow(title: "Topics", value: app.widgetTopicMode.displayName) {
                    WidgetTopicModePicker()
                }
                .padding(.top, 24)

                settingsRow(title: "Refresh", value: app.widgetRefresh.displayName) {
                    WidgetRefreshPicker()
                }
                .padding(.top, 12)

                Text("Your widget reflects the settings you select here — independent of the in-app wallpaper.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.sheetMuted)
                    .lineSpacing(3)
                    .padding(.top, 28)
            }
        }
        .fullScreenCover(isPresented: $showsPaywall) {
            PaywallView { showsPaywall = false }
        }
    }

    private var widgetPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color(hex: 0xECECEC))
                .frame(height: previewSize.previewSize.height + 80)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.black.opacity(0.85))
                        .frame(width: 72, height: 22)
                        .padding(.top, 14)
                }

            widgetPreviewCard
                .padding(.top, 36)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Widget preview")
    }

    private var widgetPreviewCard: some View {
        let theme = app.widgetTheme
        let size = previewSize.previewSize
        return Text(previewQuote)
            .font(.custom("BricolageGrotesque-SemiBold", size: previewSize == .small ? 14 : 16))
            .foregroundStyle(theme.foreground)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .minimumScaleFactor(0.75)
            .padding(14)
            .frame(width: size.width, height: size.height)
            .background(theme.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var sizePicker: some View {
        HStack(spacing: 10) {
            ForEach(WidgetPreviewSize.allCases) { size in
                let selected = previewSize == size
                Button {
                    previewSize = size
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selected ? "checkmark" : "plus")
                            .font(.system(size: 13, weight: .semibold))
                        Text(size.label)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(selected ? Color(hex: 0xE4E4E4) : Color.white, in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(Color(hex: 0xD0D0D0), lineWidth: selected ? 0 : 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17))
            .foregroundStyle(Color.sheetMuted)
            .padding(.top, 26)
    }

    private var themePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FeedTheme.allCases) { theme in
                    let selected = app.widgetTheme == theme
                    let locked = PremiumAccess.isThemeLocked(theme, isPremium: store.isPremium)
                    Button {
                        if locked {
                            showsPaywall = true
                        } else {
                            app.widgetTheme = theme
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(theme.background)
                                .frame(width: 72, height: 72)
                            Text("Aa")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(theme.foreground)
                            if locked {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                    .padding(6)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                    .padding(6)
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(selected ? Color.motivaForeground : Color.clear, lineWidth: 2.5)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func settingsRow<Destination: View>(
        title: String,
        value: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 19))
                Spacer()
                Text(value)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.sheetMuted)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.sheetMuted)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct WidgetTopicModePicker: View {
    @Environment(AppState.self) private var app

    var body: some View {
        List {
            ForEach(WidgetTopicMode.allCases) { mode in
                Button {
                    app.widgetTopicMode = mode
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.displayName)
                                .font(.system(size: 18))
                            Text(mode == .mix ? "Quotes from topics you follow" : "Quotes from the full Motiva library")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.sheetMuted)
                        }
                        Spacer()
                        if app.widgetTopicMode == mode {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Topics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WidgetRefreshPicker: View {
    @Environment(AppState.self) private var app

    var body: some View {
        List {
            ForEach(WidgetRefreshInterval.allCases) { interval in
                Button {
                    app.widgetRefresh = interval
                } label: {
                    HStack {
                        Text(interval.displayName)
                            .font(.system(size: 18))
                        Spacer()
                        if app.widgetRefresh == interval {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Refresh")
        .navigationBarTitleDisplayMode(.inline)
    }
}
