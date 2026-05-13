import AppKit
import Combine
import SwiftUI

final class NotchWindowController: NSWindowController {
    private let model: NookModel
    private var cancellables = Set<AnyCancellable>()

    private let collapsedSize = NSSize(width: 180, height: 24)
    private let expandedSize = NSSize(width: 590, height: 116)

    init(model: NookModel) {
        self.model = model

        let rootView = NotchRootView()
            .environmentObject(model)

        let hostingView = ClearHostingView(
            rootView: rootView,
            model: model,
            collapsedHitSize: collapsedSize
        )
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.isOpaque = false

        let panel = NotchPanel(
            contentRect: NSRect(origin: .zero, size: expandedSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true

        super.init(window: panel)

        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView?.layer?.isOpaque = false

        panel.orderFrontRegardless()
        bindModel()
        reposition(animated: false)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func bindModel() {
    }

    @objc private func screenParametersChanged() {
        reposition(animated: false)
    }

    func reposition(animated: Bool) {
        guard let window else { return }

        let size = expandedSize
        let screen = targetScreen()
        let frame = screen.frame
        let origin = NSPoint(
            x: frame.midX - (size.width / 2),
            y: frame.maxY - size.height
        )
        let target = NSRect(origin: origin, size: size)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(target, display: true)
            }
        } else {
            window.setFrame(target, display: true)
        }
    }

    private func targetScreen() -> NSScreen {
        NSScreen.main ?? NSScreen.screens[0]
    }
}

private final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private final class ClearHostingView<Content: View>: NSHostingView<Content> {
    private weak var model: NookModel?
    private let collapsedHitSize: NSSize
    private var trackingArea: NSTrackingArea?

    init(rootView: Content, model: NookModel, collapsedHitSize: NSSize) {
        self.model = model
        self.collapsedHitSize = collapsedHitSize
        super.init(rootView: rootView)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }

    @available(*, unavailable)
    @MainActor dynamic required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isOpaque: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard model?.isExpanded == false else {
            return super.hitTest(point)
        }

        let collapsedRect = NSRect(
            x: bounds.midX - (collapsedHitSize.width / 2),
            y: bounds.maxY - collapsedHitSize.height,
            width: collapsedHitSize.width,
            height: collapsedHitSize.height
        )

        guard collapsedRect.contains(point) else {
            return nil
        }
        return super.hitTest(point)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        guard let model, model.autoExpandOnHover, model.isExpanded == false else { return }

        let point = convert(event.locationInWindow, from: nil)
        if collapsedHoverRect.contains(point) {
            model.expand()
        }
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        guard let model, model.autoExpandOnHover, model.isExpanded == false else { return }

        let point = convert(event.locationInWindow, from: nil)
        if collapsedHoverRect.contains(point) {
            model.expand()
        }
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        model?.scheduleCollapse()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasFileURLs(sender) else { return [] }
        model?.expand(tab: .tray)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        hasFileURLs(sender) ? .copy : []
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true
        ]
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL],
              urls.isEmpty == false else {
            return false
        }

        model?.addFiles(urls)
        return true
    }

    private func hasFileURLs(_ sender: NSDraggingInfo) -> Bool {
        sender.draggingPasteboard.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        )
    }

    private var collapsedHoverRect: NSRect {
        NSRect(
            x: bounds.midX - (collapsedHitSize.width / 2) - 10,
            y: bounds.maxY - collapsedHitSize.height - 4,
            width: collapsedHitSize.width + 20,
            height: collapsedHitSize.height + 8
        )
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
        window?.backgroundColor = .clear
        window?.isOpaque = false
    }
}
