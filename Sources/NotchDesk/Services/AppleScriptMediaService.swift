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
                    set artworkPath to ""
                    try
                        set artworkPath to do shell script "mktemp -t notchdesk-artwork.XXXXXX"
                        set artworkData to raw data of artwork 1 of current track
                        set fileRef to open for access POSIX file artworkPath with write permission
                        set eof fileRef to 0
                        write artworkData to fileRef
                        close access fileRef
                    on error
                        try
                            close access POSIX file artworkPath
                        end try
                    end try
                    return "Music||| " & trackTitle & "||| " & trackArtist & "||| " & playState & "||| " & artworkPath
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
                    set artworkURL to ""
                    try
                        set artworkURL to artwork url of current track
                    end try
                    return "Spotify||| " & trackTitle & "||| " & trackArtist & "||| " & playState & "||| " & artworkURL
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
                set jsCode to "(() => { const metadata = navigator.mediaSession && navigator.mediaSession.metadata; const media = Array.from(document.querySelectorAll('video,audio')).find(item => !item.paused && !item.ended) || Array.from(document.querySelectorAll('video,audio'))[0]; const art = metadata && metadata.artwork && metadata.artwork.length ? metadata.artwork[metadata.artwork.length - 1].src : ''; const artwork = art ? new URL(art, location.href).href : ''; const title = (metadata && metadata.title) || document.title || 'Browser Media'; const artist = (metadata && (metadata.artist || metadata.album)) || location.hostname.replace(/^www\\\\./, ''); const state = media ? (media.paused ? 'paused' : 'playing') : 'playing'; return [title, artist, state, artwork].join('|||'); })();"
                repeat with browserWindow in windows
                    repeat with browserTab in tabs of browserWindow
                        set tabURL to URL of browserTab
                        if tabURL contains "music.youtube.com" then
                            try
                                set jsResult to execute browserTab javascript jsCode
                                if jsResult is not "" then return "YouTube Music||| " & jsResult
                            end try
                            return "YouTube Music||| " & (title of browserTab) & "||| Google Chrome||| playing||| "
                        else if tabURL contains "youtube.com/watch" then
                            try
                                set jsResult to execute browserTab javascript jsCode
                                if jsResult is not "" then return "YouTube||| " & jsResult
                            end try
                            return "YouTube||| " & (title of browserTab) & "||| Google Chrome||| playing||| "
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
        let artworkURL = parsedArtworkURL(parts[safe: 4])
        let cleaned = cleanedBrowserTitle(rawTitle, appName: appName)
        let split = splitTitle(cleaned, fallbackArtist: rawArtist)

        return MediaSnapshot(
            appName: appName,
            title: split.title,
            artist: split.artist,
            state: state,
            outputVolume: volume,
            artworkURL: artworkURL,
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

    private static func parsedArtworkURL(_ rawValue: String?) -> URL? {
        guard let rawValue else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(fileURLWithPath: trimmed)
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
