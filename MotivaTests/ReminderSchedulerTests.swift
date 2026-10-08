import Foundation
import Testing
@testable import Motiva

struct ReminderSchedulerTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func settings(count: Int, from start: (Int, Int), to end: (Int, Int)) -> ReminderSettings {
        let day = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7))!
        return ReminderSettings(
            enabled: true,
            count: count,
            start: calendar.date(bySettingHour: start.0, minute: start.1, second: 0, of: day)!,
            end: calendar.date(bySettingHour: end.0, minute: end.1, second: 0, of: day)!
        )
    }

    private func clock(_ times: [DateComponents]) -> [String] {
        times.map { String(format: "%02d:%02d", $0.hour ?? -1, $0.minute ?? -1) }
    }

    @Test func singleReminderFiresAtTheStartTime() {
        let times = ReminderScheduler.times(for: settings(count: 1, from: (9, 30), to: (22, 0)), calendar: calendar)
        #expect(clock(times) == ["09:30"])
    }

    @Test func remindersSpanStartToEndEvenly() {
        let times = ReminderScheduler.times(for: settings(count: 3, from: (9, 0), to: (21, 0)), calendar: calendar)
        #expect(clock(times) == ["09:00", "15:00", "21:00"])
    }

    @Test func defaultOnboardingSettingsStartAndEndOnTime() {
        let times = clock(ReminderScheduler.times(for: settings(count: 10, from: (9, 0), to: (22, 0)), calendar: calendar))
        #expect(times.count == 10)
        #expect(times.first == "09:00")
        #expect(times.last == "22:00")
        #expect(times == times.sorted())
    }

    @Test func endBeforeStartWrapsPastMidnight() {
        let times = ReminderScheduler.times(for: settings(count: 3, from: (22, 0), to: (2, 0)), calendar: calendar)
        #expect(clock(times) == ["22:00", "00:00", "02:00"])
    }

    @Test func sameStartAndEndSpreadsAcrossTheWholeDayWithoutDuplicates() {
        let times = clock(ReminderScheduler.times(for: settings(count: 4, from: (8, 0), to: (8, 0)), calendar: calendar))
        #expect(times == ["08:00", "14:00", "20:00", "02:00"])
        #expect(Set(times).count == times.count)
    }

    @Test func countIsCappedAtThirty() {
        let times = ReminderScheduler.times(for: settings(count: 100, from: (0, 0), to: (23, 59)), calendar: calendar)
        #expect(times.count == 30)
    }

    @Test func zeroRemindersSchedulesNothing() {
        #expect(ReminderScheduler.times(for: settings(count: 0, from: (9, 0), to: (22, 0)), calendar: calendar).isEmpty)
    }

    @Test func trialReminderFiresOneDayBeforeTheTrialEnds() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(ReminderScheduler.trialReminderDate(trialDays: 3, now: now, calendar: calendar)
                == calendar.date(byAdding: .day, value: 2, to: now))
        #expect(ReminderScheduler.trialReminderDate(trialDays: 1, now: now, calendar: calendar) == nil)
    }
}
