import Foundation

enum OnboardingStep: String, Codable, Hashable, CaseIterable {
    case welcome, referral, customize, age, name, gender, relationship, religion, beliefs, zodiac
    case sources, consistency, push, achieve, habit, routine, reminders, meant
    case quotes, quoteStyle, quoteAction, mental, vision, rewires, mood, moodReason, confront, improve, goals
    case topics, plan, phone, freeTrial, trial, offer, widget, done

    var isIntro: Bool {
        [.welcome, .customize, .achieve, .quotes].contains(self)
    }

    var showsNavigationBar: Bool {
        !isIntro && ![.done, .routine, .reminders, .meant, .plan, .phone, .freeTrial, .trial, .offer, .widget].contains(self)
    }

    var showsSkip: Bool {
        guard showsNavigationBar, self != .referral else { return false }
        return !(OnboardingContent.questions[self]?.noSkip ?? false)
    }

    var usesDarkBackground: Bool { self == .meant }
}

enum QuestionIcons {
    case mood, reason, improve
}

struct Question {
    /// `{name}` is replaced with ", <name>" when the user has entered one.
    let title: String
    let options: [String]
    var multi = false
    var circle = false
    var footer = false
    var subtitle: String?
    var icons: QuestionIcons?
    var noSkip = false

    var showsSelectionCircle: Bool { multi || circle }
    var hasContinueButton: Bool { multi || footer }

    func title(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return title.replacingOccurrences(of: "{name}", with: trimmed.isEmpty ? "" : ", \(trimmed)")
    }
}

enum OnboardingContent {
    static let questions: [OnboardingStep: Question] = [
        .referral: Question(title: "How did you hear\nabout Motiva?", options: ["Facebook", "App Store", "Instagram", "TikTok", "Friend or family", "Web search", "Other"]),
        .age: Question(title: "How old are you?", options: ["13 to 17", "18 to 24", "25 to 34", "35 to 44", "45 to 54", "55+"]),
        .gender: Question(title: "Which option represents\nyou best{name}?", options: ["Female", "Male", "Other", "Prefer not to say"]),
        .relationship: Question(title: "What’s your\nrelationship status?", options: ["Single", "In a relationship", "Other"]),
        .religion: Question(title: "Are you religious?", options: ["Yes", "No", "Spiritual but not religious"]),
        .beliefs: Question(title: "Which of these best describes your beliefs?", options: ["Christianity", "Judaism", "Islam", "Hinduism", "Buddhism", "Other"]),
        .zodiac: Question(title: "What’s your Zodiac sign?", options: ["Capricorn", "Aquarius", "Pisces", "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius"]),
        .sources: Question(title: "What are your biggest\nsources of motivation?", options: ["Work", "Faith/spirituality", "Family and friends", "Self-improvement"], multi: true),
        .consistency: Question(title: "Do you struggle to stay consistent in any area?", options: ["Mental health", "Healthy habits", "School/work", "Personal relationships"], multi: true),
        .push: Question(title: "What gives you a push when you’re unmotivated?", options: ["Being inspired by someone", "Recalling past achievements", "Thinking about the future", "Support from others", "Faith or spirituality"], multi: true),
        .habit: Question(title: "What would help make motivation a daily habit?", options: ["Getting regular reminders", "Tracking my progress", "Reading quotes in the app", "A home/lock screen widget"], multi: true),
        .quoteStyle: Question(title: "What kind of quotes\ninspire you the most?", options: ["Thought-provoking and wise", "From people I admire", "Short and to the point", "Tough love", "Spiritual"], circle: true, footer: true),
        .quoteAction: Question(title: "What do you do when a quote\nreally speaks to you?", options: ["Share it", "Save it for later", "Write it down"], circle: true, footer: true),
        .mental: Question(title: "How do you improve\nyour mental health?", options: ["Therapy", "Exercise and nutrition", "Support from others", "Spending time in nature"], multi: true, subtitle: "You can select more than one option"),
        .vision: Question(title: "Do you have a clear vision\nof the life you want?", options: ["Yes, I do", "I’m working on it"]),
        .rewires: Question(title: "Do you know positive thinking\nrewires your brain?", options: ["Yes, I believe that", "I’ve heard of it, but I’m not sure"]),
        .mood: Question(title: "How have you been feeling\nlately{name}?", options: ["Awesome", "Good", "Neutral", "Bad", "Terrible", "Other"], icons: .mood, noSkip: true),
        .moodReason: Question(title: "What’s making you feel that way?", options: ["Family", "Friends", "Work", "Health", "Love", "Other"], circle: true, footer: true, icons: .reason, noSkip: true),
        .confront: Question(title: "Been avoiding anything you\nreally should confront?", options: ["Setting goals for my future", "Healing from my past", "Advancing my work and career", "Improving my financial situation"], circle: true, footer: true),
        .improve: Question(title: "What do you want\nto improve?", options: ["Stress & anxiety", "Positive thinking", "Relationships", "Faith & spirituality", "Achieving goals", "Self-esteem"], multi: true, icons: .improve, noSkip: true),
        .goals: Question(title: "What do you want to\nachieve with Motiva?", options: ["Find happiness", "Renew my energy and focus", "Be more present and enjoy life", "Accomplish my goals", "Develop a positive mindset", "Improve my self-confidence"], multi: true),
    ]

    static let zodiacSymbols = ["♑︎", "♒︎", "♓︎", "♈︎", "♉︎", "♊︎", "♋︎", "♌︎", "♍︎", "♎︎", "♏︎", "♐︎"]
    static let reasonSymbols = ["house", "person.2", "briefcase", "waveform.path.ecg", "heart", "ellipsis"]
    static let improveSymbols = ["tornado", "face.smiling", "figure.2.arms.open", "sparkle", "mountain.2", "sparkles"]

    static let topics = ["Success", "Life lessons", "Unfiltered (NSFW)", "Mental health", "Motivation", "Faith", "Love", "Mental toughness", "Deep", "Overthinking", "Affirmations"]
}
