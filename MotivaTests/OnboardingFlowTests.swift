import Testing
@testable import Motiva

struct OnboardingFlowTests {
    @Test func welcomeAdvancesToAge() {
        let model = OnboardingModel()
        model.advance(from: .welcome)
        #expect(model.step == .age)
    }

    @Test func relationshipAdvancesToSources() {
        let model = OnboardingModel()
        model.path = [.relationship]
        model.advance(from: .relationship)
        #expect(model.step == .sources)
    }

    @Test func advancingFromAScreenThatIsNoLongerVisibleIsIgnored() {
        let model = OnboardingModel()
        model.advance(from: .welcome)
        model.advance(from: .welcome)
        #expect(model.path == [.age])
    }

    @Test func backReturnsToThePreviousScreen() {
        let model = OnboardingModel()
        model.advance(from: .welcome)
        model.advance(from: .age)
        model.back()
        #expect(model.step == .age)
    }

    @Test func startAtJumpsDirectlyToAStep() {
        let model = OnboardingModel(startAt: .reminders)
        #expect(model.path == [.reminders])
        #expect(OnboardingModel(startAt: .welcome).path.isEmpty)
    }

    @Test func walkingTheWholeFlowEndsOnWidgetAndVisitsEveryScreenOnce() {
        let model = OnboardingModel()
        var visited = [model.step]
        while model.step != .widget {
            model.advance(from: model.step)
            visited.append(model.step)
            #expect(visited.count <= OnboardingStep.allCases.count, "Flow did not reach the widget step")
            if visited.count > OnboardingStep.allCases.count { return }
        }
        #expect(Set(visited) == Set(OnboardingStep.allCases))
        #expect(visited.count == OnboardingStep.allCases.count)
    }

    @Test func togglingTwiceDeselects() {
        let model = OnboardingModel()
        model.toggle("Work", in: .sources)
        model.toggle("Work", in: .sources)
        #expect(!model.selected("Work", in: .sources))
    }

    @Test func titleIncludesTrimmedName() {
        let question = OnboardingContent.questions[.gender]!
        #expect(question.title(for: "  Sam ") == "Which option represents\nyou best, Sam?")
        #expect(question.title(for: "   ") == "Which option represents\nyou best?")
    }

    @Test func everyQuestionStepHasContent() {
        let questionSteps: [OnboardingStep] = [
            .age, .gender, .relationship, .sources, .consistency, .push, .habit,
            .quoteStyle, .quoteAction, .mental, .vision, .rewires, .mood, .moodReason, .confront, .improve, .goals,
        ]
        for step in questionSteps {
            #expect(OnboardingContent.questions[step]?.options.isEmpty == false, "\(step) has no options")
        }
        #expect(Set(OnboardingContent.questions.keys) == Set(questionSteps))
    }
}
