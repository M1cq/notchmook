import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = NookModel()

    private var windowController: NotchWindowController?
    private var settingsWindowController: NSWindowController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

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
        if let settingsWindowController {
            settingsWindowController.showWindow(nil)
            settingsWindowController.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingView = NSHostingView(
            rootView: SettingsPane()
                .environmentObject(model)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 380),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "NotchDesk Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false

        let controller = NSWindowController(window: window)
        settingsWindowController = controller
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
