import AppKit

enum PermissionService {
    static func requestAutomationPrompts() {
        DispatchQueue.global(qos: .userInitiated).async {
            AppleScriptRunner.run("""
            tell application "System Events"
                count of processes
            end tell
            """)

            AppleScriptRunner.run("""
            tell application "Music"
                get name
            end tell
            """)

            if isRunning(bundleIdentifier: "com.google.Chrome", appName: "Google Chrome") {
                AppleScriptRunner.run("""
                tell application "Google Chrome"
                    count of windows
                end tell
                """)
            }

            if isRunning(bundleIdentifier: "com.spotify.client", appName: "Spotify") {
                AppleScriptRunner.run("""
                tell application "Spotify"
                    get name
                end tell
                """)
            }

            AppleScriptRunner.run("""
            tell application "Finder"
                get name
            end tell
            """)
        }
    }

    static func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }

    private static func isRunning(bundleIdentifier: String, appName: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains { application in
            application.bundleIdentifier == bundleIdentifier
                || application.localizedName == appName
        }
    }
}
