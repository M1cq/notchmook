import AppKit
import Combine
import Foundation

final class MediaController: ObservableObject {
    @Published private(set) var snapshot = MediaSnapshot()

    private var timer: Timer?
    private let refreshLock = NSLock()
    private var refreshInFlight = false

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        timer?.invalidate()
    }

    func refresh() {
        refreshLock.lock()
        guard refreshInFlight == false else {
            refreshLock.unlock()
            return
        }
        refreshInFlight = true
        refreshLock.unlock()

        DispatchQueue.global(qos: .utility).async {
            defer {
                self.refreshLock.lock()
                self.refreshInFlight = false
                self.refreshLock.unlock()
            }

            let currentVolume = self.snapshot.outputVolume
            let resolved = Self.resolvedSnapshot(volume: currentVolume)
            DispatchQueue.main.async {
                self.snapshot = resolved
            }
        }
    }

    func togglePlayPause() {
        sendMediaCommand(.playPause)
    }

    func nextTrack() {
        sendMediaCommand(.next)
    }

    func previousTrack() {
        sendMediaCommand(.previous)
    }

    func setVolume(_ value: Double) {
        let clamped = max(0, min(100, Int(value.rounded())))
        snapshot.outputVolume = clamped
    }

    private func sendMediaCommand(_ command: MediaKeyService.Command) {
        DispatchQueue.global(qos: .userInitiated).async {
            if MediaRemoteService.send(command) == false {
                MediaKeyService.send(command)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                self.refresh()
            }
        }
    }

    private static func resolvedSnapshot(volume: Int) -> MediaSnapshot {
        if let appleScript = AppleScriptMediaService.currentSnapshot(volume: volume) {
            return appleScript
        }
        if let mediaRemote = MediaRemoteService.currentSnapshot(volume: volume) {
            return mediaRemote
        }
        if let accessibility = AccessibilityMediaService.currentSnapshot(volume: volume) {
            return accessibility
        }

        let windowFallback = windowTitleFallback(volume: volume)
        if windowFallback.hasMedia {
            return windowFallback
        }

        let pwaFallback = youtubeMusicPWAFallback(volume: volume)
        if pwaFallback.hasMedia {
            return pwaFallback
        }

        let audioProcessFallback = audioProcessFallback(volume: volume)
        if audioProcessFallback.hasMedia {
            return audioProcessFallback
        }

        return MediaSnapshot(outputVolume: volume)
    }

    private static func windowTitleFallback(volume: Int) -> MediaSnapshot {
        guard let windowInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return MediaSnapshot(outputVolume: volume)
        }

        for info in windowInfo {
            let owner = info[kCGWindowOwnerName as String] as? String ?? ""
            let title = info[kCGWindowName as String] as? String ?? ""
            guard title.isEmpty == false else { continue }

            if let snapshot = parseWindowTitle(title: title, owner: owner, volume: volume) {
                return snapshot
            }
        }

        return MediaSnapshot(outputVolume: volume)
    }

    private static func parseWindowTitle(title: String, owner: String, volume: Int) -> MediaSnapshot? {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.isEmpty == false else { return nil }

        let browserOwners = [
            "Safari",
            "Google Chrome",
            "Microsoft Edge",
            "Brave Browser",
            "Arc",
            "Dia"
        ]

        if normalized.localizedCaseInsensitiveContains("YouTube Music") {
            let cleaned = normalized
                .replacingOccurrences(of: " - YouTube Music", with: "")
                .replacingOccurrences(of: "YouTube Music", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: " -\n\t"))
            return splitTitle(cleaned.isEmpty ? normalized : cleaned, appName: "YouTube Music", fallbackArtist: owner, volume: volume)
        }

        if normalized.localizedCaseInsensitiveContains("YouTube") {
            let cleaned = normalized
                .replacingOccurrences(of: " - YouTube", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: " -\n\t"))
            return splitTitle(cleaned.isEmpty ? normalized : cleaned, appName: "YouTube", fallbackArtist: owner, volume: volume)
        }

        if normalized.localizedCaseInsensitiveContains("Netflix") {
            let cleaned = normalized
                .replacingOccurrences(of: " - Netflix", with: "")
                .replacingOccurrences(of: "Netflix", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: " -\n\t"))
            return MediaSnapshot(
                appName: "Netflix",
                title: cleaned.isEmpty ? "Netflix" : cleaned,
                artist: owner.isEmpty ? "Now Playing" : owner,
                state: "playing",
                outputVolume: volume,
                lastUpdated: Date()
            )
        }

        if normalized.localizedCaseInsensitiveContains("Spotify") || owner == "Spotify" {
            return splitTitle(normalized.replacingOccurrences(of: "Spotify", with: ""), appName: owner == "Spotify" ? "Spotify" : "Spotify Web", fallbackArtist: owner, volume: volume)
        }

        if browserOwners.contains(owner),
           normalized.localizedCaseInsensitiveContains("NotchDesk") == false,
           normalized.localizedCaseInsensitiveContains("Finder") == false {
            return MediaSnapshot(
                appName: "Now Playing",
                title: normalized,
                artist: owner,
                state: "playing",
                outputVolume: volume,
                lastUpdated: Date()
            )
        }

        return nil
    }

    private static func splitTitle(_ rawTitle: String, appName: String, fallbackArtist: String, volume: Int) -> MediaSnapshot {
        let pieces = rawTitle
            .components(separatedBy: " - ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        let title = pieces.first ?? rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = pieces.dropFirst().first ?? fallbackArtist

        return MediaSnapshot(
            appName: appName,
            title: title.isEmpty ? appName : title,
            artist: artist.isEmpty ? "Now Playing" : artist,
            state: "playing",
            outputVolume: volume,
            lastUpdated: Date()
        )
    }

    private static func youtubeMusicPWAFallback(volume: Int) -> MediaSnapshot {
        guard isYouTubeMusicPWARunning() else {
            return MediaSnapshot(outputVolume: volume)
        }

        return MediaSnapshot(
            appName: "YouTube Music",
            title: "YouTube Music",
            artist: "Now Playing",
            state: "playing",
            outputVolume: volume,
            lastUpdated: Date()
        )
    }

    private static func audioProcessFallback(volume: Int) -> MediaSnapshot {
        let output = processOutput(executable: "/bin/ps", arguments: ["-axo", "command"])
        let lines = output.components(separatedBy: .newlines)

        if isYouTubeMusicRunningInWorkspace() {
            return MediaSnapshot(
                appName: "YouTube Music",
                title: "YouTube Music",
                artist: "Now Playing",
                state: "playing",
                outputVolume: volume,
                lastUpdated: Date()
            )
        }

        if lines.contains(where: { line in
            line.localizedCaseInsensitiveContains("YouTube Music")
                || line.localizedCaseInsensitiveContains("music.youtube.com")
        }) {
            return MediaSnapshot(
                appName: "YouTube Music",
                title: "YouTube Music",
                artist: "Now Playing",
                state: "playing",
                outputVolume: volume,
                lastUpdated: Date()
            )
        }

        if lines.contains(where: { line in
            line.localizedCaseInsensitiveContains("Google Chrome Helper")
                && line.localizedCaseInsensitiveContains("audio.mojom.AudioService")
        }) {
            return MediaSnapshot(
                appName: "Chrome",
                title: "Browser Media",
                artist: "Now Playing",
                state: "playing",
                outputVolume: volume,
                lastUpdated: Date()
            )
        }

        if lines.contains(where: { line in
            line.localizedCaseInsensitiveContains("Dia")
                && line.localizedCaseInsensitiveContains("audio.mojom.AudioService")
        }) {
            return MediaSnapshot(
                appName: "Dia",
                title: "Browser Media",
                artist: "Now Playing",
                state: "playing",
                outputVolume: volume,
                lastUpdated: Date()
            )
        }

        if lines.contains(where: { line in
            line.localizedCaseInsensitiveContains("/System/Applications/Music.app/Contents/MacOS/Music")
        }) {
            return MediaSnapshot(
                appName: "Music",
                title: "Music",
                artist: "Now Playing",
                state: "playing",
                outputVolume: volume,
                lastUpdated: Date()
            )
        }

        if lines.contains(where: { line in
            line.localizedCaseInsensitiveContains("/Spotify.app/Contents/MacOS/Spotify")
        }) {
            return MediaSnapshot(
                appName: "Spotify",
                title: "Spotify",
                artist: "Now Playing",
                state: "playing",
                outputVolume: volume,
                lastUpdated: Date()
            )
        }

        return MediaSnapshot(outputVolume: volume)
    }

    private static func isYouTubeMusicPWARunning() -> Bool {
        if isYouTubeMusicRunningInWorkspace() {
            return true
        }
        if processListContains(all: ["YouTube Music.app", "app_mode_loader"]) {
            return true
        }
        if processListContains(all: ["music.youtube.com", "app_mode_loader"]) {
            return true
        }
        return processListContains(all: ["Chrome Apps.localized", "YouTube Music"])
    }

    private static func isYouTubeMusicRunningInWorkspace() -> Bool {
        NSWorkspace.shared.runningApplications.contains { application in
            let name = application.localizedName ?? ""
            let bundleIdentifier = application.bundleIdentifier ?? ""
            let executablePath = application.executableURL?.path ?? ""
            let bundlePath = application.bundleURL?.path ?? ""

            return name.localizedCaseInsensitiveContains("YouTube Music")
                || bundleIdentifier.localizedCaseInsensitiveContains("YouTubeMusic")
                || executablePath.localizedCaseInsensitiveContains("YouTube Music.app")
                || bundlePath.localizedCaseInsensitiveContains("YouTube Music.app")
        }
    }

    private static func processListContains(all patterns: [String]) -> Bool {
        processOutput(executable: "/bin/ps", arguments: ["-axo", "command"])
            .components(separatedBy: .newlines)
            .contains { line in
                patterns.allSatisfy { line.localizedCaseInsensitiveContains($0) }
            }
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
