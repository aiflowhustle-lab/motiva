import Foundation
import Observation
import SwiftUI

enum FeedTheme: String, Codable, CaseIterable, Identifiable {
    case classic, paper, forest

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classic: "Classic"
        case .paper: "Paper"
        case .forest: "Forest"
        }
    }

    var background: Color {
        switch self {
        case .classic: Color(hex: 0x131313)
        case .paper: Color(hex: 0xF2F2F2)
        case .forest: Color(hex: 0x17271E)
        }
    }

    var foreground: Color { self == .paper ? .motivaForeground : Color(hex: 0xFCFCFC) }
    var pill: Color { self == .paper ? Color(hex: 0xDBDBDB) : Color.white.opacity(0.08) }
    var track: Color { self == .paper ? Color(hex: 0xBDBDBD) : Color.white.opacity(0.28) }
    var control: Color { self == .paper ? Color(hex: 0xDBDBDB) : Color.white.opacity(0.16) }
    var isDark: Bool { self != .paper }
}

struct ReminderSettings: Codable, Equatable {
    var enabled = true
    var count = 10
    var start = ReminderSettings.time(hour: 9)
    var end = ReminderSettings.time(hour: 22)

    static func time(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
    }
}

/// A day on the calendar, independent of time zone, so travelling doesn't shift which day was last counted.
struct CalendarDay: Codable, Equatable {
    var year: Int
    var month: Int
    var day: Int

    init(_ date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        year = components.year ?? 0
        month = components.month ?? 0
        day = components.day ?? 0
    }

    func days(until other: CalendarDay, calendar: Calendar) -> Int {
        guard let start = calendar.date(from: DateComponents(year: year, month: month, day: day)),
              let end = calendar.date(from: DateComponents(year: other.year, month: other.month, day: other.day))
        else { return 0 }
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
}

@Observable
final class AppState {
    private struct Stored: Codable {
        var favorites: [String] = []
        var ownQuotes: [String] = []
        var history: [String] = []
        var theme: FeedTheme = .classic
        var topic: String?
        var streakCount = 0
        var streakDay: CalendarDay?
        var reminders = ReminderSettings()

        init() {}

        /// Missing or unreadable fields fall back to defaults, so adding a field in an update doesn't wipe saved data.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let fallback = Stored()
            favorites = (try? container.decodeIfPresent([String].self, forKey: .favorites)) ?? fallback.favorites
            ownQuotes = (try? container.decodeIfPresent([String].self, forKey: .ownQuotes)) ?? fallback.ownQuotes
            history = (try? container.decodeIfPresent([String].self, forKey: .history)) ?? fallback.history
            theme = (try? container.decodeIfPresent(FeedTheme.self, forKey: .theme)) ?? fallback.theme
            topic = (try? container.decodeIfPresent(String.self, forKey: .topic)) ?? fallback.topic
            streakCount = (try? container.decodeIfPresent(Int.self, forKey: .streakCount)) ?? fallback.streakCount
            streakDay = (try? container.decodeIfPresent(CalendarDay.self, forKey: .streakDay)) ?? fallback.streakDay
            reminders = (try? container.decodeIfPresent(ReminderSettings.self, forKey: .reminders)) ?? fallback.reminders
        }
    }

    private static let storageKey = "appState"
    static let historyLimit = 100

    private let defaults: UserDefaults

    var favorites: [String] { didSet { save() } }
    var ownQuotes: [String] { didSet { save() } }
    private(set) var history: [String] { didSet { save() } }
    var theme: FeedTheme { didSet { save() } }
    var topic: String? { didSet { save() } }
    private(set) var streakCount: Int { didSet { save() } }
    private(set) var streakDay: CalendarDay? { didSet { save() } }
    var reminders: ReminderSettings { didSet { save() } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.data(forKey: Self.storageKey)
            .flatMap { try? JSONDecoder().decode(Stored.self, from: $0) } ?? Stored()
        favorites = stored.favorites
        ownQuotes = stored.ownQuotes
        history = stored.history
        theme = stored.theme
        topic = stored.topic
        streakCount = stored.streakCount
        streakDay = stored.streakDay
        reminders = stored.reminders
    }

    func isFavorite(_ quote: String) -> Bool { favorites.contains(quote) }

    func toggleFavorite(_ quote: String) {
        if let index = favorites.firstIndex(of: quote) {
            favorites.remove(at: index)
        } else {
            favorites.append(quote)
        }
    }

    func visit(_ quote: String) {
        var updated = history.filter { $0 != quote }
        updated.insert(quote, at: 0)
        history = Array(updated.prefix(Self.historyLimit))
    }

    /// Counts today toward the streak. Returns true the first time it's called on a new day.
    @discardableResult
    func registerOpen(now: Date = .now, calendar: Calendar = .current) -> Bool {
        let today = CalendarDay(now, calendar: calendar)
        if let last = streakDay {
            let days = last.days(until: today, calendar: calendar)
            if days <= 0 { return false }
            streakCount = days == 1 ? streakCount + 1 : 1
        } else {
            streakCount = 1
        }
        streakDay = today
        return true
    }

    func applyOnboarding(_ profile: OnboardingProfile) {
        reminders = ReminderSettings(
            enabled: true,
            count: profile.dailyQuoteCount,
            start: profile.reminderStart,
            end: profile.reminderEnd
        )
    }

    func clearHistory(_ quotes: [String]) {
        history.removeAll { quotes.contains($0) }
    }

    func reset() {
        let fresh = Stored()
        favorites = fresh.favorites
        ownQuotes = fresh.ownQuotes
        history = fresh.history
        theme = fresh.theme
        topic = fresh.topic
        streakCount = fresh.streakCount
        streakDay = fresh.streakDay
        reminders = fresh.reminders
        defaults.removeObject(forKey: Self.storageKey)
    }

    private func save() {
        var stored = Stored()
        stored.favorites = favorites
        stored.ownQuotes = ownQuotes
        stored.history = history
        stored.theme = theme
        stored.topic = topic
        stored.streakCount = streakCount
        stored.streakDay = streakDay
        stored.reminders = reminders
        guard let data = try? JSONEncoder().encode(stored) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
