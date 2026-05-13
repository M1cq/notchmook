import AppKit
import Foundation

enum AppleScriptMediaService {
    static func currentSnapshot(volume: Int) -> MediaSnapshot? {
        musicSnapshot(volume: volume)
            ?? spotifySnapshot(volume: volume)
            ?? chromeSnapshot(volume: volume)
    }

    private static func musicSnapshot(volume: Int) -> MediaSnapshot? {
        guard isRunning(bundleIdentifier: "com.apple.Music", appName: "Music") else { return nil }

        let script = """
        with timeout of 1 seconds
            tell application "Music"
                set playState to player state as text
                if playState is "playing" or playState is "paused" then
                    set trackTitle to name of current track
                    set trackArtist to artist of current track
                    return "Music||| " & trackTitle & "||| " & trackArtist & "||| " & playState
                end if
            end tell
        end timeout
        """

        return snapshot(from: AppleScriptRunner.run(script), fallbackAppName: "Music", volume: volume)
    }

    private static func spotifySnapshot(volume: Int) -> MediaSnapshot? {
        guard isRunning(bundleIdentifier: "com.spotify.client", appName: "Spotify") else { return nil }

        let script = """
        with timeout of 1 seconds
            tell application "Spotify"
                set playState to player state as text
                if playState is "playing" or playState is "paused" then
                    set trackTitle to name of current track
                    set trackArtist to artist of current track
                    return "Spotify||| " & trackTitle & "||| " & trackArtist & "||| " & playState
                end if
            end tell
        end timeout
        """

        return snapshot(from: AppleScriptRunner.run(script), fallbackAppName: "Spotify", volume: volume)
    }

    private static func chromeSnapshot(volume: Int) -> MediaSnapshot? {
        guard isRunning(bundleIdentifier: "com.google.Chrome", appName: "Google Chrome") else { return nil }

        let script = """
        with timeout of 1 seconds
            tell application "Google Chrome"
                repeat with browserWindow in windows
                    repeat with browserTab in tabs of browserWindow
                        set tabURL to URL of browserTab
                        if tabURL contains "music.youtube.com" then
                            set tabTitle to title of browserTab
                            return "YouTube Music||| " & tabTitle & "||| Google Chrome||| playing"
                        else if tabURL contains "youtube.com/watch" then
                            set tabTitle to title of browserTab
                            return "YouTube||| " & tabTitle & "||| Google Chrome||| playing"
                        end if
                    end repeat
                end repeat
            end tell
        end timeout
        """

        return snapshot(from: AppleScriptRunner.run(script), fallbackAppName: "Chrome", volume: volume)
    }

    private static func snapshot(from rawValue: String?, fallbackAppName: String, volume: Int) -> MediaSnapshot? {
        guard let rawValue, rawValue.isEmpty == false else { return nil }

        let parts = rawValue
            .components(separatedBy: "|||")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard parts.count >= 2, parts[1].isEmpty == false else { return nil }

        let appName = parts[safe: 0] ?? fallbackAppName
        let rawTitle = parts[safe: 1] ?? appName
        let rawArtist = parts[safe: 2] ?? "Now Playing"
        let state = normalizedState(parts[safe: 3] ?? "playing")
        let cleaned = cleanedBrowserTitle(rawTitle, appName: appName)
        let split = splitTitle(cleaned, fallbackArtist: rawArtist)

        return MediaSnapshot(
            appName: appName,
            title: split.title,
            artist: split.artist,
            state: state,
            outputVolume: volume,
            lastUpdated: Date()
        )
    }

    private static func isRunning(bundleIdentifier: String, appName: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains { application in
            application.bundleIdentifier == bundleIdentifier
                || application.localizedName == appName
                || application.executableURL?.lastPathComponent == appName
        }
    }

    private static func normalizedState(_ rawValue: String) -> String {
        rawValue.localizedCaseInsensitiveContains("paused") ? "paused" : "playing"
    }

    private static func cleanedBrowserTitle(_ title: String, appName: String) -> String {
        title
            .replacingOccurrences(of: " - YouTube Music", with: "")
            .replacingOccurrences(of: " - YouTube", with: "")
            .replacingOccurrences(of: "YouTube Music", with: appName == "YouTube Music" ? "" : "YouTube Music")
            .trimmingCharacters(in: CharacterSet(charactersIn: " -\n\t"))
    }

    private static func splitTitle(_ rawTitle: String, fallbackArtist: String) -> (title: String, artist: String) {
        for separator in [" – ", " - "] where rawTitle.contains(separator) {
            let pieces = rawTitle
                .components(separatedBy: separator)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }
            if pieces.count >= 2 {
                return (pieces[0], pieces[1])
            }
        }

        return (rawTitle, fallbackArtist.isEmpty ? "Now Playing" : fallbackArtist)
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
