import AppKit
import Combine
import Foundation

final class MediaController: ObservableObject {
    @Published private(set) var snapshot = MediaSnapshot()

    private var timer: Timer?

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
        let script = """
        on cleanBrowserTitle(rawTitle, rawURL, sourceName)
            set cleanedTitle to rawTitle as text
            if cleanedTitle contains " - YouTube Music" then
                set AppleScript's text item delimiters to " - YouTube Music"
                set cleanedTitle to text item 1 of cleanedTitle
                set AppleScript's text item delimiters to ""
            end if
            if cleanedTitle contains " - YouTube" then
                set AppleScript's text item delimiters to " - YouTube"
                set cleanedTitle to text item 1 of cleanedTitle
                set AppleScript's text item delimiters to ""
            end if
            if cleanedTitle contains " - " then
                set AppleScript's text item delimiters to " - "
                set titleBits to text items of cleanedTitle
                set AppleScript's text item delimiters to ""
                if (count of titleBits) is greater than 1 then
                    set trackName to item 1 of titleBits
                    set artistName to item 2 of titleBits
                    return sourceName & "||" & trackName & "||" & artistName & "||playing"
                end if
            end if
            if cleanedTitle is "" then set cleanedTitle to sourceName
            return sourceName & "||" & cleanedTitle & "||Browser media||playing"
        end cleanBrowserTitle

        on isMediaURL(tabURL)
            if tabURL contains "music.youtube.com" then return true
            if tabURL contains "youtube.com/watch" then return true
            if tabURL contains "youtu.be/" then return true
            if tabURL contains "soundcloud.com" then return true
            if tabURL contains "open.spotify.com" then return true
            if tabURL contains "music.apple.com" then return true
            if tabURL contains "twitch.tv" then return true
            if tabURL contains "vimeo.com" then return true
            return false
        end isMediaURL

        on sourceNameForURL(tabURL)
            if tabURL contains "music.youtube.com" then return "YouTube Music"
            if tabURL contains "youtube.com" or tabURL contains "youtu.be/" then return "YouTube"
            if tabURL contains "soundcloud.com" then return "SoundCloud"
            if tabURL contains "open.spotify.com" then return "Spotify Web"
            if tabURL contains "music.apple.com" then return "Apple Music Web"
            if tabURL contains "twitch.tv" then return "Twitch"
            if tabURL contains "vimeo.com" then return "Vimeo"
            return "Now Playing"
        end sourceNameForURL

        on chromiumMediaTrack(appName)
            set jsCode to "(() => { const metadata = navigator.mediaSession && navigator.mediaSession.metadata; const media = Array.from(document.querySelectorAll('video,audio')).find(item => !item.paused && !item.ended) || Array.from(document.querySelectorAll('video,audio'))[0]; const title = (metadata && metadata.title) || document.title || 'Browser media'; const artist = (metadata && (metadata.artist || metadata.album)) || location.hostname.replace(/^www\\\\./, ''); const state = media ? (media.paused ? 'paused' : 'playing') : 'playing'; return ['Now Playing', title, artist, state].join('||'); })();"
            try
                using terms from application "/Applications/Google Chrome.app"
                    tell application appName
                        repeat with browserWindow in windows
                            repeat with browserTab in tabs of browserWindow
                                set tabURL to URL of browserTab as text
                                if my isMediaURL(tabURL) then
                                    try
                                        set jsResult to execute browserTab javascript jsCode
                                        if jsResult is not missing value and jsResult is not "" then return jsResult
                                    end try
                                    set tabTitle to title of browserTab as text
                                    return my cleanBrowserTitle(tabTitle, tabURL, my sourceNameForURL(tabURL))
                                end if
                            end repeat
                        end repeat
                    end tell
                end using terms from
            end try
            return ""
        end chromiumMediaTrack

        on safariMediaTrack()
            set jsCode to "(() => { const metadata = navigator.mediaSession && navigator.mediaSession.metadata; const media = Array.from(document.querySelectorAll('video,audio')).find(item => !item.paused && !item.ended) || Array.from(document.querySelectorAll('video,audio'))[0]; const title = (metadata && metadata.title) || document.title || 'Browser media'; const artist = (metadata && (metadata.artist || metadata.album)) || location.hostname.replace(/^www\\\\./, ''); const state = media ? (media.paused ? 'paused' : 'playing') : 'playing'; return ['Now Playing', title, artist, state].join('||'); })();"
            try
                tell application "Safari"
                    repeat with browserWindow in windows
                        repeat with browserTab in tabs of browserWindow
                            set tabURL to URL of browserTab as text
                            if my isMediaURL(tabURL) then
                                try
                                    set jsResult to do JavaScript jsCode in browserTab
                                    if jsResult is not missing value and jsResult is not "" then return jsResult
                                end try
                                set tabTitle to name of browserTab as text
                                return my cleanBrowserTitle(tabTitle, tabURL, my sourceNameForURL(tabURL))
                            end if
                        end repeat
                    end repeat
                end tell
            end try
            return ""
        end safariMediaTrack

        set foundTrack to ""
        tell application "System Events"
            set spotifyOpen to exists (processes where name is "Spotify")
            set musicOpen to exists (processes where name is "Music")
            set safariOpen to exists (processes where name is "Safari")
            set chromeOpen to exists (processes where name is "Google Chrome")
            set edgeOpen to exists (processes where name is "Microsoft Edge")
            set braveOpen to exists (processes where name is "Brave Browser")
            set arcOpen to exists (processes where name is "Arc")
            set diaOpen to exists (processes where name is "Dia")
        end tell
        if spotifyOpen then
            tell application "Spotify"
                if player state is playing or player state is paused then
                    set foundTrack to "Spotify||" & (name of current track as text) & "||" & (artist of current track as text) & "||" & (player state as text)
                end if
            end tell
        end if
        if foundTrack is "" and musicOpen then
            tell application "Music"
                if player state is playing or player state is paused then
                    set foundTrack to "Music||" & (name of current track as text) & "||" & (artist of current track as text) & "||" & (player state as text)
                end if
            end tell
        end if
        if foundTrack is "" and safariOpen then
            set foundTrack to my safariMediaTrack()
        end if
        if foundTrack is "" and chromeOpen then
            set foundTrack to my chromiumMediaTrack("Google Chrome")
        end if
        if foundTrack is "" and edgeOpen then
            set foundTrack to my chromiumMediaTrack("Microsoft Edge")
        end if
        if foundTrack is "" and braveOpen then
            set foundTrack to my chromiumMediaTrack("Brave Browser")
        end if
        if foundTrack is "" and arcOpen then
            set foundTrack to my chromiumMediaTrack("Arc")
        end if
        if foundTrack is "" and diaOpen then
            set foundTrack to my chromiumMediaTrack("Dia")
        end if
        set currentVolume to output volume of (get volume settings)
        if foundTrack is "" then
            return "Music||No media playing||Open Music, Spotify, or YouTube Music||stopped||" & currentVolume
        end if
        return foundTrack & "||" & currentVolume
        """

        DispatchQueue.global(qos: .utility).async {
            let output = AppleScriptRunner.run(script)
            let parsed = Self.parse(output)
            DispatchQueue.main.async {
                self.snapshot = parsed
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
        AppleScriptRunner.run("set volume output volume \(clamped)")
        snapshot.outputVolume = clamped
    }

    private func sendMediaCommand(_ command: MediaKeyService.Command) {
        DispatchQueue.global(qos: .userInitiated).async {
            MediaKeyService.send(command)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                self.refresh()
            }
        }
    }

    private static func parse(_ output: String?) -> MediaSnapshot {
        guard let output, output.isEmpty == false else {
            return MediaSnapshot()
        }

        let parts = output.components(separatedBy: "||")
        guard parts.count >= 5 else {
            return MediaSnapshot()
        }

        return MediaSnapshot(
            appName: parts[0],
            title: parts[1],
            artist: parts[2],
            state: parts[3],
            outputVolume: Int(parts[4]) ?? 50,
            lastUpdated: Date()
        )
    }
}
