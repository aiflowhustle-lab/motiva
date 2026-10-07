import Testing
@testable import Motiva

struct OnboardingFlowTests {
    @Test func welcomeAdvancesToReferral() {
        let model = OnboardingModel()
        model.advance(from: .welcome)
        #expect(model.step == .referral)
    }

    @Test(arguments: [
        ("Yes", OnboardingStep.beliefs),
        ("No", OnboardingStep.zodiac),
        ("Spiritual but not religious", OnboardingStep.zodiac),
    ])
    func religionBranches(answer: String, expected: OnboardingStep) {
        let model = OnboardingModel()
        model.path = [.religion]
        model.pick(answer, in: .religion)
        model.advance(from: .religion)
        #expect(model.step == expected)
    }

    @Test func skippingReligionGoesToZodiac() {
        let model = OnboardingModel()
        model.path = [.religion]
        model.advance(from: .religion)
        #expect(model.step == .zodiac)
    }

    @Test func advancingFromAScreenThatIsNoLongerVisibleIsIgnored() {
        let model = OnboardingModel()
        model.advance(from: .welcome)
        model.advance(from: .welcome)
        #expect(model.path == [.referral])
    }

    @Test func backReturnsToThePreviousScreen() {
        let model = OnboardingModel()
        model.advance(from: .welcome)
        model.advance(from: .referral)
        model.back()
        #expect(model.step == .referral)
    }

    @Test func walkingTheWholeFlowEndsOnWidgetAndVisitsEveryScreenOnce() {
        let model = OnboardingModel()
        model.pick("Yes", in: .religion)
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
            .referral, .age, .gender, .relationship, .religion, .beliefs, .zodiac, .sources, .consistency, .push, .habit,
            .quoteStyle, .quoteAction, .mental, .vision, .rewires, .mood, .moodReason, .confront, .improve, .goals,
        ]
        for step in questionSteps {
            #expect(OnboardingContent.questions[step]?.options.isEmpty == false, "\(step) has no options")
        }
        #expect(OnboardingContent.zodiacSymbols.count == OnboardingContent.questions[.zodiac]?.options.count)
    }
}
