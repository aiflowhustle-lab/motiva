import SwiftUI

/// Small streak flame badge (native recreation of `flame-streak-badge.html`).
struct StreakFlameBadge: View {
    let count: Int
    var foreground: Color = .motivaForeground

    private static let viewBox = CGSize(width: 100, height: 136)
    private static let outline =
        "M50 8 C70 46 86 68 86 88 C86 110 70 124 50 124 C30 124 14 110 14 88 C14 68 30 46 50 8 Z"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedCount: Int
    @State private var flareGeneration = 0
    @State private var flarePopScale: CGFloat = 1
    @State private var ringScale: CGFloat = 0.9
    @State private var ringOpacity: Double = 0
    @State private var digitOffset: CGFloat = 0
    @State private var digitOpacity: Double = 1

    init(count: Int, foreground: Color = .motivaForeground) {
        self.count = count
        self.foreground = foreground
        _displayedCount = State(initialValue: count)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            badge(at: time)
        }
        .frame(width: 56, height: 76)
        .onChange(of: count) { old, new in
            guard new != displayedCount else { return }
            if new > old, !reduceMotion {
                playFlare(to: new)
            } else {
                displayedCount = new
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(displayedCount) day streak")
    }

    private func badge(at time: TimeInterval) -> some View {
        let sway = sin(time * 2 * .pi / 2.8)
        let rise = sin(time * 2 * .pi / 2.0)
        let riseX = 1 - 0.015 * rise
        let riseY = 1 + 0.022 * rise
        let rotation = sway * 2.8

        let width: CGFloat = 56
        let height: CGFloat = 76

        return ZStack(alignment: .bottom) {
            SVGShape(Self.outline, viewBox: Self.viewBox)
                .stroke(foreground, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
                .allowsHitTesting(false)

            ZStack {
                SVGShape(Self.outline, viewBox: Self.viewBox)
                    .stroke(foreground, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))

                ember(
                    time: time, period: 2.2, delay: 0,
                    width: width, height: height,
                    x: 0.56, y: 0.147, radius: 1.8
                )
                ember(
                    time: time, period: 2.8, delay: 0.9,
                    width: width, height: height,
                    x: 0.44, y: 0.221, radius: 1.4
                )
            }
            .frame(width: width, height: height)
            .scaleEffect(
                x: riseX * flarePopScale,
                y: riseY * flarePopScale,
                anchor: UnitPoint(x: 0.5, y: 0.9)
            )
            .rotationEffect(.degrees(rotation), anchor: UnitPoint(x: 0.5, y: 0.9))

            Text("\(displayedCount)")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(foreground)
                .padding(.bottom, 9)
                .offset(y: digitOffset)
                .opacity(digitOpacity)
        }
        .frame(width: width, height: height)
    }

    private func ember(
        time: TimeInterval,
        period: Double,
        delay: Double,
        width: CGFloat,
        height: CGFloat,
        x: CGFloat,
        y: CGFloat,
        radius: CGFloat
    ) -> some View {
        let phase = (time - delay).truncatingRemainder(dividingBy: period) / period
        let sample = emberSample(phase)
        let point = CGPoint(
            x: width * x + sample.offset.width,
            y: height * y + sample.offset.height
        )
        return Circle()
            .fill(foreground)
            .frame(width: radius * 2, height: radius * 2)
            .scaleEffect(sample.scale)
            .opacity(sample.opacity * 0.55)
            .position(point)
            .allowsHitTesting(false)
    }

    private func emberSample(_ phase: Double) -> (offset: CGSize, scale: CGFloat, opacity: Double) {
        switch phase {
        case ..<0.25:
            let t = phase / 0.25
            return (CGSize(width: 3 * t, height: -18 * t), 0.5 + 0.2 * t, t * 0.7)
        default:
            let t = (phase - 0.25) / 0.75
            return (CGSize(width: 3, height: -18 * t), 0.7 - 0.4 * t, 0.7 * (1 - t))
        }
    }

    @MainActor
    private func playFlare(to newCount: Int) {
        flareGeneration += 1
        let generation = flareGeneration

        ringOpacity = 0.6
        ringScale = 0.9

        withAnimation(.spring(duration: 0.5, bounce: 0.45)) {
            flarePopScale = 1.14
        }
        withAnimation(.easeOut(duration: 0.55)) {
            ringScale = 1.6
            ringOpacity = 0
        }
        withAnimation(.easeInOut(duration: 0.16)) {
            digitOffset = -7
            digitOpacity = 0
        }

        Task {
            try? await Task.sleep(for: .milliseconds(180))
            guard generation == flareGeneration else { return }
            displayedCount = newCount
            digitOffset = 7
            withAnimation(.easeInOut(duration: 0.28)) {
                digitOffset = 0
                digitOpacity = 1
            }
            try? await Task.sleep(for: .milliseconds(320))
            guard generation == flareGeneration else { return }
            withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                flarePopScale = 1
            }
        }
    }
}
