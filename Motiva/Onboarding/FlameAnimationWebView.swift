import SwiftUI

/// Native flame motion (same timing feel as `flame.html`) — no WebKit, renders on frame 0.
struct AnimatedFlameIllustration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                FlameStaticPlaceholder()
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    flameLayers(at: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
    }

    private func flameLayers(at time: TimeInterval) -> some View {
        let riseWave = sin(time * 2 * .pi / 1.7)
        let swayWave = sin(time * 2 * .pi / 2.4)
        let scaleX = 1 - 0.028 * riseWave
        let scaleY = 1 + 0.045 * riseWave
        let rotation = swayWave * 5.5
        let haloPulse = 0.5 + 0.5 * riseWave

        return GeometryReader { geometry in
            let sx = geometry.size.width / 160
            let sy = geometry.size.height / 200

            ZStack {
                FlameStaticPlaceholder()
                    .scaleEffect(x: scaleX, y: scaleY, anchor: UnitPoint(x: 0.5, y: 0.95))
                    .rotationEffect(.degrees(rotation), anchor: UnitPoint(x: 0.5, y: 0.95))

                spark(time: time, period: 1.5, delay: 0, x: 88 * sx, y: 24 * sy, radius: 2 * sx)
                spark(time: time, period: 2.0, delay: 0.6, x: 70 * sx, y: 40 * sy, radius: 1.6 * sx)
                spark(time: time, period: 2.4, delay: 1.1, x: 95 * sx, y: 50 * sy, radius: 1.3 * sx)
            }
            .opacity(0.92 + 0.08 * haloPulse)
        }
    }

    private func spark(
        time: TimeInterval,
        period: Double,
        delay: Double,
        x: CGFloat,
        y: CGFloat,
        radius: CGFloat
    ) -> some View {
        let elapsed = time - delay
        let phase = elapsed.truncatingRemainder(dividingBy: period) / period
        let eased = sparkSample(phase)

        return Circle()
            .fill(Color.motivaForeground)
            .frame(width: radius * 2, height: radius * 2)
            .scaleEffect(eased.scale)
            .opacity(eased.opacity * 0.55)
            .position(x: x + eased.offset.width, y: y + eased.offset.height)
    }

    private func sparkSample(_ phase: Double) -> (offset: CGSize, scale: CGFloat, opacity: Double) {
        switch phase {
        case ..<0.2:
            let t = phase / 0.2
            return (CGSize(width: 0, height: 4 * (1 - t)), 0.6 + 0.2 * t, t * 0.8)
        case ..<0.6:
            let t = (phase - 0.2) / 0.4
            return (CGSize(width: 5 * t, height: 4 - 20 * t), 0.8 + 0.2 * t, 0.8)
        default:
            let t = (phase - 0.6) / 0.4
            return (CGSize(width: 5 - 9 * t, height: -16 - 16 * t), 1 - 0.6 * t, 0.8 * (1 - t))
        }
    }
}

struct FlameArt: View {
    var body: some View {
        AnimatedFlameIllustration()
            .frame(width: 205, height: 245)
            .artShadow()
            .accessibilityLabel("Flame")
    }
}
