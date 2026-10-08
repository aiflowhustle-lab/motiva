import SwiftUI

/// Reveals `text` one character at a time. The full text is laid out from the start, with
/// unrevealed characters transparent, so line breaks and centering never shift while typing.
struct TypewriterText: View {
    let text: String
    @Binding var isComplete: Bool
    var characterDelay: Duration = .milliseconds(38)
    var startDelay: Duration = .milliseconds(450)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleCount = 0
    @State private var typeTick = 0
    @State private var finishedTyping = 0

    var body: some View {
        Text(revealed)
            .accessibilityLabel(text)
            .task(id: text) { await type() }
            .sensoryFeedback(.selection, trigger: typeTick) { _, tick in tick > 0 && tick % 4 == 0 }
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.65), trigger: finishedTyping)
    }

    private var revealed: AttributedString {
        var attributed = AttributedString(text)
        let count = isComplete ? text.count : min(visibleCount, text.count)
        let hiddenStart = attributed.index(attributed.startIndex, offsetByCharacters: count)
        attributed[hiddenStart...].foregroundColor = .clear
        return attributed
    }

    private func type() async {
        guard !isComplete else { return }
        if reduceMotion {
            isComplete = true
            return
        }
        visibleCount = 0
        try? await Task.sleep(for: startDelay)

        for (index, character) in text.enumerated() {
            if Task.isCancelled || isComplete { return }
            visibleCount = index + 1
            typeTick += 1
            try? await Task.sleep(for: pause(after: character))
        }
        finishedTyping += 1
        isComplete = true
    }

    private func pause(after character: Character) -> Duration {
        switch character {
        case ".", "!", "?": characterDelay * 7
        case ",": characterDelay * 4
        case "\n": characterDelay * 3
        default: characterDelay
        }
    }
}
