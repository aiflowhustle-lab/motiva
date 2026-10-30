import SwiftUI

private extension GraphicsContext.Shading {
    static let foreground = GraphicsContext.Shading.color(.motivaForeground)
    static let muted = GraphicsContext.Shading.color(.motivaMuted)
}

private func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
}

private func rotated(_ path: Path, degrees: Double, around center: CGPoint) -> Path {
    path.applying(
        CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: -center.x, y: -center.y)
    )
}

/// Draws in a fixed design coordinate space, scaled to fit the available size.
private struct ArtCanvas: View {
    let viewBox: CGSize
    let draw: (inout GraphicsContext) -> Void

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / viewBox.width, size.height / viewBox.height)
            context.translateBy(x: (size.width - viewBox.width * scale) / 2, y: (size.height - viewBox.height * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            draw(&context)
        }
    }
}

/// App icon artwork (black tile + white mark), scaled to `size`.
struct MotivaLogoMark: View {
    var size: CGFloat = 100
    /// Defaults to iOS app-icon proportion; notification previews use Lovable ratios (8pt @ 32, 10pt @ 43).
    var cornerRadius: CGFloat?

    var body: some View {
        Image("MotivaLogo")
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? size * 0.223, style: .continuous))
    }
}

/// White mark on black tile — welcome and widget onboarding.
struct QuoteMarkArt: View {
    var size: CGFloat = 170

    var body: some View {
        Image("MotivaWelcomeMark")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.223, style: .continuous))
            .accessibilityLabel("Motiva")
    }
}

struct CompassArt: View {
    var body: some View {
        ArtCanvas(viewBox: CGSize(width: 200, height: 200)) { context in
            let center = CGPoint(x: 100, y: 100)
            context.stroke(circle(100, 100, 94), with: .foreground, lineWidth: 2.7)
            context.stroke(circle(100, 100, 80), with: .muted, lineWidth: 1.6)

            for i in 0..<12 {
                let major = i % 3 == 0
                var tick = Path()
                tick.move(to: CGPoint(x: 100, y: major ? 21 : 23))
                tick.addLine(to: CGPoint(x: 100, y: major ? 30 : 28))
                context.stroke(
                    rotated(tick, degrees: Double(i) * 30, around: center),
                    with: major ? .foreground : .muted,
                    style: StrokeStyle(lineWidth: major ? 2.3 : 1.3, lineCap: major ? .round : .butt)
                )
            }

            var label = context
            label.translateBy(x: 100, y: 44)
            label.rotate(by: .degrees(6))
            label.draw(Text("N").font(.system(size: 20)).foregroundStyle(Color.motivaForeground), at: .zero)

            let north = rotated(SVGPath.parse("M100 44 89 104 100 100 111 104Z"), degrees: 34, around: center)
            let south = rotated(SVGPath.parse("M100 153 89 104 100 100 111 104Z"), degrees: 34, around: center)
            context.fill(north, with: .foreground)
            context.stroke(south, with: .muted, style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
            context.fill(circle(100, 100, 5), with: .color(.motivaBackground))
            context.stroke(circle(100, 100, 5), with: .foreground, lineWidth: 1.4)
        }
        .frame(width: 166, height: 166)
        .artShadow()
        .accessibilityLabel("Compass")
    }
}

struct TargetArt: View {
    var body: some View {
        ArtCanvas(viewBox: CGSize(width: 240, height: 240)) { context in
            context.stroke(circle(120, 120, 108), with: .foreground, lineWidth: 2)
            context.stroke(circle(120, 120, 69), with: .foreground, lineWidth: 1)
            context.stroke(circle(120, 120, 37), with: .foreground, style: StrokeStyle(lineWidth: 1, dash: [3, 7]))
            context.fill(circle(120, 120, 5), with: .foreground)
        }
        .frame(width: 224, height: 224)
        .artShadow()
        .accessibilityLabel("Concentric target rings")
    }
}

struct OrbitArt: View {
    var body: some View {
        ArtCanvas(viewBox: CGSize(width: 240, height: 240)) { context in
            context.drawLayer { layer in
                layer.opacity = 0.2
                layer.addFilter(.blur(radius: 2.5))
                for (x, y, r) in [(58, 58, 21), (188, 46, 13), (198, 150, 25), (64, 182, 17), (128, 22, 9), (24, 126, 11), (150, 214, 13)] as [(CGFloat, CGFloat, CGFloat)] {
                    layer.stroke(circle(x, y, r), with: .foreground, lineWidth: 4)
                }
            }
            context.drawLayer { layer in
                layer.opacity = 0.3
                layer.addFilter(.blur(radius: 1.4))
                for (x, y) in [(96, 44), (212, 98), (42, 150), (118, 224)] as [(CGFloat, CGFloat)] {
                    layer.fill(circle(x, y, 3), with: .foreground)
                }
            }
            context.stroke(circle(120, 118, 52), with: .foreground, lineWidth: 3.2)
            context.fill(circle(120, 118, 7), with: .foreground)
        }
        .frame(width: 196, height: 196)
        .artShadow()
        .accessibilityLabel("Ring surrounded by soft orbiting rings")
    }
}

struct FlameArt: View {
    var body: some View {
        ArtCanvas(viewBox: CGSize(width: 220, height: 270)) { context in
            let dotted = StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round, dash: [1, 8])
            let solid = { (width: CGFloat) in StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round) }

