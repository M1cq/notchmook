import ApplicationServices
import Foundation

enum AccessibilityMediaService {
    static func currentSnapshot(volume: Int) -> MediaSnapshot? {
        for pid in candidateProcessIDs() {
            if let snapshot = snapshotFromApplication(pid: pid, volume: volume) {
                return snapshot
            }
        }
        return nil
    }

    private static func candidateProcessIDs() -> [pid_t] {
        processOutput(executable: "/bin/ps", arguments: ["-axo", "pid=,command="])
            .components(separatedBy: .newlines)
            .compactMap { line -> pid_t? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.localizedCaseInsensitiveContains("YouTube Music.app")
                    || trimmed.localizedCaseInsensitiveContains("music.youtube.com")
                    || (trimmed.localizedCaseInsensitiveContains("app_mode_loader")
                        && trimmed.localizedCaseInsensitiveContains("youtube")) else {
                    return nil
                }

                let pidString = trimmed.split(separator: " ").first.map(String.init) ?? ""
                return pid_t(pidString)
            }
    }

    private static func snapshotFromApplication(pid: pid_t, volume: Int) -> MediaSnapshot? {
        let app = AXUIElementCreateApplication(pid)
        var values: [String] = []
        var visited = 0

        collectStrings(from: app, into: &values, visited: &visited, depth: 0)

        guard let title = bestTitle(from: values) else { return nil }
        return splitTitle(title, volume: volume)
    }

    private static func collectStrings(from element: AXUIElement, into values: inout [String], visited: inout Int, depth: Int) {
        guard visited < 260, depth < 8 else { return }
        visited += 1

        for attribute in [kAXTitleAttribute, kAXValueAttribute, kAXDescriptionAttribute, kAXHelpAttribute] {
            var rawValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, attribute as CFString, &rawValue) == .success,
               let string = rawValue as? String {
                append(string, into: &values)
            }
        }

        var childrenValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue) == .success,
              let children = childrenValue as? [AXUIElement] else {
            return
        }

        for child in children {
            collectStrings(from: child, into: &values, visited: &visited, depth: depth + 1)
        }
    }

    private static func append(_ string: String, into values: inout [String]) {
        let cleaned = string
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count >= 2, values.contains(cleaned) == false else { return }
        values.append(cleaned)
    }

    private static func bestTitle(from values: [String]) -> String? {
        let ignored = [
            "YouTube Music",
            "Home",
            "Explore",
            "Library",
            "Search",
            "Settings",
            "Account",
            "Play",
            "Pause",
            "Next",
            "Previous"
        ]

        let candidates = values.filter { value in
            ignored.contains(where: { value.caseInsensitiveCompare($0) == .orderedSame }) == false
        }

        if let title = candidates.first(where: { $0.localizedCaseInsensitiveContains(" - YouTube Music") }) {
            return title.replacingOccurrences(of: " - YouTube Music", with: "")
        }
        if let title = candidates.first(where: { $0.contains(" – ") || $0.contains(" - ") }) {
            return title
        }
        if let title = candidates.first(where: { $0.count > 8 && $0.count < 90 }) {
            return title
        }
        return nil
    }

    private static func splitTitle(_ rawTitle: String, volume: Int) -> MediaSnapshot {
        let separators = [" – ", " - "]
        for separator in separators where rawTitle.contains(separator) {
            let parts = rawTitle
                .components(separatedBy: separator)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }
            if parts.count >= 2 {
                return MediaSnapshot(
                    appName: "YouTube Music",
                    title: parts[0],
                    artist: parts[1],
                    state: "playing",
                    outputVolume: volume,
                    lastUpdated: Date()
                )
            }
        }

        return MediaSnapshot(
            appName: "YouTube Music",
            title: rawTitle,
            artist: "Now Playing",
            state: "playing",
            outputVolume: volume,
            lastUpdated: Date()
        )
    }

    private static func processOutput(executable: String, arguments: [String]) -> String {
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
}
