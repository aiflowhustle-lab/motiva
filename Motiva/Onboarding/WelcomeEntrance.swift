import SwiftUI

enum WelcomeMotion {
    /// Logo lands first — slight overshoot on scale for a “pop” before copy.
    static let logo = Animation.timingCurve(0.34, 1.52, 0.64, 1, duration: 0.740)
    static let headline = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.620)
    static let subtitle = Animation.timingCurve(0.25, 1, 0.3, 1, duration: 0.520)
    static let button = Animation.timingCurve(0.34, 1.4, 0.64, 1, duration: 0.560)
    static let legal = Animation.easeOut(duration: 0.400)
    static let reduceMotionFade = Animation.easeOut(duration: 0.200)

    static let logoDelay: Duration = .milliseconds(380)
    static let line1Delay: Duration = .milliseconds(820)
    static let line2Delay: Duration = .milliseconds(910)
    static let subtitleDelay: Duration = .milliseconds(1040)
    static let buttonDelay: Duration = .milliseconds(1200)
    static let legalDelay: Duration = .milliseconds(1340)
}

/// Motiva mark: rises, un-scales, and settles with a soft rotational snap-in.
struct WelcomeLogoEntrance: View {
    var size: CGFloat = 170
    let revealed: Bool
    let animation: Animation

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.motivaForeground.opacity(revealed ? 0 : 0.12), lineWidth: 1.5)
                .frame(width: size * 1.22, height: size * 1.22)
                .scaleEffect(revealed ? 1.15 : 0.55)
                .opacity(revealed ? 0 : 1)

            QuoteMarkArt(size: size)
        }
        .opacity(revealed ? 1 : 0)
        .scaleEffect(revealed ? 1 : 0.68)
        .rotationEffect(.degrees(revealed ? 0 : -11))
        .offset(y: revealed ? 0 : 40)
        .animation(animation, value: revealed)
        .accessibilityLabel("Motiva")
    }
}

/// Slides headline text up inside a fixed clip; opacity unchanged.
struct HeadlineLineReveal: View {
    let text: String
    let revealed: Bool
    let animation: Animation

    @State private var lineHeight: CGFloat = 33

    var body: some View {
        Text(text)
            .titleStyle()
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onAppear { lineHeight = max(geometry.size.height, 1) }
                        .onChange(of: geometry.size.height) { _, height in
                            if height > 0 { lineHeight = height }
                        }
                }
            }
            .offset(y: revealed ? 0 : lineHeight * 1.08)
            .animation(animation, value: revealed)
            .frame(maxWidth: .infinity)
            .clipped()
    }
}

/// Opacity + vertical offset entrance (layout size fixed from first frame).
struct FadeSlideReveal<Content: View>: View {
    let revealed: Bool
    let hiddenOffset: CGFloat
    let animation: Animation
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : hiddenOffset)
            .animation(animation, value: revealed)
    }
}

struct WelcomeButtonEntrance: View {
    let revealed: Bool
    let animation: Animation
    let action: () -> Void

    var body: some View {
        Button(action: action) { Text("Continue") }
            .buttonStyle(WelcomeContinueButtonStyle())
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 36)
            .scaleEffect(revealed ? 1 : 0.98)
            .animation(animation, value: revealed)
            .allowsHitTesting(revealed)
    }
}

/// Welcome Continue: 0.975 scale over 140 ms on press (entrance is separate).
struct WelcomeContinueButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
            .padding(.horizontal, 15)
            .foregroundStyle(.white)
            .background(Color.motivaPrimary, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
            .contentShape(Rectangle())
            .pressHaptic(.impact(flexibility: .solid, intensity: 1.0), isPressed: configuration.isPressed)
    }
}

struct WelcomeEntranceTimeline {
    @MainActor
    static func run(
        reduceMotion: Bool,
        set: @escaping (WelcomeEntranceFlags) -> Void
    ) {
        guard !reduceMotion else { return }

        Task { @MainActor in
            try? await Task.sleep(for: WelcomeMotion.logoDelay)
            withAnimation(WelcomeMotion.logo) { set(WelcomeEntranceFlags(logo: true)) }
        }
        Task { @MainActor in
            try? await Task.sleep(for: WelcomeMotion.line1Delay)
            withAnimation(WelcomeMotion.headline) { set(WelcomeEntranceFlags(logo: true, line1: true)) }
        }
        Task { @MainActor in
            try? await Task.sleep(for: WelcomeMotion.line2Delay)
            withAnimation(WelcomeMotion.headline) { set(WelcomeEntranceFlags(logo: true, line1: true, line2: true)) }
        }
        Task { @MainActor in
            try? await Task.sleep(for: WelcomeMotion.subtitleDelay)
            withAnimation(WelcomeMotion.subtitle) {
                set(WelcomeEntranceFlags(logo: true, line1: true, line2: true, subtitle: true))
            }
        }
        Task { @MainActor in
            try? await Task.sleep(for: WelcomeMotion.buttonDelay)
            withAnimation(WelcomeMotion.button) {
                set(WelcomeEntranceFlags(logo: true, line1: true, line2: true, subtitle: true, button: true))
            }
        }
        Task { @MainActor in
            try? await Task.sleep(for: WelcomeMotion.legalDelay)
            withAnimation(WelcomeMotion.legal) { set(WelcomeEntranceFlags(allVisible: true)) }
        }
    }
}

struct WelcomeEntranceFlags: Equatable {
    var logo = false
    var line1 = false
    var line2 = false
    var subtitle = false
    var button = false
    var legal = false

    init(
        logo: Bool = false,
        line1: Bool = false,
        line2: Bool = false,
        subtitle: Bool = false,
        button: Bool = false,
        legal: Bool = false
    ) {
        self.logo = logo
        self.line1 = line1
        self.line2 = line2
        self.subtitle = subtitle
        self.button = button
        self.legal = legal
    }

    init(allVisible: Bool) {
        logo = allVisible
        line1 = allVisible
        line2 = allVisible
        subtitle = allVisible
        button = allVisible
        legal = allVisible
    }
}
