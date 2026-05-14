import AppKit
import SwiftUI

enum NookTheme: String, CaseIterable, Identifiable {
    case dusk
    case graphite
    case ocean
    case ember

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dusk: "Dusk"
        case .graphite: "Graphite"
        case .ocean: "Ocean"
        case .ember: "Ember"
        }
    }

    var gradient: [Color] {
        switch self {
        case .dusk:
            [
                Color(red: 0.22, green: 0.18, blue: 0.30),
                Color(red: 0.10, green: 0.12, blue: 0.20)
            ]
        case .graphite:
            [
                Color(red: 0.16, green: 0.17, blue: 0.18),
                Color(red: 0.04, green: 0.05, blue: 0.06)
            ]
        case .ocean:
            [
                Color(red: 0.08, green: 0.24, blue: 0.30),
                Color(red: 0.04, green: 0.09, blue: 0.18)
            ]
        case .ember:
            [
                Color(red: 0.34, green: 0.16, blue: 0.12),
                Color(red: 0.14, green: 0.07, blue: 0.08)
            ]
        }
    }

    var accent: Color {
        switch self {
        case .dusk: Color(red: 0.56, green: 0.42, blue: 1.0)
        case .graphite: Color(red: 0.74, green: 0.78, blue: 0.82)
        case .ocean: Color(red: 0.25, green: 0.78, blue: 0.92)
        case .ember: Color(red: 1.0, green: 0.48, blue: 0.30)
        }
    }

    var albumGradient: [Color] {
        switch self {
        case .dusk:
            [
                Color(red: 0.13, green: 0.06, blue: 0.24),
                Color(red: 0.54, green: 0.29, blue: 0.96),
                Color(red: 0.12, green: 0.10, blue: 0.18)
            ]
        case .graphite:
            [
                Color(red: 0.34, green: 0.36, blue: 0.38),
                Color(red: 0.12, green: 0.13, blue: 0.14),
                Color(red: 0.04, green: 0.05, blue: 0.06)
            ]
        case .ocean:
            [
                Color(red: 0.07, green: 0.37, blue: 0.48),
                Color(red: 0.16, green: 0.64, blue: 0.78),
                Color(red: 0.05, green: 0.09, blue: 0.18)
            ]
        case .ember:
            [
                Color(red: 0.50, green: 0.12, blue: 0.10),
                Color(red: 0.98, green: 0.42, blue: 0.23),
                Color(red: 0.18, green: 0.07, blue: 0.08)
            ]
        }
    }
}

enum NookTab: String, CaseIterable, Identifiable {
    case dashboard
    case tray
    case mirror
    case shortcuts
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Live"
        case .tray: "Tray"
        case .mirror: "Mirror"
        case .shortcuts: "Quick"
        case .settings: "Tune"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "waveform"
        case .tray: "tray.full"
        case .mirror: "camera.viewfinder"
        case .shortcuts: "bolt.fill"
        case .settings: "slider.horizontal.3"
        }
    }
}

struct TrayItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let addedAt = Date()

    var displayName: String {
        url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
    }

    var isDirectory: Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }
}

struct CalendarEntry: Identifiable {
    let id = UUID()
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarColor: Color
    let isAllDay: Bool
}

struct NookShortcut: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let action: () -> Void
}

struct CustomShortcutItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var shortcutName: String
    var symbol: String
    var tintName: String

    init(
        id: UUID = UUID(),
        title: String,
        shortcutName: String,
        symbol: String = "sparkles",
        tintName: String = "purple"
    ) {
        self.id = id
        self.title = title
        self.shortcutName = shortcutName
        self.symbol = symbol
        self.tintName = tintName
    }

    var tint: Color {
        switch tintName {
        case "pink": .pink
        case "orange": .orange
        case "blue": .blue
        case "green": .green
        case "cyan": .cyan
        case "red": .red
        case "gray": .gray
        default: .purple
        }
    }
}

struct NookActionConfig: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var subtitle: String
    var symbol: String
    var tintName: String
    var kind: String
    var value: String

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        symbol: String,
        tintName: String = "purple",
        kind: String,
        value: String
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.tintName = tintName
        self.kind = kind
        self.value = value
    }

    var tint: Color {
        switch tintName {
        case "pink": .pink
        case "orange": .orange
        case "blue": .blue
        case "green": .green
        case "cyan": .cyan
        case "red": .red
        case "gray": .gray
        default: .purple
        }
    }

    static let defaults = [
        NookActionConfig(
            title: "AirDrop",
            subtitle: "Share tray",
            symbol: "sparkles",
            tintName: "cyan",
            kind: "builtIn",
            value: "airDrop"
        ),
        NookActionConfig(
            title: "Open Music",
            subtitle: "Open player",
            symbol: "music.note",
            tintName: "pink",
            kind: "builtIn",
            value: "openMusic"
        )
    ]

    static let builtInOptions = [
        NookActionConfig(title: "AirDrop", subtitle: "Share tray", symbol: "sparkles", tintName: "cyan", kind: "builtIn", value: "airDrop"),
        NookActionConfig(title: "Open Music", subtitle: "Open player", symbol: "music.note", tintName: "pink", kind: "builtIn", value: "openMusic"),
        NookActionConfig(title: "Calendar", subtitle: "Open app", symbol: "calendar", tintName: "orange", kind: "builtIn", value: "openCalendar"),
        NookActionConfig(title: "Mirror", subtitle: "Camera", symbol: "camera.viewfinder", tintName: "blue", kind: "builtIn", value: "mirror"),
        NookActionConfig(title: "Clear Tray", subtitle: "Empty files", symbol: "trash", tintName: "red", kind: "builtIn", value: "clearTray")
    ]
}

struct MediaSnapshot {
    var appName = "Music"
    var title = "No media playing"
    var artist = "Open Music or Spotify"
    var state = "stopped"
    var outputVolume = 50
    var artworkURL: URL?
    var lastUpdated = Date()

    var isPlaying: Bool {
        state.lowercased() == "playing"
    }

    var hasMedia: Bool {
        title != "No media playing" && state.lowercased() != "stopped"
    }
}
