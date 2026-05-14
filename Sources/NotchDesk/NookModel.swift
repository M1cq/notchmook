import AppKit
import Combine
import Foundation

final class NookModel: ObservableObject {
    @Published var isExpanded = false
    @Published var isPeeking = false
    @Published var isPinned = false
    @Published var selectedTab: NookTab = .dashboard
    @Published var trayItems: [TrayItem] = []
    @Published var autoExpandOnHover = true
    @Published var notchlessHandler = true
    @Published var customShortcutItems: [CustomShortcutItem] = [] {
        didSet {
            saveCustomShortcuts()
            rebuildShortcuts()
        }
    }
    @Published var nookActions: [NookActionConfig] = NookActionConfig.defaults {
        didSet {
            saveNookActions()
        }
    }
    @Published private(set) var availableShortcutNames: [String] = []
    @Published var theme: NookTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: Self.themeDefaultsKey)
        }
    }
    @Published var nookLayout: NookLayout {
        didSet {
            UserDefaults.standard.set(nookLayout.rawValue, forKey: Self.layoutDefaultsKey)
        }
    }
    @Published var nookWidgetConfigs: [NookWidgetConfig] = NookWidgetConfig.defaults {
        didSet {
            saveNookWidgetConfigs()
        }
    }

    let mediaController = MediaController()
    let calendarProvider = CalendarProvider()
    let cameraController = CameraController()
    @Published private(set) var shortcuts: [NookShortcut] = []

    private var collapseTask: DispatchWorkItem?
    private static let themeDefaultsKey = "NotchDesk.theme"
    private static let layoutDefaultsKey = "NotchDesk.layout"
    private static let widgetConfigsDefaultsKey = "NotchDesk.widgetConfigs"
    private static let shortcutsDefaultsKey = "NotchDesk.customShortcuts"
    private static let nookActionsDefaultsKey = "NotchDesk.nookActions"

    init() {
        let storedTheme = UserDefaults.standard.string(forKey: Self.themeDefaultsKey)
            .flatMap(NookTheme.init(rawValue:))
        theme = storedTheme ?? .dusk

        let storedLayout = UserDefaults.standard.string(forKey: Self.layoutDefaultsKey)
            .flatMap(NookLayout.init(rawValue:))
        nookLayout = storedLayout ?? .classic

        if let data = UserDefaults.standard.data(forKey: Self.widgetConfigsDefaultsKey),
           let decoded = try? JSONDecoder().decode([NookWidgetConfig].self, from: data) {
            nookWidgetConfigs = Self.normalizedWidgetConfigs(decoded)
        }

        if let data = UserDefaults.standard.data(forKey: Self.nookActionsDefaultsKey),
           let decoded = try? JSONDecoder().decode([NookActionConfig].self, from: data),
           decoded.isEmpty == false {
            nookActions = Array(decoded.prefix(2))
        }

        if let data = UserDefaults.standard.data(forKey: Self.shortcutsDefaultsKey),
           let decoded = try? JSONDecoder().decode([CustomShortcutItem].self, from: data) {
            customShortcutItems = decoded
        }

        rebuildShortcuts()
        refreshAvailableShortcutNames()
    }

    func expand(tab: NookTab? = nil) {
        collapseTask?.cancel()
        if let tab {
            selectedTab = tab
        }
        isPeeking = false
        isExpanded = true
    }

    func peek() {
        collapseTask?.cancel()
        guard isExpanded == false else { return }
        guard isPeeking == false else { return }
        performHapticFeedbackIfNeeded()
        isPeeking = true
    }

    func collapsePeek() {
        guard isExpanded == false else { return }
        isPeeking = false
    }

    func scheduleCollapse() {
        collapseTask?.cancel()
        guard !isPinned else { return }

        let task = DispatchWorkItem { [weak self] in
            self?.isExpanded = false
            self?.isPeeking = false
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
        isPeeking = false
        isExpanded = true
    }

    func remove(_ item: TrayItem) {
        trayItems.removeAll { $0.id == item.id }
    }

    func clearTray() {
        trayItems.removeAll()
    }

    func performNookAction(_ action: NookActionConfig) {
        switch (action.kind, action.value) {
        case ("builtIn", "airDrop"):
            AirDropService.share(trayItems.map(\.url))
        case ("builtIn", "openMusic"):
            openApp(named: "Music")
        case ("builtIn", "openCalendar"):
            openApp(named: "Calendar")
        case ("builtIn", "mirror"):
            expand(tab: .mirror)
        case ("builtIn", "clearTray"):
            clearTray()
        case ("shortcut", let name):
            ShortcutProvider.runShortcut(named: name)
        default:
            break
        }
    }

    func setNookAction(_ action: NookActionConfig, at index: Int) {
        var next = normalizedNookActions()
        guard next.indices.contains(index) else { return }
        next[index] = action
        nookActions = next
    }

    func customShortcutNookAction(named name: String) -> NookActionConfig {
        NookActionConfig(
            title: name,
            subtitle: "Shortcut",
            symbol: "sparkles",
            tintName: "purple",
            kind: "shortcut",
            value: name
        )
    }

    func refreshAvailableShortcutNames() {
        DispatchQueue.global(qos: .utility).async {
            let names = ShortcutProvider.availableShortcutNames()
            DispatchQueue.main.async {
                self.availableShortcutNames = names
            }
        }
    }

    func addShortcut(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false,
              customShortcutItems.contains(where: { $0.shortcutName == trimmed }) == false else {
            return
        }

        customShortcutItems.insert(
            CustomShortcutItem(title: trimmed, shortcutName: trimmed),
            at: 0
        )
    }

    func removeCustomShortcut(_ item: CustomShortcutItem) {
        customShortcutItems.removeAll { $0.id == item.id }
    }

    func setWidgetEnabled(_ kind: NookWidgetKind, isEnabled: Bool) {
        updateWidget(kind) { config in
            config.isEnabled = isEnabled
        }
        if isEnabled {
            nookLayout = .custom
        }
    }

    func setWidgetWeight(_ kind: NookWidgetKind, weight: Double) {
        updateWidget(kind) { config in
            config.weight = min(max(weight, 0.5), 3.0)
        }
        nookLayout = .custom
    }

    func moveWidget(_ kind: NookWidgetKind, direction: Int) {
        var configs = orderedWidgetConfigs()
        guard let index = configs.firstIndex(where: { $0.kind == kind }) else { return }
        let destination = index + direction
        guard configs.indices.contains(destination) else { return }
        configs.swapAt(index, destination)
        for index in configs.indices {
            configs[index].order = index
        }
        nookWidgetConfigs = configs
        nookLayout = .custom
    }

    func resetWidgetLayout() {
        nookWidgetConfigs = NookWidgetConfig.defaults
        nookLayout = .custom
    }

    func orderedWidgetConfigs() -> [NookWidgetConfig] {
        Self.normalizedWidgetConfigs(nookWidgetConfigs)
            .sorted { lhs, rhs in
                if lhs.order == rhs.order {
                    return lhs.kind.rawValue < rhs.kind.rawValue
                }
                return lhs.order < rhs.order
            }
    }

    private func rebuildShortcuts() {
        shortcuts = ShortcutProvider(model: self).shortcuts(customItems: customShortcutItems)
    }

    private func saveCustomShortcuts() {
        guard let encoded = try? JSONEncoder().encode(customShortcutItems) else { return }
        UserDefaults.standard.set(encoded, forKey: Self.shortcutsDefaultsKey)
    }

    private func saveNookActions() {
        guard let encoded = try? JSONEncoder().encode(normalizedNookActions()) else { return }
        UserDefaults.standard.set(encoded, forKey: Self.nookActionsDefaultsKey)
    }

    private func saveNookWidgetConfigs() {
        guard let encoded = try? JSONEncoder().encode(orderedWidgetConfigs()) else { return }
        UserDefaults.standard.set(encoded, forKey: Self.widgetConfigsDefaultsKey)
    }

    private func normalizedNookActions() -> [NookActionConfig] {
        var normalized = Array(nookActions.prefix(2))
        while normalized.count < 2 {
            normalized.append(NookActionConfig.defaults[normalized.count])
        }
        return normalized
    }

    private func updateWidget(_ kind: NookWidgetKind, update: (inout NookWidgetConfig) -> Void) {
        var configs = orderedWidgetConfigs()
        guard let index = configs.firstIndex(where: { $0.kind == kind }) else { return }
        update(&configs[index])
        nookWidgetConfigs = configs
    }

    private func performHapticFeedbackIfNeeded() {
        guard UserDefaults.standard.object(forKey: "NotchDesk.hapticFeedback") as? Bool ?? true else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }

    private static func normalizedWidgetConfigs(_ configs: [NookWidgetConfig]) -> [NookWidgetConfig] {
        var byKind = Dictionary(uniqueKeysWithValues: configs.map { ($0.kind, $0) })
        for defaultConfig in NookWidgetConfig.defaults where byKind[defaultConfig.kind] == nil {
            byKind[defaultConfig.kind] = defaultConfig
        }
        return NookWidgetKind.allCases.compactMap { byKind[$0] }
    }

    private func openApp(named name: String) {
        let candidates = [
            "/System/Applications/\(name).app",
            "/System/Applications/Utilities/\(name).app",
            "/Applications/\(name).app"
        ].map(URL.init(fileURLWithPath:))

        let url = candidates.first { FileManager.default.fileExists(atPath: $0.path) } ?? candidates[0]
        NSWorkspace.shared.open(url)
    }
}