            context.stroke(Path(ellipseIn: CGRect(x: 35, y: 216, width: 146, height: 34)), with: .muted, style: dotted)
            context.stroke(SVGPath.parse("M131 28C107 55 61 89 57 125c-6 54 12 95 46 96 53 3 63-45 58-83-3-33-20-71-30-110Z"), with: .foreground, style: solid(2.5))
            context.stroke(SVGPath.parse("M122 104c-12 19-35 30-38 57-3 35 12 61 24 60 29 0 30-36 31-53 1-18-11-46-17-64Z"), with: .foreground, style: solid(1.2))
            context.stroke(SVGPath.parse("M115 157c-10 15-19 25-16 44 1 13 7 20 13 20 16-1 12-28 3-64Z"), with: .muted, style: dotted)
            context.stroke(SVGPath.parse("m120 17 5-5"), with: .foreground, style: solid(1.2))
            context.fill(circle(164, 266, 2), with: .muted)
            context.fill(circle(121, 21, 1.5), with: .muted)
        }
        .frame(width: 205, height: 245)
        .artShadow()
        .accessibilityLabel("Flame")
    }
}

struct StreakPreview: View {
    private var days: [String] {
        let calendar = Calendar.current
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let today = calendar.component(.weekday, from: .now) - 1
        return (0..<7).map { String(symbols[(today + $0) % 7].prefix(2)) }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    VStack(spacing: 7) {
                        Text(day).font(.system(size: 12, weight: .semibold))
                        ZStack {
                            if index == 0 {
                                Circle().fill(Color.motivaBackground)
                                Circle().strokeBorder(Color.motivaForeground, lineWidth: 2)
                                Image(systemName: "checkmark").font(.system(size: 16, weight: .heavy))
                            } else {
                                Circle().strokeBorder(Color.motivaMuted, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                            }
                        }
                        .frame(width: 33, height: 33)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            Text("Build a streak, one day at a time")
                .font(.system(size: 14))
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(Color.motivaCard, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

/// Phone-top silhouette with stacked iOS-style notification previews (Lovable reference design).
struct NotificationArt: View {
    private struct Item: Identifiable {
        let time: String
        let title: String
        let message: String
        var id: String { time }
    }

    private let items: [Item] = [
        Item(time: "now", title: "Motiva", message: "Small steps are still steps forward."),
        Item(time: "Yesterday", title: "Motiva", message: "Your peace is worth protecting."),
        Item(time: "Tuesday", title: "Motiva", message: "Make room for the person you are becoming."),
    ]

    @State private var revealedCount = 1

    var body: some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(
                topLeadingRadius: 100,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 82,
                style: .continuous
            )
                .fill(Color.motivaForeground)
                .frame(width: 290, height: 316)
                .rotationEffect(.degrees(0.4))
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.motivaBackground)
                        .frame(width: 44, height: 3)
                        .padding(.top, 15)
                }
                .mask {
                    LinearGradient(
                        colors: [.black, .black, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            VStack(spacing: 19) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    notificationCard(item, prominent: index == 0)
                        .frame(maxWidth: index == 0 ? 331 : 248)
                        .frame(maxWidth: .infinity)
                        .padding(.top, index == 0 ? 64 : 0)
                        .opacity(revealedCount > index ? 1 : 0)
                        .scaleEffect(revealedCount > index ? 1 : 0.9, anchor: .top)
                        .offset(y: revealedCount > index ? 0 : 18)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 316)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily Motiva notification previews")
        .onAppear { runPopInSequence() }
    }

    private func runPopInSequence() {
        revealedCount = 1
        guard items.count > 1 else { return }
        for index in 1..<items.count {
            let delay = 0.4 + Double(index - 1) * 0.55
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.72, dampingFraction: 0.78)) {
                    revealedCount = index + 1
                }
            }
        }
    }

    private func notificationCard(_ item: Item, prominent: Bool) -> some View {
        let iconSize: CGFloat = prominent ? 43 : 32
        let corner: CGFloat = prominent ? 10 : 8
        return HStack(alignment: .top, spacing: prominent ? 9 : 7) {
            appIcon(size: iconSize, prominent: prominent)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: prominent ? 14 : 10, weight: .semibold))
                    .lineLimit(1)
                Text(item.message)
                    .font(.system(size: prominent ? 14 : 10))
                    .foregroundStyle(Color.motivaForeground)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, prominent ? 11 : 8)
        .padding(.vertical, prominent ? 15 : 12)
        .frame(maxWidth: prominent ? 331 : .infinity, minHeight: prominent ? 74 : 56, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Text(item.time)
                .font(.system(size: prominent ? 13 : 10))
                .foregroundStyle(Color(hex: 0x7D7D7D))
                .padding(.top, prominent ? 7 : 5)
                .padding(.trailing, prominent ? 14 : 10)
        }
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private func appIcon(size: CGFloat, prominent: Bool) -> some View {
        let corner = size * (prominent ? 10 / 43 : 8 / 32)
        return MotivaLogoMark(size: size, cornerRadius: corner)
            .accessibilityHidden(true)
    }
}

