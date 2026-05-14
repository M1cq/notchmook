import AppKit
import SwiftUI

struct ShortcutProvider {
    weak var model: NookModel?

    func shortcuts(customItems: [CustomShortcutItem]) -> [NookShortcut] {
        customItems.map { item in
            NookShortcut(
                title: item.title,
                subtitle: "Run Shortcut",
                symbol: item.symbol,
                tint: item.tint,
                action: { Self.runShortcut(named: item.shortcutName) }
            )
        } + builtInShortcuts
    }

    var builtInShortcuts: [NookShortcut] {
        [
            NookShortcut(
                title: "Music",
                subtitle: "Open player",
                symbol: "music.note",
                tint: .pink,
                action: { openApp(named: "Music") }
            ),
            NookShortcut(
                title: "Calendar",
                subtitle: "Open schedule",
                symbol: "calendar",
                tint: .orange,
                action: { openApp(named: "Calendar") }
            ),
            NookShortcut(
                title: "Shortcuts",
                subtitle: "Automation hub",
                symbol: "sparkles",
                tint: .purple,
                action: { openApp(named: "Shortcuts") }
            ),
            NookShortcut(
                title: "AirDrop",
                subtitle: "Share tray files",
                symbol: "antenna.radiowaves.left.and.right",
                tint: .cyan,
                action: { AirDropService.share(model?.trayItems.map(\.url) ?? []) }
            ),
            NookShortcut(
                title: "Settings",
                subtitle: "System controls",
                symbol: "gearshape",
                tint: .gray,
                action: { openApp(named: "System Settings") }
            ),
            NookShortcut(
                title: "Clear Tray",
                subtitle: "Empty temporary files",
                symbol: "trash",
                tint: .red,
                action: { model?.clearTray() }
            )
        ]
    }

    static func availableShortcutNames() -> [String] {
        processOutput(executable: "/usr/bin/shortcuts", arguments: ["list"])
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    static func runShortcut(named name: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = processOutput(executable: "/usr/bin/shortcuts", arguments: ["run", name])
        }
    }

    private func openApp(named name: String) {
        NSWorkspace.shared.open(appURL(named: name))
    }

    private func appURL(named name: String) -> URL {
        let candidates = [
            "/System/Applications/\(name).app",
            "/System/Applications/Utilities/\(name).app",
            "/Applications/\(name).app"
        ].map(URL.init(fileURLWithPath:))

        return candidates.first { FileManager.default.fileExists(atPath: $0.path) } ?? candidates[0]
    }

}

private func processOutput(executable: String, arguments: [String]) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    do {
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    } catch {
        return ""
    }
}
