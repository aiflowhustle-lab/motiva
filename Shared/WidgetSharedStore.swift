import Foundation

enum WidgetAppGroup {
    static let identifier = "group.com.motiva.dailyquotes"
}

struct WidgetSnapshot: Codable, Equatable {
    var quotes: [String]
    var theme: String
    var updatedAt: Date

    static let storageKey = "widgetSnapshot"

    static let placeholder = WidgetSnapshot(
        quotes: [
            "Small steps are still\nsteps forward.",
            "Your peace is worth\nprotecting.",
        ],
        theme: "classic",
        updatedAt: .distantPast
    )
}

enum WidgetSharedStore {
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: WidgetAppGroup.identifier)
    }

    static func save(_ snapshot: WidgetSnapshot) {
        guard let defaults,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: WidgetSnapshot.storageKey)
    }

    static func load() -> WidgetSnapshot {
        guard let defaults,
              let data = defaults.data(forKey: WidgetSnapshot.storageKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data),
              !snapshot.quotes.isEmpty
        else { return .placeholder }
        return snapshot
    }
}
