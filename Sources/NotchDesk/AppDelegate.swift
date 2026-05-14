import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let model = NookModel()

    private var windowController: NotchWindowController?
    private var settingsWindowController: NSWindowController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettings),
            name: .openNotchDeskSettings,
            object: nil
        )

        let controller = NotchWindowController(model: model)
        controller.showWindow(nil)
        windowController = controller

        configureStatusItem()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "platter.filled.top.iphone", accessibilityDescription: "NotchDesk")
        item.button?.imagePosition = .imageOnly

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show NotchDesk", action: #selector(showNook), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Pin / Unpin", action: #selector(togglePin), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit NotchDesk", action: #selector(quit), keyEquivalent: "q"))

        for menuItem in menu.items {
            menuItem.target = self
        }

        item.menu = menu
        statusItem = item
    }

    @objc private func showNook() {
        model.selectedTab = .dashboard
        model.isExpanded = true
        windowController?.showWindow(nil)
        windowController?.reposition(animated: true)
    }

    @objc private func togglePin() {
        model.isPinned.toggle()
        model.isExpanded = model.isPinned || model.isExpanded
    }

    @objc private func openSettings() {
        showSettingsWindow()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    func showSettingsWindow() {
        NSApp.setActivationPolicy(.regular)

        if let settingsWindowController {
            settingsWindowController.showWindow(nil)
            settingsWindowController.window?.orderFrontRegardless()
            settingsWindowController.window?.makeKeyAndOrderFront(nil)
            NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingView = NSHostingView(
            rootView: SettingsPane()
                .environmentObject(model)
        )
        let window = SettingsPanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        window.title = "NotchDesk Settings"
        window.contentView = hostingView
        window.backgroundColor = NSColor(red: 0.17, green: 0.18, blue: 0.21, alpha: 1.0)
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.delegate = self

        let controller = NSWindowController(window: window)
        settingsWindowController = controller
        controller.showWindow(nil)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === settingsWindowController?.window {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

private final class SettingsPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

extension Notification.Name {
    static let openNotchDeskSettings = Notification.Name("NotchDesk.openSettings")
}
