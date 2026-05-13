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
        on cleanYouTubeTitle(rawTitle)
            set cleanedTitle to rawTitle as text
            if cleanedTitle contains " - YouTube Music" then
                set AppleScript's text item delimiters to " - YouTube Music"
                set cleanedTitle to text item 1 of cleanedTitle
                set AppleScript's text item delimiters to ""
            end if
            if cleanedTitle contains "YouTube Music" then
                return "YouTube Music||YouTube Music||Browser playback||playing"
            end if
            if cleanedTitle contains " - " then
                set AppleScript's text item delimiters to " - "
                set titleBits to text items of cleanedTitle
                set AppleScript's text item delimiters to ""
                if (count of titleBits) is greater than 1 then
                    set trackName to item 1 of titleBits
                    set artistName to item 2 of titleBits
                    return "YouTube Music||" & trackName & "||" & artistName & "||playing"
                end if
            end if
            return "YouTube Music||" & cleanedTitle & "||Browser playback||playing"
        end cleanYouTubeTitle

        on chromiumYouTubeTrack(appName)
            try
                using terms from application "/Applications/Google Chrome.app"
                    tell application appName
                        repeat with browserWindow in windows
                            repeat with browserTab in tabs of browserWindow
                                set tabURL to URL of browserTab as text
                                if tabURL contains "music.youtube.com" then
                                    set tabTitle to title of browserTab as text
                                    return my cleanYouTubeTitle(tabTitle)
                                end if
                            end repeat
                        end repeat
                    end tell
                end using terms from
            end try
            return ""
        end chromiumYouTubeTrack

        on safariYouTubeTrack()
            try
                tell application "Safari"
                    repeat with browserWindow in windows
                        repeat with browserTab in tabs of browserWindow
                            set tabURL to URL of browserTab as text
                            if tabURL contains "music.youtube.com" then
                                set tabTitle to name of browserTab as text
                                return my cleanYouTubeTitle(tabTitle)
                            end if
                        end repeat
                    end repeat
                end tell
            end try
            return ""
        end safariYouTubeTrack

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
            set foundTrack to my safariYouTubeTrack()
        end if
        if foundTrack is "" and chromeOpen then
            set foundTrack to my chromiumYouTubeTrack("Google Chrome")
        end if
        if foundTrack is "" and edgeOpen then
            set foundTrack to my chromiumYouTubeTrack("Microsoft Edge")
        end if
        if foundTrack is "" and braveOpen then
            set foundTrack to my chromiumYouTubeTrack("Brave Browser")
        end if
        if foundTrack is "" and arcOpen then
            set foundTrack to my chromiumYouTubeTrack("Arc")
        end if
        if foundTrack is "" and diaOpen then
            set foundTrack to my chromiumYouTubeTrack("Dia")
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
        runCommand(spotify: "playpause", music: "playpause")
    }

    func nextTrack() {
        runCommand(spotify: "next track", music: "next track")
    }

    func previousTrack() {
        runCommand(spotify: "previous track", music: "previous track")
    }

    func setVolume(_ value: Double) {
        let clamped = max(0, min(100, Int(value.rounded())))
        AppleScriptRunner.run("set volume output volume \(clamped)")
        snapshot.outputVolume = clamped
    }

    private func runCommand(spotify spotifyCommand: String, music musicCommand: String) {
        let activeApp = snapshot.appName
        let script: String
        if activeApp == "Spotify" {
            script = """
            tell application "Spotify" to \(spotifyCommand)
            """
        } else if activeApp == "YouTube Music" {
            script = Self.youtubeMusicCommandScript(command: spotifyCommand)
        } else {
            script = """
            tell application "Music" to \(musicCommand)
            """
        }

        DispatchQueue.global(qos: .userInitiated).async {
            AppleScriptRunner.run(script)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.refresh()
            }
        }
    }

    private static func youtubeMusicCommandScript(command: String) -> String {
        let selector: String
        switch command {
        case "next track":
            selector = "tp-yt-paper-icon-button.next-button, .next-button"
        case "previous track":
            selector = "tp-yt-paper-icon-button.previous-button, .previous-button"
        default:
            selector = "#play-pause-button, tp-yt-paper-icon-button.play-pause-button, .play-pause-button"
        }

        let escapedSelector = selector
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return """
        on clickYouTubeMusic(appName)
            set jsCode to "(() => { const button = document.querySelector(\\\"\(escapedSelector)\\\"); if (button) { button.click(); return true; } return false; })();"
            try
                using terms from application "/Applications/Google Chrome.app"
                    tell application appName
                        repeat with browserWindow in windows
                            repeat with browserTab in tabs of browserWindow
                                if (URL of browserTab as text) contains "music.youtube.com" then
                                    execute browserTab javascript jsCode
                                    return true
                                end if
                            end repeat
                        end repeat
                    end tell
                end using terms from
            end try
            return false
        end clickYouTubeMusic

        on clickSafariYouTubeMusic()
            set jsCode to "(() => { const button = document.querySelector(\\\"\(escapedSelector)\\\"); if (button) { button.click(); return true; } return false; })();"
            try
                tell application "Safari"
                    repeat with browserWindow in windows
                        repeat with browserTab in tabs of browserWindow
                            if (URL of browserTab as text) contains "music.youtube.com" then
                                do JavaScript jsCode in browserTab
                                return true
                            end if
                        end repeat
                    end repeat
                end tell
            end try
            return false
        end clickSafariYouTubeMusic

        tell application "System Events"
            set safariOpen to exists (processes where name is "Safari")
            set chromeOpen to exists (processes where name is "Google Chrome")
            set edgeOpen to exists (processes where name is "Microsoft Edge")
            set braveOpen to exists (processes where name is "Brave Browser")
            set arcOpen to exists (processes where name is "Arc")
            set diaOpen to exists (processes where name is "Dia")
        end tell
        if safariOpen and my clickSafariYouTubeMusic() then return
        if chromeOpen and my clickYouTubeMusic("Google Chrome") then return
        if edgeOpen and my clickYouTubeMusic("Microsoft Edge") then return
        if braveOpen and my clickYouTubeMusic("Brave Browser") then return
        if arcOpen and my clickYouTubeMusic("Arc") then return
        if diaOpen and my clickYouTubeMusic("Dia") then return
        """
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
