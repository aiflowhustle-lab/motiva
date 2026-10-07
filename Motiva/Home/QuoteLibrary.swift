import Foundation

struct QuoteTopic: Identifiable, Hashable {
    let name: String
    let symbol: String
    let quotes: [String]
    var id: String { name }
}

enum QuoteLibrary {
    static let featured = [
        "Investing in yourself is\nnever a gamble.",
        "I feed my spirit.\nI train my body.\nI focus my mind.\nThis is my time.",
        "You are allowed to be both\na masterpiece and\na work in progress.",
        "Small steps are still\nsteps forward.",
        "Be where your feet are.",
        "Your peace is worth\nprotecting.",
        "You have not come this far\nto only come this far.",
        "Make room for the person\nyou are becoming.",
    ]

    static let topics: [QuoteTopic] = [
        QuoteTopic(name: "Feeling sassy", symbol: "sunglasses", quotes: [
            "I’m not for everyone,\nand that’s the point.",
            "Confidence looks\ngood on me.",
            "I didn’t come this far\nto blend in.",
            "My vibe is\nnon-negotiable.",
            "Be the energy\nyou want to attract.",
        ]),
        QuoteTopic(name: "Self-respect", symbol: "leaf", quotes: [
            "No is a\ncomplete sentence.",
            "I teach people how to treat me\nby what I accept.",
            "Protect your energy\nlike it’s rent money.",
            "Walking away is also\na form of strength.",
            "I am worthy of the effort\nI give to others.",
        ]),
        QuoteTopic(name: "Being present", symbol: "timer", quotes: [
            "This moment is enough.",
            "Breathe in.\nYou are here.\nThat matters.",
            "Slow down.\nLife isn’t a race.",
            "Notice the small things.\nThey’re the big things.",
            "Today is the only day\nyou can change.",
        ]),
        QuoteTopic(name: "Unconditional love", symbol: "heart.circle", quotes: [
            "Love is a verb.\nShow it today.",
            "Be gentle with the people\nwho are trying.",
            "The love you give\nalways finds its way back.",
            "Kindness is never\nwasted.",
            "Love yourself first,\nthe rest follows.",
        ]),
        QuoteTopic(name: "Personal growth", symbol: "sparkles", quotes: [
            "Growth is uncomfortable\nbecause it’s new.",
            "Every expert was once\na beginner.",
            "You don’t have to be great\nto start.",
            "Progress, not perfection.",
            "Outgrowing things is\na sign you’re growing.",
        ]),
        QuoteTopic(name: "Confidence", symbol: "flame", quotes: [
            "Doubt kills more dreams\nthan failure ever will.",
            "Act like the person\nyou want to become.",
            "You are capable of\nmore than you know.",
            "Stand tall.\nYou earned your place.",
            "Believe it,\nthen become it.",
        ]),
        QuoteTopic(name: "Motivation", symbol: "quote.opening", quotes: [
            "Discipline is choosing\nwhat you want most\nover what you want now.",
            "Start where you are.\nUse what you have.\nDo what you can.",
            "One day or day one.\nYou decide.",
            "Done is better\nthan perfect.",
            "The best time to start\nwas yesterday.\nThe next best is now.",
        ]),
    ]

    /// The mixed feed shown when no topic is selected: featured quotes first, then every topic interleaved.
    static let forYou: [String] = {
        var mixed = featured
        let longest = topics.map(\.quotes.count).max() ?? 0
        for index in 0..<longest {
            for topic in topics where index < topic.quotes.count {
                mixed.append(topic.quotes[index])
            }
        }
        return mixed
    }()

    static func quotes(for topicName: String?) -> [String] {
        guard let topicName, let topic = topics.first(where: { $0.name == topicName }) else { return forYou }
        return topic.quotes
    }
}
