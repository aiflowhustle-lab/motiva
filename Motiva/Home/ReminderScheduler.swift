import Foundation
import UserNotifications

enum ReminderScheduler {
    private static let maxReminders = 30

    private static func identifier(_ index: Int) -> String { "motiva.reminder.\(index)" }

    /// Replaces the daily quote notifications, spreading `count` reminders evenly between the start and end times.
    static func schedule(_ settings: ReminderSettings, quotes: [String]) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<maxReminders).map(identifier))
        guard settings.enabled, !quotes.isEmpty else { return }

        for (index, time) in times(for: settings).enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Motiva"
            content.body = quotes[index % quotes.count].replacingOccurrences(of: "\n", with: " ")
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
            try? await center.add(UNNotificationRequest(identifier: identifier(index), content: content, trigger: trigger))
        }
    }

    /// The time of day for each reminder, spaced evenly from start to end. An end at or before the start wraps past midnight.
    static func times(for settings: ReminderSettings, calendar: Calendar = .current) -> [DateComponents] {
        let count = min(settings.count, maxReminders)
        guard count > 0 else { return [] }

        let minutesPerDay = 24 * 60
        let start = calendar.component(.hour, from: settings.start) * 60 + calendar.component(.minute, from: settings.start)
        var end = calendar.component(.hour, from: settings.end) * 60 + calendar.component(.minute, from: settings.end)
        if end <= start { end += minutesPerDay }
        let spansWholeDay = end - start == minutesPerDay

        return (0..<count).map { index in
            let offset: Int
            if count == 1 {
                offset = 0
            } else if spansWholeDay {
                offset = minutesPerDay * index / count
            } else {
                offset = (end - start) * index / (count - 1)
            }
            let minute = (start + offset) % minutesPerDay
            return DateComponents(hour: minute / 60, minute: minute % 60)
        }
    }

    static func isDenied() async -> Bool {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied
    }
}
