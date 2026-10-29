import SwiftUI
import WidgetKit

private enum WidgetGalleryCopy {
    static let previewQuote = "Positive mind,\npositive vibes,\npositive life."
}

private enum WidgetTypography {
    static let quote = "BricolageGrotesque-SemiBold"
}

struct MotivaQuoteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MotivaQuote", provider: MotivaQuoteProvider()) { entry in
            MotivaWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    entry.palette.background
                }
        }
        .configurationDisplayName("Daily quote")
        .description("Make it yours by editing this widget from the app's widget settings.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct MotivaQuoteEntry: TimelineEntry {
    let date: Date
    let quote: String
    let palette: WidgetPalette
}

struct MotivaQuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> MotivaQuoteEntry {
        galleryEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (MotivaQuoteEntry) -> Void) {
        if context.isPreview {
            completion(galleryEntry())
        } else {
            completion(makeEntry(at: .now))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MotivaQuoteEntry>) -> Void) {
        let snapshot = WidgetSharedStore.load()
        let palette = WidgetPalette.from(theme: snapshot.theme)
        let calendar = Calendar.current
        let now = Date.now
        var entries: [MotivaQuoteEntry] = []

        for hourOffset in 0..<24 {
            guard let date = calendar.date(byAdding: .hour, value: hourOffset, to: now) else { continue }
            let quote = snapshot.quotes[hourOffset % snapshot.quotes.count]
            entries.append(MotivaQuoteEntry(date: date, quote: quote, palette: palette))
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func galleryEntry() -> MotivaQuoteEntry {
        MotivaQuoteEntry(date: .now, quote: WidgetGalleryCopy.previewQuote, palette: .classic)
    }

    private func makeEntry(at date: Date) -> MotivaQuoteEntry {
        let snapshot = WidgetSharedStore.load()
        let palette = WidgetPalette.from(theme: snapshot.theme)
        let hour = Calendar.current.component(.hour, from: date)
        let quote = snapshot.quotes[hour % snapshot.quotes.count]
        return MotivaQuoteEntry(date: date, quote: quote, palette: palette)
    }
}

struct MotivaWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MotivaQuoteEntry

    var body: some View {
        Text(entry.quote)
            .font(.custom(WidgetTypography.quote, size: fontSize))
            .foregroundStyle(entry.palette.foreground)
            .multilineTextAlignment(.center)
            .lineSpacing(lineSpacing)
            .minimumScaleFactor(0.75)
            .padding(contentPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .accessibilityLabel(entry.quote.replacingOccurrences(of: "\n", with: " "))
    }

    private var fontSize: CGFloat {
        switch family {
        case .systemSmall: 16
        case .systemMedium: 20
        case .systemLarge: 23
        default: 19
        }
    }

    private var lineSpacing: CGFloat {
        family == .systemSmall ? 3 : 4
    }

    private var contentPadding: CGFloat {
        switch family {
        case .systemSmall: 12
        case .systemMedium: 16
        case .systemLarge: 20
        default: 14
        }
    }
}

struct WidgetPalette {
    let background: Color
    let foreground: Color

    static let classic = WidgetPalette(
        background: Color(red: 0.075, green: 0.075, blue: 0.075),
        foreground: Color(red: 0.99, green: 0.99, blue: 0.99)
    )

    static let paper = WidgetPalette(
        background: Color(red: 0.949, green: 0.949, blue: 0.949),
        foreground: Color(red: 0.082, green: 0.082, blue: 0.082)
    )

    static let forest = WidgetPalette(
        background: Color(red: 0.09, green: 0.153, blue: 0.118),
        foreground: Color(red: 0.99, green: 0.99, blue: 0.99)
    )

    static func from(theme raw: String) -> WidgetPalette {
        switch raw {
        case "paper": return .paper
        case "forest": return .forest
        default: return .classic
        }
    }
}
