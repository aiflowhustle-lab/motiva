import SwiftUI

struct OnboardingView: View {
    var onFinish: (OnboardingProfile) -> Void

    @State private var model = OnboardingModel()

    var body: some View {
        NavigationStack(path: $model.path) {
            page(.welcome)
                .navigationDestination(for: OnboardingStep.self, destination: page)
        }
        .preferredColorScheme(model.step.usesDarkBackground ? .dark : .light)
    }

    private func page(_ step: OnboardingStep) -> some View {
        let dark = step.usesDarkBackground
        return VStack(spacing: 0) {
            if step.showsNavigationBar {
                navigationBar(for: step)
            }
            screen(for: step)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, Metrics.screenPadding)
        .foregroundStyle(dark ? Color.white : Color.motivaForeground)
        .background((dark ? Color.motivaDark : Color.motivaBackground).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func navigationBar(for step: OnboardingStep) -> some View {
        HStack {
            Button {
                model.back()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .frame(width: 44, height: 44, alignment: .leading)
                    .opacity(0.65)
            }
            .accessibilityLabel("Go back")

            Spacer()

            if step.showsSkip {
                Button("Skip") { model.advance(from: step) }
                    .font(.system(size: 16))
                    .padding(.trailing, 7)
            }
        }
        .buttonStyle(.quiet)
        .frame(height: 47)
    }

    @ViewBuilder
    private func screen(for step: OnboardingStep) -> some View {
        let next = { model.advance(from: step) }
        switch step {
        case .welcome, .customize, .achieve, .quotes:
            IntroScreen(step: step, onContinue: next)
        case .name:
            NameScreen(model: model)
        case .routine:
            RoutineScreen(onContinue: next)
        case .reminders:
            RemindersScreen(model: model)
        case .meant, .phone, .freeTrial, .trial:
            StatementScreen(step: step, name: model.trimmedName, onContinue: next)
        case .topics:
            TopicsScreen(model: model)
        case .plan:
            PlanScreen(model: model)
        case .offer:
            TrialOfferScreen(trialReminder: $model.trialReminder, onClose: next)
        case .widget:
            WidgetScreen { onFinish(model.makeProfile()) }
        default:
            if let question = OnboardingContent.questions[step] {
                QuestionScreen(model: model, step: step, question: question)
            }
        }
    }
}

#Preview {
    OnboardingView { _ in }
        .environment(SubscriptionStore())
}
