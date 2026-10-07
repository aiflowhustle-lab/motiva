import Foundation
import Observation
import UserNotifications

struct OnboardingProfile: Codable {
    var name: String
    var answers: [String: [String]]
    var dailyQuoteCount: Int
    var reminderStart: Date
    var reminderEnd: Date
    var trialReminder: Bool

    static let storageKey = "onboardingProfile"

    static func load() -> OnboardingProfile? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(OnboardingProfile.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}

@Observable
final class OnboardingModel {
    private static let order: [OnboardingStep] = [
        .welcome, .referral, .customize, .age, .name, .gender, .relationship, .religion, .beliefs, .zodiac,
        .sources, .consistency, .push, .achieve, .habit, .routine, .reminders, .meant,
        .quotes, .quoteStyle, .quoteAction, .mental, .vision, .rewires, .mood, .moodReason, .confront, .improve, .goals,
        .topics, .plan, .phone, .freeTrial, .trial, .offer, .widget,
    ]

    /// Screens pushed on top of the welcome screen; bound to the NavigationStack.
    var path: [OnboardingStep] = []

    var name = ""
    var selections: [OnboardingStep: [String]] = [:]
    var dailyQuoteCount = 10
    var reminderStart = OnboardingModel.time(hour: 9)
    var reminderEnd = OnboardingModel.time(hour: 22)
    var trialReminder = false

    init() {
        #if DEBUG
        // Launch with `-onboardingStep <step>` to jump straight to a screen.
        if let raw = UserDefaults.standard.string(forKey: "onboardingStep"),
           let step = OnboardingStep(rawValue: raw), step != .welcome {
            path = [step]
        }
        #endif
    }

    var step: OnboardingStep { path.last ?? .welcome }
    var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    func selected(_ option: String, in step: OnboardingStep) -> Bool {
        selections[step, default: []].contains(option)
    }

    func toggle(_ option: String, in step: OnboardingStep) {
        var current = selections[step, default: []]
        if let index = current.firstIndex(of: option) {
            current.remove(at: index)
        } else {
            current.append(option)
        }
        selections[step] = current
    }

    func pick(_ option: String, in step: OnboardingStep) {
        selections[step] = [option]
    }

    /// Moves past `step`. Ignored unless `step` is the visible screen, so a quick double tap can't skip a screen.
    func advance(from step: OnboardingStep) {
        guard step == self.step else { return }
        guard let index = Self.order.firstIndex(of: step), index + 1 < Self.order.count else { return }
        var next = Self.order[index + 1]
        if step == .religion && selections[.religion]?.first != "Yes" {
            next = .zodiac
        }
        path.append(next)
    }

    func back() {
        _ = path.popLast()
    }

    func requestNotificationsAndAdvance() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        advance(from: .reminders)
    }

    func makeProfile() -> OnboardingProfile {
        OnboardingProfile(
            name: trimmedName,
            answers: Dictionary(uniqueKeysWithValues: selections.map { ($0.key.rawValue, $0.value) }),
            dailyQuoteCount: dailyQuoteCount,
            reminderStart: reminderStart,
            reminderEnd: reminderEnd,
            trialReminder: trialReminder
        )
    }

    private static func time(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
    }
}
