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
    var message = "Access all topics, quotes, themes, and remove ads!"
    var symbol = "lock.open"

    @State private var showsPaywall = false

    var body: some View {
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
    @State private var trialReminder = false

    var body: some View {
        TrialOfferScreen(trialReminder: $trialReminder, onClose: onClose)
            .padding(.horizontal, Metrics.screenPadding)
            .foregroundStyle(Color.motivaForeground)
            .background(Color.motivaBackground.ignoresSafeArea())
            .environment(\.colorScheme, .light)
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
            ZStack(alignment: .bottom) {
                SVGShape(
                    "M131 28C107 55 61 89 57 125c-6 54 12 95 46 96 53 3 63-45 58-83-3-33-20-71-30-110Z",
                    viewBox: CGRect(x: 54, y: 26, width: 112, height: 197)
                )
                .stroke(style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
                Text("\(count)")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.bottom, 10)
            }
            .frame(width: 50, height: 76)
            .frame(width: 62)
            .accessibilityElement()
            .accessibilityLabel("\(count) day streak")

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
