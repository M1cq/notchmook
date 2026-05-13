import Foundation
import Darwin

enum MediaRemoteService {
    private typealias NowPlayingCallback = @convention(block) (CFDictionary) -> Void
    private typealias GetNowPlayingInfo = @convention(c) (DispatchQueue, @escaping NowPlayingCallback) -> Void
    private typealias SendCommand = @convention(c) (Int32, CFDictionary?) -> Void

    private static let frameworkHandle: UnsafeMutableRawPointer? = {
        dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW)
    }()

    static func currentSnapshot(volume: Int) -> MediaSnapshot? {
        guard let handle = frameworkHandle,
              let symbol = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") else {
            return nil
        }

        let function = unsafeBitCast(symbol, to: GetNowPlayingInfo.self)
        let semaphore = DispatchSemaphore(value: 0)
        var result: MediaSnapshot?

        function(DispatchQueue.global(qos: .userInitiated)) { dictionary in
            result = parse(dictionary: dictionary as NSDictionary, volume: volume)
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 0.35)
        return result
    }

    static func send(_ command: MediaKeyService.Command) -> Bool {
        guard let handle = frameworkHandle,
              let symbol = dlsym(handle, "MRMediaRemoteSendCommand") else {
            return false
        }

        let function = unsafeBitCast(symbol, to: SendCommand.self)
        function(command.mediaRemoteCommand, nil)
        return true
    }

    private static func parse(dictionary: NSDictionary, volume: Int) -> MediaSnapshot? {
        let title = stringValue(dictionary, keys: [
            "kMRMediaRemoteNowPlayingInfoTitle",
            "title"
        ])
        let artist = stringValue(dictionary, keys: [
            "kMRMediaRemoteNowPlayingInfoArtist",
            "artist",
            "kMRMediaRemoteNowPlayingInfoAlbum"
        ])
        let appName = stringValue(dictionary, keys: [
            "kMRMediaRemoteNowPlayingInfoApplicationDisplayName",
            "kMRMediaRemoteNowPlayingApplicationDisplayName",
            "kMRMediaRemoteNowPlayingInfoClientName",
            "kMRMediaRemoteNowPlayingInfoBundleIdentifier"
        ]) ?? "Now Playing"

        guard let title, title.isEmpty == false else {
            return nil
        }

        let playbackRate = numberValue(dictionary, keys: [
            "kMRMediaRemoteNowPlayingInfoPlaybackRate",
            "playbackRate"
        ]) ?? 1
        let artworkURL = artworkURL(from: dictionary, appName: appName, title: title)

        return MediaSnapshot(
            appName: displayName(for: appName),
            title: title,
            artist: artist ?? "Now Playing",
            state: playbackRate == 0 ? "paused" : "playing",
            outputVolume: volume,
            artworkURL: artworkURL,
            lastUpdated: Date()
        )
    }

    private static func stringValue(_ dictionary: NSDictionary, keys: [String]) -> String? {
        for key in keys {
            if let value = dictionary[key] as? String, value.isEmpty == false {
                return value
            }
        }
        return nil
    }

    private static func numberValue(_ dictionary: NSDictionary, keys: [String]) -> Double? {
        for key in keys {
            if let value = dictionary[key] as? NSNumber {
                return value.doubleValue
            }
        }
        return nil
    }

    private static func dataValue(_ dictionary: NSDictionary, keys: [String]) -> Data? {
        for key in keys {
            if let data = dictionary[key] as? Data, data.isEmpty == false {
                return data
            }
        }
        return nil
    }

    private static func artworkURL(from dictionary: NSDictionary, appName: String, title: String) -> URL? {
        guard let data = dataValue(dictionary, keys: [
            "kMRMediaRemoteNowPlayingInfoArtworkData",
            "kMRMediaRemoteNowPlayingInfoArtworkDataDigest",
            "artworkData",
            "artwork"
        ]) else {
            return nil
        }

        let mimeType = stringValue(dictionary, keys: [
            "kMRMediaRemoteNowPlayingInfoArtworkMIMEType",
            "artworkMIMEType"
        ])
        let ext = mimeType?.localizedCaseInsensitiveContains("png") == true ? "png" : "jpg"
        let filename = "\(appName)-\(title)"
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.isEmpty == false }
            .joined(separator: "-")
            .prefix(90)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("NotchDeskArtwork", isDirectory: true)
        let url = directory.appendingPathComponent("\(filename).\(ext)")

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            return nil
        }
    }

    private static func displayName(for rawValue: String) -> String {
        if rawValue.contains("YouTubeMusic") || rawValue.localizedCaseInsensitiveContains("YouTube Music") {
            return "YouTube Music"
        }
        if rawValue.localizedCaseInsensitiveContains("YouTube") {
            return "YouTube"
        }
        if rawValue.localizedCaseInsensitiveContains("Spotify") {
            return "Spotify"
        }
        if rawValue.localizedCaseInsensitiveContains("Music") {
            return "Music"
        }
        if rawValue.hasPrefix("com.") {
            return rawValue
                .components(separatedBy: ".")
                .last?
                .replacingOccurrences(of: "-", with: " ")
                .capitalized ?? "Now Playing"
        }
        return rawValue
    }
}

private extension MediaKeyService.Command {
    var mediaRemoteCommand: Int32 {
        switch self {
        case .playPause: 2
        case .next: 4
        case .previous: 5
        }
    }
}
