import SwiftUI

@main
struct NotchDeskApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsPane()
                .environmentObject(appDelegate.model)
        }
    }
}
