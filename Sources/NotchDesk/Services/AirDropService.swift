import AppKit
import UniformTypeIdentifiers

enum AirDropService {
    static func share(_ urls: [URL]) {
        guard urls.isEmpty == false else {
            openAirDropWindow()
            return
        }

        DispatchQueue.main.async {
            if let service = NSSharingService(named: .sendViaAirDrop), service.canPerform(withItems: urls) {
                service.perform(withItems: urls)
                return
            }

            let picker = NSSharingServicePicker(items: urls)
            if let window = NSApp.keyWindow ?? NSApp.windows.first,
               let view = window.contentView {
                picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
            }
        }
    }

    static func openAirDropWindow() {
        AppleScriptRunner.run("""
        tell application "Finder"
            activate
            open AirDrop window
        end tell
        """)
    }

    @discardableResult
    static func shareFileProviders(_ providers: [NSItemProvider]) -> Bool {
        let fileProviders = providers.filter {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }
        guard fileProviders.isEmpty == false else { return false }

        let group = DispatchGroup()
        var urls: [URL] = []
        let lock = NSLock()

        for provider in fileProviders {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }

                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let rawURL = item as? URL {
                    url = rawURL
                } else if let string = item as? String {
                    url = URL(string: string)
                } else {
                    url = nil
                }

                if let url {
                    lock.lock()
                    urls.append(url)
                    lock.unlock()
                }
            }
        }

        group.notify(queue: .main) {
            share(urls)
        }

        return true
    }
}
