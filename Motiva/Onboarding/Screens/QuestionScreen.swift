import SwiftUI

struct QuestionScreen: View {
    let model: OnboardingModel
    let step: OnboardingStep
    let question: Question

    @State private var appeared = false
    @State private var chosen: String?

    /// Single-answer questions without a Continue button move on as soon as an option is tapped.
    private var advancesOnTap: Bool { !question.hasContinueButton && !question.showsSelectionCircle }

    var body: some View {
        if question.hasContinueButton {
            ScrollingScreen {
                content
            } footer: {
                Button("Continue") { model.advance(from: step) }.buttonStyle(.primary)
            }
        } else {
            ScrollView {
                content.padding(.bottom, 25)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .onAppear {
                chosen = nil
                appeared = true
            }
            .sensoryFeedback(.selection, trigger: chosen) { _, new in new != nil }
        }
    }

    /// Delays the entrance on tap-to-advance screens; other screens show immediately.
    private func entrance(_ delay: Double) -> Double? {
        advancesOnTap ? delay : nil
    }

    private var content: some View {
        VStack(spacing: 0) {
            Text(question.title(for: model.name))
                .titleStyle()
                .frame(minHeight: 34)
                .padding(.top, 15)
                .padding(.bottom, question.subtitle != nil ? 15 : (step == .zodiac ? 46 : 31))
                .staggeredReveal(appeared, delay: entrance(0.15))

            if let subtitle = question.subtitle {
                Text(subtitle)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.motivaMuted)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 28)
            }

            VStack(spacing: 13) {
                ForEach(Array(question.options.enumerated()), id: \.element) { index, option in
                    choice(option, index: index)
                        .staggeredReveal(appeared, delay: entrance(0.3 + Double(index) * 0.07))
                }
            }
        }
    }

    private func choice(_ option: String, index: Int) -> some View {
        let selected = model.selected(option, in: step)
        let highlighted = advancesOnTap && (chosen == option || (chosen == nil && selected))
        return Button {
            if advancesOnTap {
                choose(option)
            } else if question.multi {
                model.toggle(option, in: step)
            } else if question.circle {
                model.pick(option, in: step)
            }
        } label: {
            HStack(spacing: 14) {
                leadingIcon(index: index)
                Text(option)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if question.showsSelectionCircle {
                    SelectionCircle(selected: selected)
                }
                if highlighted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .bold))
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 21)
            .padding(.vertical, 16)
        }
        .buttonStyle(ChoiceButtonStyle(highlighted: highlighted))
        .scaleEffect(chosen == option ? 1.02 : 1)
        .opacity(chosen != nil && chosen != option ? 0.45 : 1)
        .animation(.spring(duration: 0.35, bounce: 0.3), value: chosen)
        .accessibilityAddTraits((question.showsSelectionCircle && selected) || highlighted ? .isSelected : [])
    }

    private func choose(_ option: String) {
        guard chosen == nil else { return }
        model.pick(option, in: step)
        chosen = option
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            model.advance(from: step)
        }
    }

    @ViewBuilder
    private func leadingIcon(index: Int) -> some View {
        if step == .zodiac {
            Text(OnboardingContent.zodiacSymbols[index])
                .font(.custom("Arial", size: 34))
                .frame(width: 33)
                .accessibilityHidden(true)
        }
        switch question.icons {
        case .mood:
            MouthIcon(kind: index)
        case .reason:
            symbol(OnboardingContent.reasonSymbols[index])
        case .improve:
            symbol(OnboardingContent.improveSymbols[index])
        case nil:
            EmptyView()
        }
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 22, weight: .light))
            .frame(width: 30, height: 30)
            .accessibilityHidden(true)
    }
}

struct SelectionCircle: View {
    let selected: Bool

    var body: some View {
        ZStack {
            if selected {
                Circle().fill(Color.motivaPrimary)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white)
            } else {
                Circle().strokeBorder(Color.motivaBorder, lineWidth: 1.5)
            }
        }
        .frame(width: 27, height: 27)
        .accessibilityHidden(true)
    }
}
