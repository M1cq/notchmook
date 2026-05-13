import AppKit
import Combine
import Foundation

final class NookModel: ObservableObject {
    @Published var isExpanded = false
    @Published var isPinned = false
    @Published var selectedTab: NookTab = .dashboard
    @Published var trayItems: [TrayItem] = []
    @Published var autoExpandOnHover = true
    @Published var notchlessHandler = true
    @Published var theme: NookTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: Self.themeDefaultsKey)
        }
    }

    let mediaController = MediaController()
    let calendarProvider = CalendarProvider()
    let cameraController = CameraController()
    lazy var shortcuts = ShortcutProvider(model: self).shortcuts

    private var collapseTask: DispatchWorkItem?
    private static let themeDefaultsKey = "NotchDesk.theme"

    init() {
        let storedTheme = UserDefaults.standard.string(forKey: Self.themeDefaultsKey)
            .flatMap(NookTheme.init(rawValue:))
        theme = storedTheme ?? .dusk
    }

    func expand(tab: NookTab? = nil) {
        collapseTask?.cancel()
        if let tab {
            selectedTab = tab
        }
        isExpanded = true
    }

    func scheduleCollapse() {
        collapseTask?.cancel()
        guard !isPinned else { return }

        let task = DispatchWorkItem { [weak self] in
            self?.isExpanded = false
        }
        collapseTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28, execute: task)
    }

    func addFiles(_ urls: [URL]) {
        let current = Set(trayItems.map(\.url))
        let newItems = urls
            .filter { current.contains($0) == false }
            .map(TrayItem.init(url:))

        guard newItems.isEmpty == false else { return }
        trayItems.append(contentsOf: newItems)
        selectedTab = .tray
        isExpanded = true
    }

    func remove(_ item: TrayItem) {
        trayItems.removeAll { $0.id == item.id }
    }

    func clearTray() {
        trayItems.removeAll()
    }
}
