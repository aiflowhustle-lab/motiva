import SwiftUI

/// Parses the subset of SVG path data used by the app artwork:
/// M, L, H, V, C, S, Q, T and Z, in absolute and relative forms.
enum SVGPath {
    static func parse(_ data: String) -> Path {
        var tokens = Tokenizer(data)
        var path = Path()
        var current = CGPoint.zero
        var start = CGPoint.zero
        var lastCubicControl: CGPoint?
        var lastQuadControl: CGPoint?
        var command: Character = "M"

        while let token = tokens.next() {
            if case .command(let c) = token {
                command = c
                if c == "Z" || c == "z" {
                    path.closeSubpath()
                    current = start
                    lastCubicControl = nil
                    lastQuadControl = nil
                    continue
                }
            } else {
                tokens.pushBack(token)
            }

            let relative = command.isLowercase
            func point() -> CGPoint {
                let x = tokens.number(), y = tokens.number()
                return relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
            }

            var cubicControl: CGPoint?
            var quadControl: CGPoint?

            switch command.uppercased().first! {
            case "M":
                current = point()
                start = current
                path.move(to: current)
                command = relative ? "l" : "L"
            case "L":
                current = point()
                path.addLine(to: current)
            case "H":
                let x = tokens.number()
                current.x = relative ? current.x + x : x
                path.addLine(to: current)
            case "V":
                let y = tokens.number()
                current.y = relative ? current.y + y : y
                path.addLine(to: current)
            case "C":
                let c1 = point(), c2 = point(), end = point()
                path.addCurve(to: end, control1: c1, control2: c2)
                current = end
                cubicControl = c2
            case "S":
                let c1 = reflect(lastCubicControl, around: current)
                let c2 = point(), end = point()
                path.addCurve(to: end, control1: c1, control2: c2)
                current = end
                cubicControl = c2
            case "Q":
                let c = point(), end = point()
                path.addQuadCurve(to: end, control: c)
                current = end
                quadControl = c
            case "T":
                let c = reflect(lastQuadControl, around: current)
                let end = point()
                path.addQuadCurve(to: end, control: c)
                current = end
                quadControl = c
            default:
                assertionFailure("Unsupported SVG path command \(command)")
                return path
            }

            lastCubicControl = cubicControl
            lastQuadControl = quadControl
        }
        return path
    }

    private static func reflect(_ control: CGPoint?, around point: CGPoint) -> CGPoint {
        guard let control else { return point }
        return CGPoint(x: 2 * point.x - control.x, y: 2 * point.y - control.y)
    }

    private enum Token {
        case command(Character)
        case number(CGFloat)
    }

    private struct Tokenizer {
        private let chars: [Character]
        private var index = 0
        private var pending: Token?

        init(_ string: String) { chars = Array(string) }

        mutating func pushBack(_ token: Token) { pending = token }

        mutating func number() -> CGFloat {
            if case .number(let value)? = next() { return value }
            return 0
        }

        mutating func next() -> Token? {
            if let pending {
                self.pending = nil
                return pending
            }
            while index < chars.count, chars[index] == " " || chars[index] == "," || chars[index].isNewline {
                index += 1
            }
            guard index < chars.count else { return nil }
            let c = chars[index]
            if c.isLetter && c != "e" && c != "E" {
                index += 1
                return .command(c)
            }

            var text = ""
            var seenDot = false
            var seenExponent = false
            if c == "-" || c == "+" {
                text.append(c)
                index += 1
            }
            while index < chars.count {
                let ch = chars[index]
                if ch.isNumber {
                    text.append(ch)
                } else if ch == "." && !seenDot && !seenExponent {
                    seenDot = true
                    text.append(ch)
                } else if (ch == "e" || ch == "E") && !seenExponent {
                    seenExponent = true
                    text.append(ch)
                    if index + 1 < chars.count, chars[index + 1] == "-" || chars[index + 1] == "+" {
                        index += 1
                        text.append(chars[index])
                    }
                } else {
                    break
                }
                index += 1
            }
            return .number(CGFloat(Double(text) ?? 0))
        }
    }
}

/// A shape drawn from SVG path data, scaled to fit its frame while preserving the view box aspect ratio.
struct SVGShape: Shape {
    let path: Path
    let viewBox: CGRect

    init(_ data: String, viewBox: CGSize) {
        self.init(data, viewBox: CGRect(origin: .zero, size: viewBox))
    }

    init(_ data: String, viewBox: CGRect) {
        self.path = SVGPath.parse(data)
        self.viewBox = viewBox
    }

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width / viewBox.width, rect.height / viewBox.height)
        let x = rect.midX - viewBox.width * scale / 2
        let y = rect.midY - viewBox.height * scale / 2
        return path.applying(
            CGAffineTransform(translationX: x, y: y)
                .scaledBy(x: scale, y: scale)
                .translatedBy(x: -viewBox.minX, y: -viewBox.minY)
        )
    }
}
