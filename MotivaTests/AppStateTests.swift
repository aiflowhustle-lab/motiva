import Foundation
import Testing
@testable import Motiva

struct AppStateTests {
    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: "MotivaTests-\(UUID().uuidString)")!
    }

    private func calendar(_ timeZone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone)!
        return calendar
    }

    private func date(_ string: String, in timeZone: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: timeZone)
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: string)!
    }

    // MARK: Streak

    @Test func firstOpenStartsAStreak() {
        let app = AppState(defaults: defaults)
        let la = calendar("America/Los_Angeles")
        #expect(app.registerOpen(now: date("2026-10-07 09:00", in: la.timeZone.identifier), calendar: la))
        #expect(app.streakCount == 1)
    }

    @Test func openingAgainTheSameDayDoesNotCount() {
        let app = AppState(defaults: defaults)
        let la = calendar("America/Los_Angeles")
        app.registerOpen(now: date("2026-10-07 00:05", in: "America/Los_Angeles"), calendar: la)
        #expect(!app.registerOpen(now: date("2026-10-07 23:55", in: "America/Los_Angeles"), calendar: la))
        #expect(app.streakCount == 1)
    }

    @Test func consecutiveDaysIncrease() {
        let app = AppState(defaults: defaults)
        let la = calendar("America/Los_Angeles")
        app.registerOpen(now: date("2026-10-07 23:59", in: "America/Los_Angeles"), calendar: la)
        app.registerOpen(now: date("2026-10-08 00:01", in: "America/Los_Angeles"), calendar: la)
        app.registerOpen(now: date("2026-10-09 12:00", in: "America/Los_Angeles"), calendar: la)
        #expect(app.streakCount == 3)
    }

    @Test func missingADayResetsToOne() {
        let app = AppState(defaults: defaults)
        let la = calendar("America/Los_Angeles")
        app.registerOpen(now: date("2026-10-07 09:00", in: "America/Los_Angeles"), calendar: la)
        app.registerOpen(now: date("2026-10-08 09:00", in: "America/Los_Angeles"), calendar: la)
        app.registerOpen(now: date("2026-10-10 09:00", in: "America/Los_Angeles"), calendar: la)
        #expect(app.streakCount == 1)
    }

    @Test(arguments: [
        ("2026-03-07 22:00", "2026-03-08 22:00"),
        ("2026-10-31 22:00", "2026-11-01 22:00"),
    ])
    func daylightSavingChangesDoNotBreakTheStreak(first: String, second: String) {
        let app = AppState(defaults: defaults)
        let la = calendar("America/Los_Angeles")
        app.registerOpen(now: date(first, in: "America/Los_Angeles"), calendar: la)
        app.registerOpen(now: date(second, in: "America/Los_Angeles"), calendar: la)
        #expect(app.streakCount == 2)
    }

    @Test func flyingEastToTheNextDayContinuesTheStreak() {
        let app = AppState(defaults: defaults)
        app.registerOpen(now: date("2026-10-07 09:00", in: "America/Los_Angeles"), calendar: calendar("America/Los_Angeles"))
        app.registerOpen(now: date("2026-10-08 20:00", in: "Asia/Tokyo"), calendar: calendar("Asia/Tokyo"))
        #expect(app.streakCount == 2)
    }

    @Test func flyingWestBackIntoYesterdayDoesNotResetTheStreak() {
        let app = AppState(defaults: defaults)
        app.registerOpen(now: date("2026-10-08 08:00", in: "Asia/Tokyo"), calendar: calendar("Asia/Tokyo"))
        #expect(!app.registerOpen(now: date("2026-10-07 18:00", in: "America/Los_Angeles"), calendar: calendar("America/Los_Angeles")))
        #expect(app.streakCount == 1)
    }

    // MARK: Persistence

    @Test func stateSurvivesRelaunch() {
        let app = AppState(defaults: defaults)
        app.toggleFavorite("Be where your feet are.")
        app.theme = .forest
        app.topic = "Confidence"
        app.registerOpen(now: date("2026-10-07 09:00", in: "America/Los_Angeles"), calendar: calendar("America/Los_Angeles"))

        let relaunched = AppState(defaults: defaults)
        #expect(relaunched.favorites == ["Be where your feet are."])
        #expect(relaunched.theme == .forest)
        #expect(relaunched.topic == "Confidence")
        #expect(relaunched.streakCount == 1)
    }

    @Test func savedDataMissingNewerFieldsStillLoads() throws {
        let olderVersion = #"{"favorites":["Small steps are still\nsteps forward."],"theme":"paper"}"#
        defaults.set(Data(olderVersion.utf8), forKey: "appState")

        let app = AppState(defaults: defaults)
        #expect(app.favorites == ["Small steps are still\nsteps forward."])
        #expect(app.theme == .paper)
        #expect(app.streakCount == 0)
    }

    @Test func historyKeepsMostRecentFirstWithoutDuplicates() {
        let app = AppState(defaults: defaults)
        app.visit("A")
        app.visit("B")
        app.visit("A")
        #expect(app.history == ["A", "B"])
    }

    @Test func historyIsCapped() {
        let app = AppState(defaults: defaults)
        for index in 0..<(AppState.historyLimit + 20) {
            app.visit("Quote \(index)")
        }
        #expect(app.history.count == AppState.historyLimit)
        #expect(app.history.first == "Quote \(AppState.historyLimit + 19)")
    }

    @Test func resetClearsEverything() {
        let app = AppState(defaults: defaults)
        app.toggleFavorite("A")
        app.theme = .paper
        app.reset()
        #expect(app.favorites.isEmpty)
        #expect(app.theme == .classic)
        #expect(AppState(defaults: defaults).favorites.isEmpty)
    }
}
