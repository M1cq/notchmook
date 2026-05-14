import AppKit
import Combine
import SwiftUI

final class NotchWindowController: NSWindowController {
    private let model: NookModel
    private var cancellables = Set<AnyCancellable>()

    private let expandedSize = NSSize(width: 590, height: 116)
    private var hoverTimer: Timer?

    init(model: NookModel) {
        self.model = model

        let rootView = NotchRootView()
            .environmentObject(model)

        let hostingView = ClearHostingView(rootView: rootView, model: model)
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
        panel.ignoresMouseEvents = true
        panel.acceptsMouseMovedEvents = true

        super.init(window: panel)

        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView?.layer?.isOpaque = false

        panel.orderFrontRegardless()
        bindModel()
        startCollapsedHoverMonitor()
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
        hoverTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func bindModel() {
        Publishers.CombineLatest(model.$isExpanded, model.$isPeeking)
            .receive(on: RunLoop.main)
            .sink { [weak self] isExpanded, isPeeking in
                self?.window?.ignoresMouseEvents = !(isExpanded || isPeeking)
            }
            .store(in: &cancellables)
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

    private func startCollapsedHoverMonitor() {
        hoverTimer?.invalidate()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updatePeekStateForPointer()
        }
        hoverTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func updatePeekStateForPointer() {
        guard model.autoExpandOnHover, model.isExpanded == false else { return }

        let point = NSEvent.mouseLocation
        if model.isPeeking {
            if peekScreenRect().contains(point) == false {
                model.collapsePeek()
            }
            return
        }

        guard collapsedHoverScreenRect().contains(point) else { return }

        window?.orderFrontRegardless()
        model.peek()
    }

    private func collapsedHoverScreenRect() -> NSRect {
        let screen = targetScreen()
        let frame = screen.frame
        let size = collapsedIdleSize()
        return NSRect(
            x: frame.midX - (size.width / 2),
            y: frame.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }

    private func peekScreenRect() -> NSRect {
        let screen = targetScreen()
        let frame = screen.frame
        let hasMedia = model.mediaController.snapshot.hasMedia
        let size = hasMedia ? NSSize(width: 322, height: 42) : NSSize(width: 166, height: 34)
        return NSRect(
            x: frame.midX - (size.width / 2),
            y: frame.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }

    private func collapsedIdleSize() -> NSSize {
        model.mediaController.snapshot.hasMedia
            ? NSSize(width: 272, height: 34)
            : NSSize(width: 112, height: 24)
    }
}

private final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private final class ClearHostingView<Content: View>: NSHostingView<Content> {
    private weak var model: NookModel?
    private var trackingArea: NSTrackingArea?

    init(rootView: Content, model: NookModel) {
        self.model = model
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

        let hitSize = collapsedInteractiveSize
        let collapsedRect = NSRect(
            x: bounds.midX - (hitSize.width / 2),
            y: bounds.maxY - hitSize.height,
            width: hitSize.width,
            height: hitSize.height
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
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if model?.isExpanded == true {
            model?.scheduleCollapse()
        }
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
        let size = collapsedIdleSize
        return NSRect(
            x: bounds.midX - (size.width / 2),
            y: bounds.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }

    private func shouldExpandFromCollapsed(at point: NSPoint) -> Bool {
        collapsedHoverRect.contains(point)
    }

    private var collapsedInteractiveSize: NSSize {
        guard let model, model.isPeeking else {
            return collapsedIdleSize
        }

        return model.mediaController.snapshot.hasMedia
            ? NSSize(width: 322, height: 42)
            : NSSize(width: 166, height: 34)
    }

    private var collapsedIdleSize: NSSize {
        guard let model else {
            return NSSize(width: 112, height: 24)
        }

        return model.mediaController.snapshot.hasMedia
            ? NSSize(width: 272, height: 34)
            : NSSize(width: 112, height: 24)
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
