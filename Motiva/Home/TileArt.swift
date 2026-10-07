import SwiftUI

enum TileKind: String, CaseIterable, Identifiable {
    case topics, wallpapers, reminders, homeWidget, lockWidget, appIcon, watch, bundle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .topics: "Topics you follow"
        case .wallpapers: "Wallpapers"
        case .reminders: "Reminders"
        case .homeWidget: "Home Screen widgets"
        case .lockWidget: "Lock Screen widgets"
        case .appIcon: "App icon"
        case .watch: "Watch"
        case .bundle: "Self-Growth bundle"
        }
    }
}

/// Thin line illustrations for the Profile tiles, drawn in a 150×140 design space.
struct TileArt: View {
    let kind: TileKind

    var body: some View {
        Canvas { context, size in
            let viewBox = CGSize(width: 150, height: 140)
            let scale = min(size.width / viewBox.width, size.height / viewBox.height)
            context.translateBy(x: (size.width - viewBox.width * scale) / 2, y: (size.height - viewBox.height * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            context.clip(to: Path(CGRect(origin: .zero, size: viewBox)))
            draw(in: &context)
        }
        .frame(width: 120, height: 115)
        .accessibilityHidden(true)
    }

    private var ink: GraphicsContext.Shading { .color(.motivaForeground) }

    private func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat, rotate degrees: Double = 0, around center: CGPoint? = nil) -> Path {
        let path = Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r, style: .continuous)
        guard degrees != 0, let center else { return path }
        return path.applying(
            CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: degrees * .pi / 180)
                .translatedBy(x: -center.x, y: -center.y)
        )
    }

    private func stroke(_ context: inout GraphicsContext, _ path: Path, width: CGFloat = 1, opacity: Double = 1) {
        var layer = context
        layer.opacity = opacity
        layer.stroke(path, with: ink, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func text(_ context: inout GraphicsContext, _ string: String, at point: CGPoint, size: CGFloat, weight: Font.Weight = .regular) {
        context.draw(
            Text(string).font(.system(size: size, weight: weight)).foregroundStyle(Color.motivaForeground),
            at: point,
            anchor: .bottomLeading
        )
    }

    private func draw(in context: inout GraphicsContext) {
        switch kind {
        case .topics:
            for r in [rect(15, 31, 48, 18, 9), rect(87, 20, 35, 17, 9), rect(46, 65, 43, 18, 9), rect(93, 90, 36, 18, 9), rect(12, 105, 44, 17, 9)] {
                stroke(&context, r)
            }
            stroke(&context, Path(ellipseIn: CGRect(x: 29, y: 23, width: 38, height: 38)), width: 1.5)
            stroke(&context, SVGPath.parse("m63 57 16 17M23 40h30m42-12h20M56 74h22M22 113h21"))

        case .wallpapers:
            stroke(&context, rect(57, 39, 51, 72, 8, rotate: 6, around: CGPoint(x: 80, y: 70)))
            stroke(&context, rect(94, 41, 43, 73, 8, rotate: 14, around: CGPoint(x: 115, y: 76)))
            stroke(&context, rect(15, 20, 51, 76, 8, rotate: -9, around: CGPoint(x: 40, y: 58)), width: 1.5)
            stroke(&context, SVGPath.parse("m29 55 24-4m-23 10 17-3"))
            var dot = context
            dot.opacity = 0.4
            dot.fill(Path(ellipseIn: CGRect(x: 109, y: 70, width: 12, height: 12)), with: ink)

        case .reminders:
            stroke(&context, rect(6, 53, 138, 31, 10))
            stroke(&context, rect(13, 60, 14, 14, 4))
            stroke(&context, SVGPath.parse("M34 63h72m-72 7h42m52-3h7"))
            text(&context, "”", at: CGPoint(x: 16, y: 80), size: 13)

        case .watch:
            stroke(&context, SVGPath.parse("m56 35 5-25h31l5 25m-41 75 5 24h31l5-24"))
            stroke(&context, rect(46, 31, 62, 83, 24))
            stroke(&context, rect(53, 38, 48, 68, 17))
            stroke(&context, rect(109, 52, 4, 14, 2))

        case .appIcon, .bundle:
            stroke(&context, rect(51, 43, 48, 48, 12), width: 1.5)
            text(&context, "”", at: CGPoint(x: 61, y: 96), size: 43)
            stroke(&context, rect(21, 18, 30, 31, 7, rotate: -12, around: CGPoint(x: 36, y: 33)), opacity: 0.35)
            stroke(&context, rect(103, 25, 29, 30, 7, rotate: 12, around: CGPoint(x: 115, y: 40)), opacity: 0.35)
            stroke(&context, rect(110, 94, 29, 30, 7, rotate: 12, around: CGPoint(x: 115, y: 110)), opacity: 0.35)
            stroke(&context, rect(22, 100, 27, 28, 7), opacity: 0.35)

        case .homeWidget, .lockWidget:
            stroke(&context, rect(23, 7, 105, 145, 25))
            stroke(&context, rect(59, 15, 35, 10, 5))
            if kind == .lockWidget {
                text(&context, "11:11", at: CGPoint(x: 45, y: 76), size: 26, weight: .bold)
                stroke(&context, rect(32, 89, 38, 20, 5))
                stroke(&context, rect(77, 89, 38, 20, 5))
            } else {
                stroke(&context, rect(35, 44, 41, 46, 9))
                text(&context, "”", at: CGPoint(x: 43, y: 86), size: 32)
                stroke(&context, rect(83, 44, 17, 18, 4))
                stroke(&context, rect(105, 44, 17, 18, 4))
                stroke(&context, rect(83, 68, 17, 18, 4))
            }
        }
    }
}
