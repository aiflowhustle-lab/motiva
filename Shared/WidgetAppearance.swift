import SwiftUI

enum WidgetTopicMode: String, Codable, CaseIterable, Identifiable {
    /// Blended quotes from topics you follow (or For you when none).
    case mix
    /// Full library rotation — same as home For you with no follows.
    case forYou

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mix: "Mix"
        case .forYou: "General"
        }
    }
}

enum WidgetRefreshInterval: String, Codable, CaseIterable, Identifiable {
    case hourly
    case daily

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hourly: "Hourly"
        case .daily: "Daily"
        }
    }
}

enum WidgetPreviewSize: String, CaseIterable, Identifiable {
    case small, medium, large

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        }
    }

    var previewSize: CGSize {
        switch self {
        case .small: CGSize(width: 148, height: 148)
        case .medium: CGSize(width: 318, height: 148)
        case .large: CGSize(width: 318, height: 330)
        }
    }
}
