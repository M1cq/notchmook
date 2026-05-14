import AppKit
import SwiftUI

struct NookDisplayMetrics: Equatable {
    var expandedSize: CGSize
    var contentHeight: CGFloat
    var collapsedMediaSize: CGSize
    var collapsedMediaPeekSize: CGSize
    var collapsedIdleSize: CGSize
    var collapsedIdlePeekSize: CGSize

    static let thirteen = NookDisplayMetrics(
        expandedSize: CGSize(width: 590, height: 116),
        contentHeight: 64,
        collapsedMediaSize: CGSize(width: 272, height: 34),
        collapsedMediaPeekSize: CGSize(width: 300, height: 40),
        collapsedIdleSize: CGSize(width: 112, height: 24),
        collapsedIdlePeekSize: CGSize(width: 158, height: 32)
    )

    static let fourteen = NookDisplayMetrics(
        expandedSize: CGSize(width: 640, height: 124),
        contentHeight: 70,
        collapsedMediaSize: CGSize(width: 292, height: 36),
        collapsedMediaPeekSize: CGSize(width: 326, height: 42),
        collapsedIdleSize: CGSize(width: 122, height: 26),
        collapsedIdlePeekSize: CGSize(width: 172, height: 34)
    )

    static let fifteen = NookDisplayMetrics(
        expandedSize: CGSize(width: 690, height: 128),
        contentHeight: 74,
        collapsedMediaSize: CGSize(width: 318, height: 38),
        collapsedMediaPeekSize: CGSize(width: 356, height: 44),
        collapsedIdleSize: CGSize(width: 132, height: 28),
        collapsedIdlePeekSize: CGSize(width: 188, height: 36)
    )
}

enum NookTheme: String, CaseIterable, Identifiable {
    case black
    case dusk
    case graphite
    case ocean
    case ember

    var id: String { rawValue }

    var title: String {
        switch self {
        case .black: "Black"
        case .dusk: "Dusk"
        case .graphite: "Graphite"
        case .ocean: "Ocean"
        case .ember: "Ember"
        }
    }

    var gradient: [Color] {
        switch self {
        case .black:
            [
                Color.black,
                Color.black
            ]
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
        case .black: Color(red: 0.88, green: 0.90, blue: 0.92)
        case .dusk: Color(red: 0.56, green: 0.42, blue: 1.0)
        case .graphite: Color(red: 0.74, green: 0.78, blue: 0.82)
        case .ocean: Color(red: 0.25, green: 0.78, blue: 0.92)
        case .ember: Color(red: 1.0, green: 0.48, blue: 0.30)
        }
    }

    var albumGradient: [Color] {
        switch self {
        case .black:
            [
                Color(red: 0.12, green: 0.12, blue: 0.12),
                Color(red: 0.02, green: 0.02, blue: 0.02),
                Color.black
            ]
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

enum NookLayout: String, CaseIterable, Identifiable {
    case classic
    case musicLarge
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: "Classic"
        case .musicLarge: "Music"
        case .custom: "Custom"
        }
    }

    var systemImage: String {
        switch self {
        case .classic: "rectangle.3.group"
        case .musicLarge: "music.note"
        case .custom: "slider.horizontal.3"
        }
    }
}

enum NookWidgetKind: String, CaseIterable, Identifiable, Codable {
    case actions
    case media
    case calendar
    case mirror
    case shortcuts
    case notes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .actions: "Actions"
        case .media: "Media"
        case .calendar: "Calendar"
        case .mirror: "Mirror"
        case .shortcuts: "Quick"
        case .notes: "Notes"
        }
    }

    var subtitle: String {
        switch self {
        case .actions: "Nook buttons"
        case .media: "Now Playing"
        case .calendar: "Events"
        case .mirror: "Camera"
        case .shortcuts: "Shortcuts"
        case .notes: "Scratch notes"
        }
    }

    var symbol: String {
        switch self {
        case .actions: "sparkles"
        case .media: "music.note"
        case .calendar: "calendar"
        case .mirror: "camera.fill"
        case .shortcuts: "bolt.fill"
        case .notes: "note.text"
        }
    }

    var defaultWeight: Double {
        switch self {
        case .actions: 1.15
        case .media: 1.55
        case .calendar: 1.25
        case .mirror: 0.62
        case .shortcuts: 1.10
        case .notes: 1.10
        }
    }
}

struct NookWidgetConfig: Identifiable, Codable, Equatable {
    var id: NookWidgetKind { kind }
    var kind: NookWidgetKind
    var isEnabled: Bool
    var weight: Double
    var order: Int

    static let defaults: [NookWidgetConfig] = [
        NookWidgetConfig(kind: .actions, isEnabled: true, weight: NookWidgetKind.actions.defaultWeight, order: 0),
        NookWidgetConfig(kind: .media, isEnabled: true, weight: NookWidgetKind.media.defaultWeight, order: 1),
        NookWidgetConfig(kind: .calendar, isEnabled: true, weight: NookWidgetKind.calendar.defaultWeight, order: 2),
        NookWidgetConfig(kind: .mirror, isEnabled: true, weight: NookWidgetKind.mirror.defaultWeight, order: 3),
        NookWidgetConfig(kind: .shortcuts, isEnabled: false, weight: NookWidgetKind.shortcuts.defaultWeight, order: 4),
        NookWidgetConfig(kind: .notes, isEnabled: false, weight: NookWidgetKind.notes.defaultWeight, order: 5)
    ]
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
        case "yellow": .yellow
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
        NookActionConfig(title: "Finder", subtitle: "Home folder", symbol: "folder", tintName: "blue", kind: "builtIn", value: "openFinder"),
        NookActionConfig(title: "Downloads", subtitle: "Open folder", symbol: "arrow.down.circle", tintName: "green", kind: "builtIn", value: "openDownloads"),
        NookActionConfig(title: "Shortcuts", subtitle: "Apple Shortcuts", symbol: "sparkles.rectangle.stack", tintName: "purple", kind: "builtIn", value: "openShortcuts"),
        NookActionConfig(title: "Screenshot", subtitle: "Capture tool", symbol: "camera.viewfinder", tintName: "yellow", kind: "builtIn", value: "openScreenshot"),
        NookActionConfig(title: "Settings", subtitle: "System app", symbol: "gearshape", tintName: "gray", kind: "builtIn", value: "openSystemSettings"),
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
