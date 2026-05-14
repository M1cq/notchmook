import AppKit
import Foundation

enum AppleScriptMediaService {
    static func currentSnapshot(volume: Int) -> MediaSnapshot? {
        musicSnapshot(volume: volume)
            ?? spotifySnapshot(volume: volume)
            ?? browserSnapshot(appName: "Google Chrome", displayName: "Chrome", bundleIdentifier: "com.google.Chrome", volume: volume)
            ?? browserSnapshot(appName: "Dia", displayName: "Dia", bundleIdentifier: "", volume: volume)
            ?? browserSnapshot(appName: "Arc", displayName: "Arc", bundleIdentifier: "company.thebrowser.Browser", volume: volume)
            ?? browserSnapshot(appName: "Microsoft Edge", displayName: "Edge", bundleIdentifier: "com.microsoft.edgemac", volume: volume)
            ?? browserSnapshot(appName: "Brave Browser", displayName: "Brave", bundleIdentifier: "com.brave.Browser", volume: volume)
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

    private static func browserSnapshot(appName: String, displayName: String, bundleIdentifier: String, volume: Int) -> MediaSnapshot? {
        guard isRunning(bundleIdentifier: bundleIdentifier, appName: appName) else { return nil }
        let jsCode = appleScriptString(browserMediaJavaScript(displayName: displayName))

        let script = """
        with timeout of 1 seconds
            tell application "\(appName)"
                set jsCode to \(jsCode)
                repeat with browserWindow in windows
                    repeat with browserTab in tabs of browserWindow
                        set tabURL to URL of browserTab
                        if tabURL contains "music.youtube.com" then
                            try
                                set jsResult to execute browserTab javascript jsCode
                                if jsResult is not "" then return jsResult
                            end try
                            return "YouTube Music||| " & (title of browserTab) & "||| \(displayName)||| playing||| "
                        else if tabURL contains "youtube.com/watch" then
                            try
                                set jsResult to execute browserTab javascript jsCode
                                if jsResult is not "" then return jsResult
                            end try
                            return "YouTube||| " & (title of browserTab) & "||| \(displayName)||| playing||| "
                        else if tabURL contains "netflix.com" then
                            try
                                set jsResult to execute browserTab javascript jsCode
                                if jsResult is not "" then return jsResult
                            end try
                            return "Netflix||| Netflix||| \(displayName)||| playing||| "
                        else
                            try
                                set jsResult to execute browserTab javascript jsCode
                                if jsResult is not "" then return jsResult
                            end try
                        end if
                    end repeat
                end repeat
            end tell
        end timeout
        """

        return snapshot(from: AppleScriptRunner.run(script), fallbackAppName: displayName, volume: volume)
    }

    private static func browserMediaJavaScript(displayName: String) -> String {
        """
        (() => {
          const metadata = navigator.mediaSession && navigator.mediaSession.metadata;
          const mediaItems = Array.from(document.querySelectorAll('video,audio'));
          const media = mediaItems.find(item => !item.paused && !item.ended) || mediaItems[0];
          if (!metadata && !media) return '';
          const host = location.hostname.replace(/^www\\./, '');
          let source = 'Browser Media';
          if (host.includes('music.youtube.com')) source = 'YouTube Music';
          else if (host.includes('youtube.com')) source = 'YouTube';
          else if (host.includes('netflix.com')) source = 'Netflix';
          const text = (value) => (value || '').replace(/\\s+/g, ' ').trim();
          const firstText = (selectors) => {
            for (const selector of selectors) {
              const item = document.querySelector(selector);
              const value = text(item && (item.getAttribute('aria-label') || item.getAttribute('alt') || item.textContent || item.content));
              if (value) return value;
            }
            return '';
          };
          const firstAttr = (selectors, attr) => {
            for (const selector of selectors) {
              const item = document.querySelector(selector);
              const value = text(item && item.getAttribute(attr));
              if (value) return value;
            }
            return '';
          };
          const netflixTitle = firstText([
            '[data-uia="video-title"]',
            '[data-uia*="title"]',
            '.video-title',
            '.title-title',
            '.ellipsize-text',
            'meta[property="og:title"]',
            'meta[name="title"]'
          ]);
          const rawTitle = text((metadata && metadata.title) || netflixTitle || document.title || source);
          const cleanedTitle = text(rawTitle.replace(/[-|]?\\s*Netflix\\s*$/i, '').replace(/^Netflix\\s*[-|]?\\s*/i, '')) || source;
          const artist = text((metadata && (metadata.artist || metadata.album)) || (source === 'Netflix' ? '\(displayName)' : host) || '\(displayName)');
          const mediaArtwork = metadata && metadata.artwork && metadata.artwork.length ? metadata.artwork[metadata.artwork.length - 1].src : '';
          const pageArtwork = firstAttr([
            'meta[property="og:image"]',
            'meta[name="twitter:image"]',
            'img[src*="occ-"]',
            'img[src*="nflx"]',
            'img[alt][src]'
          ], 'content') || firstAttr([
            'img[src*="occ-"]',
            'img[src*="nflx"]',
            'img[alt][src]'
          ], 'src');
          const art = mediaArtwork || pageArtwork;
          const artwork = art ? new URL(art, location.href).href : '';
          const state = media ? (media.paused ? 'paused' : 'playing') : 'playing';
          return [source, cleanedTitle, artist, state, artwork].join('|||');
        })();
        """
    }

    private static func appleScriptString(_ rawValue: String) -> String {
        let escaped = rawValue
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
        return "\"\(escaped)\""
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
        if isUselessBrowserTitle(cleaned, appName: appName, rawArtist: rawArtist), artworkURL == nil {
            return nil
        }
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
            .replacingOccurrences(of: " - Netflix", with: "")
            .replacingOccurrences(of: "YouTube Music", with: appName == "YouTube Music" ? "" : "YouTube Music")
            .replacingOccurrences(of: "Netflix", with: appName == "Netflix" ? "" : "Netflix")
            .trimmingCharacters(in: CharacterSet(charactersIn: " -\n\t"))
    }

    private static func isUselessBrowserTitle(_ title: String, appName: String, rawArtist: String) -> Bool {
        guard appName == "Netflix" else { return false }
        let genericTitles = ["Dia", "Chrome", "Google Chrome", "Arc", "Edge", "Microsoft Edge", "Brave", "Brave Browser"]
        return genericTitles.contains { title.caseInsensitiveCompare($0) == .orderedSame }
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
