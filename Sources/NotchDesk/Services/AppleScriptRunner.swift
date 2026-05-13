import Foundation

enum AppleScriptRunner {
    @discardableResult
    static func run(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let descriptor = script.executeAndReturnError(&error)
        if let error {
            NSLog("AppleScript error: \(error)")
        }
        return descriptor.stringValue
    }
}
