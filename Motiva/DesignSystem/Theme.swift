import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    static let motivaBackground = Color(hex: 0xF2F2F2)
    static let motivaForeground = Color(hex: 0x151515)
    static let motivaPrimary = Color(hex: 0x171717)
    static let motivaCard = Color.white
    static let motivaMuted = Color(hex: 0x878787)
    static let motivaBorder = Color(hex: 0xDBDBDB)
    static let motivaInput = Color(hex: 0xE8E8E8)
    static let motivaDark = Color(hex: 0x070707)
    static let motivaDarkButton = Color(hex: 0xEBEBEB)

    static let sheetBackground = Color(hex: 0xF5F5F5)
    static let sheetMuted = Color(hex: 0x777777)
    static let sheetFill = Color(hex: 0xEBEBEB)
}

enum Metrics {
    static let screenPadding: CGFloat = 25
    static let cornerRadius: CGFloat = 17
    static let buttonHeight: CGFloat = 59
}

extension Font {
    static let motivaTitle = Font.system(size: 26, weight: .bold)
    static let motivaBody = Font.system(size: 18)
    static let motivaChoice = Font.system(size: 21)
}

extension View {
    func artShadow() -> some View {
        shadow(color: .black.opacity(0.24), radius: 14, x: 0, y: 10)
    }

    func titleStyle() -> some View {
        font(.motivaTitle)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct RevealModifier: ViewModifier {
    let visible: Bool
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reduceMotion ? 0 : -14)
            .animation(.easeOut(duration: 0.55).delay(delay), value: visible)
    }
}

extension View {
    /// Fades the view in while it drops into place from slightly above, once `visible` turns true.
    func reveal(_ visible: Bool, delay: Double) -> some View {
        modifier(RevealModifier(visible: visible, delay: delay))
    }

    /// Like `reveal`, but shows the view immediately when `delay` is nil.
    @ViewBuilder
    func staggeredReveal(_ visible: Bool, delay: Double?) -> some View {
        if let delay {
            reveal(visible, delay: delay)
        } else {
            self
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var inverted = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
            .padding(.horizontal, 15)
            .foregroundStyle(inverted ? Color.motivaDark : .white)
            .background(
                inverted ? Color.motivaDarkButton : Color.motivaPrimary,
                in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .contentShape(Rectangle())
    }
}

struct ChoiceButtonStyle: ButtonStyle {
    /// Filled black, for toggles like topic chips.
    var selected = false
    /// Soft grey, for the answer just picked on a tap-to-advance question.
    var highlighted = false

    private func background(pressed: Bool) -> Color {
        if selected { return .motivaPrimary }
        if highlighted { return .motivaBorder }
        return pressed ? .motivaInput : .motivaCard
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.motivaChoice)
            .foregroundStyle(selected ? .white : Color.motivaForeground)
            .frame(minHeight: Metrics.buttonHeight)
            .background(
                background(pressed: configuration.isPressed),
                in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .contentShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
    }
}

struct QuietButtonStyle: ButtonStyle {
    var color: Color = .motivaMuted

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(color)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var primaryInverted: PrimaryButtonStyle { PrimaryButtonStyle(inverted: true) }
}

extension ButtonStyle where Self == QuietButtonStyle {
    static var quiet: QuietButtonStyle { QuietButtonStyle() }
    static func quiet(_ color: Color) -> QuietButtonStyle { QuietButtonStyle(color: color) }
}
