import ApplicationServices
import AppKit
import Foundation

enum AccessibilityMediaService {
    static func currentSnapshot(volume: Int) -> MediaSnapshot? {
        for candidate in candidateApplications() {
            if let snapshot = snapshotFromApplication(candidate: candidate, volume: volume) {
                return snapshot
            }
        }
        return nil
    }

    private struct CandidateApplication {
        let pid: pid_t
        let appName: String
    }

    private static func candidateApplications() -> [CandidateApplication] {
        let running = NSWorkspace.shared.runningApplications.compactMap { application -> CandidateApplication? in
            let name = application.localizedName ?? ""
            let bundleIdentifier = application.bundleIdentifier ?? ""
            let executablePath = application.executableURL?.path ?? ""
            let matchedName: String?

            if name.localizedCaseInsensitiveContains("YouTube Music")
                || bundleIdentifier.localizedCaseInsensitiveContains("YouTubeMusic")
                || executablePath.localizedCaseInsensitiveContains("YouTube Music.app") {
                matchedName = "YouTube Music"
            } else if name == "Dia" {
                matchedName = "Dia"
            } else if name == "Google Chrome" {
                matchedName = "Chrome"
            } else if name == "Arc" {
                matchedName = "Arc"
            } else if name == "Microsoft Edge" {
                matchedName = "Edge"
            } else if name == "Brave Browser" {
                matchedName = "Brave"
            } else {
                matchedName = nil
            }

            guard let matchedName else { return nil }
            return CandidateApplication(pid: application.processIdentifier, appName: matchedName)
        }

        let pwa = processOutput(executable: "/bin/ps", arguments: ["-axo", "pid=,command="])
            .components(separatedBy: .newlines)
            .compactMap { line -> CandidateApplication? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.localizedCaseInsensitiveContains("YouTube Music.app")
                    || trimmed.localizedCaseInsensitiveContains("music.youtube.com")
                    || (trimmed.localizedCaseInsensitiveContains("app_mode_loader")
                        && trimmed.localizedCaseInsensitiveContains("youtube")) else {
                    return nil
                }

                let pidString = trimmed.split(separator: " ").first.map(String.init) ?? ""
                guard let pid = pid_t(pidString) else { return nil }
                return CandidateApplication(pid: pid, appName: "YouTube Music")
            }

        var seen = Set<pid_t>()
        return (running + pwa).filter { candidate in
            guard seen.contains(candidate.pid) == false else { return false }
            seen.insert(candidate.pid)
            return true
        }
    }

    private static func snapshotFromApplication(candidate: CandidateApplication, volume: Int) -> MediaSnapshot? {
        let app = AXUIElementCreateApplication(candidate.pid)
        var values: [String] = []
        var visited = 0

        collectStrings(from: app, into: &values, visited: &visited, depth: 0)

        let appName = inferredAppName(from: values, fallback: candidate.appName)
        guard let title = bestTitle(from: values, appName: appName) else { return nil }
        return splitTitle(title, appName: appName, fallbackArtist: candidate.appName, volume: volume)
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

    private static func bestTitle(from values: [String], appName: String) -> String? {
        let ignored = [
            "YouTube Music",
            "Netflix",
            "Dia",
            "Chrome",
            "Google Chrome",
            "Arc",
            "Microsoft Edge",
            "Brave Browser",
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
                && value.localizedCaseInsensitiveContains("notchdesk") == false
        }

        if let title = candidates.first(where: { $0.localizedCaseInsensitiveContains(" - YouTube Music") }) {
            return title.replacingOccurrences(of: " - YouTube Music", with: "")
        }
        if appName == "Netflix" {
            if let title = candidates.first(where: { value in
                value.count > 2
                    && value.count < 90
                    && value.localizedCaseInsensitiveContains("Netflix") == false
                    && value.localizedCaseInsensitiveContains("Continue Watching") == false
                    && value.localizedCaseInsensitiveContains("Who's watching") == false
            }) {
                return title
            }
        }
        if let title = candidates.first(where: { $0.contains(" – ") || $0.contains(" - ") }) {
            return title
        }
        if let title = candidates.first(where: { $0.count > 8 && $0.count < 90 }) {
            return title
        }
        return nil
    }

    private static func inferredAppName(from values: [String], fallback: String) -> String {
        if values.contains(where: { $0.localizedCaseInsensitiveContains("Netflix") }) {
            return "Netflix"
        }
        if values.contains(where: { $0.localizedCaseInsensitiveContains("YouTube Music") }) || fallback == "YouTube Music" {
            return "YouTube Music"
        }
        if values.contains(where: { $0.localizedCaseInsensitiveContains("YouTube") }) {
            return "YouTube"
        }
        return fallback
    }

    private static func splitTitle(_ rawTitle: String, appName: String, fallbackArtist: String, volume: Int) -> MediaSnapshot {
        let separators = [" – ", " - "]
        for separator in separators where rawTitle.contains(separator) {
            let parts = rawTitle
                .components(separatedBy: separator)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }
            if parts.count >= 2 {
                return MediaSnapshot(
                    appName: appName,
                    title: parts[0],
                    artist: parts[1],
                    state: "playing",
                    outputVolume: volume,
                    lastUpdated: Date()
                )
            }
        }

        return MediaSnapshot(
            appName: appName,
            title: rawTitle,
            artist: fallbackArtist.isEmpty ? "Now Playing" : fallbackArtist,
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