/// Home Screen widget illustration (Lovable widget onboarding reference).
struct WidgetArt: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let widgetSide = width * 0.48
            let appSide = width * 0.21

            ZStack(alignment: .top) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 70,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 70,
                    style: .continuous
                )
                .stroke(Color.motivaForeground, lineWidth: 2.5)
                .frame(maxWidth: .infinity)
                .frame(height: geometry.size.height * 1.12, alignment: .top)
                .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: -8)

                Capsule()
                    .stroke(Color.motivaForeground, lineWidth: 1.5)
                    .frame(width: width * 0.32, height: 29)
                    .padding(.top, 17)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 31, style: .continuous)
                        .stroke(Color.motivaForeground, lineWidth: 2.8)
                        .frame(width: widgetSide, height: widgetSide)
                        .overlay {
                            Image("MotivaWelcomeMark")
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .frame(width: min(63, widgetSide * 0.55), height: min(63, widgetSide * 0.55))
                                .clipShape(RoundedRectangle(cornerRadius: min(63, widgetSide * 0.55) * 0.223, style: .continuous))
                                .accessibilityHidden(true)
                        }

                    widgetAppOutline
                        .frame(width: appSide, height: appSide)
                        .offset(x: width * 0.52, y: 0)

                    widgetAppOutline
                        .frame(width: appSide, height: appSide)
                        .offset(x: width * 0.79, y: 0)

                    widgetAppOutline
                        .frame(width: appSide, height: appSide)
                        .offset(x: width * 0.59, y: 57)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, width * 0.10)
                .padding(.top, 99)
            }
        }
        .aspectRatio(323 / 368, contentMode: .fit)
        .frame(maxWidth: 323)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.77),
                    .init(color: .clear, location: 0.99),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .accessibilityLabel("Motiva widget on an iPhone Home Screen")
    }

    private var widgetAppOutline: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .stroke(Color.motivaAppOutline, lineWidth: 1.5)
    }
}

struct MouthIcon: View {
    private static let mouths = [
        "M7 12c4 10 18 10 22 0",
        "M8 14c4 6 16 6 20 0",
        "M9 16h14",
        "M8 19c4-6 16-6 20 0",
        "M7 21c4-11 18-11 22 0",
        "M8 16c3-5 5 5 8 0s5-5 8 0",
    ]

    let kind: Int

    var body: some View {
        SVGShape(Self.mouths[kind % Self.mouths.count], viewBox: CGSize(width: 32, height: 32))
            .stroke(style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
            .frame(width: 30, height: 30)
            .accessibilityHidden(true)
    }
}
