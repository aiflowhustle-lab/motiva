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

struct QuoteMarkArt: View {
    var body: some View {
        SVGShape(
            "M31 12C15 12 9 23 10 35c1 13 10 19 24 20 9 1 6 15-12 39-5 7-2 13 5 13 6 0 13-10 19-20 15-26 20-49 12-64-5-9-14-11-27-11Zm61 0C76 12 70 23 71 35c1 13 10 19 24 20 9 1 6 15-12 39-5 7-2 13 5 13 6 0 13-10 19-20 15-26 20-49 12-64-5-9-14-11-27-11Z",
            viewBox: CGSize(width: 120, height: 110)
        )
        .fill(Color.motivaForeground)
        .frame(width: 100, height: 100)
        .artShadow()
        .accessibilityLabel("Quotation marks")
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

struct NotificationArt: View {
    private struct Card: View {
        var body: some View {
            HStack(spacing: 10) {
                Text("”")
                    .font(.system(size: 30, weight: .heavy))
                    .frame(width: 25, height: 25)
                    .offset(y: 6)
                    .clipped()
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.motivaForeground, lineWidth: 1))
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { proxy in
                        VStack(alignment: .leading, spacing: 6) {
                            Rectangle().frame(width: proxy.size.width * 0.8, height: 2)
                            Rectangle().frame(width: proxy.size.width * 0.4, height: 1).opacity(0.6)
                        }
                    }
                    .frame(height: 9)
                }
                Rectangle().fill(Color.motivaMuted).frame(width: 15, height: 1)
            }
            .padding(11)
            .frame(height: 57)
            .background(Color.motivaBackground, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 19, style: .continuous).stroke(Color.motivaForeground, lineWidth: 2))
            .artShadow()
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Card().opacity(0.4).blur(radius: 3).offset(x: -5, y: 39)
            Card().offset(y: 77)
        }
        .frame(maxWidth: 290, alignment: .topLeading)
        .frame(height: 165, alignment: .top)
        .padding(.top, 14)
        .padding(.bottom, 9)
        .accessibilityElement()
        .accessibilityLabel("Daily quote notification previews")
    }
}

struct WidgetArt: View {
    var body: some View {
        ArtCanvas(viewBox: CGSize(width: 320, height: 350)) { context in
            context.stroke(SVGPath.parse("M8 350V82Q8 8 82 8h156q74 0 74 74v268"), with: .foreground, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
            context.stroke(Path(roundedRect: CGRect(x: 112, y: 25, width: 96, height: 26), cornerRadius: 13), with: .foreground, lineWidth: 1.4)
            context.stroke(Path(roundedRect: CGRect(x: 40, y: 104, width: 112, height: 112), cornerRadius: 27, style: .continuous), with: .foreground, lineWidth: 2.5)
            context.fill(
                SVGPath.parse("M89 123c-8 0-11 5-10 11 0 6 5 9 11 9 5 1 3 8-5 19-3 4-1 6 2 6s7-5 9-9c8-13 10-24 6-31-2-4-7-5-13-5Zm19 0c-8 0-11 5-10 11 0 6 5 9 11 9 5 1 3 8-5 19-3 4-1 6 2 6s7-5 9-9c8-13 10-24 6-31-2-4-7-5-13-5Z"),
                with: .foreground
            )
            for rect in [CGRect(x: 163, y: 104, width: 47, height: 47), CGRect(x: 228, y: 104, width: 47, height: 47), CGRect(x: 181, y: 157, width: 47, height: 47)] {
                context.stroke(Path(roundedRect: rect, cornerRadius: 13, style: .continuous), with: .muted, lineWidth: 1.3)
            }
        }
        .aspectRatio(320 / 350, contentMode: .fit)
        .frame(maxHeight: 350)
        .mask(
            LinearGradient(stops: [.init(color: .black, location: 0.78), .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom)
        )
        .accessibilityLabel("Motiva quote widget on an iPhone Home Screen")
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
