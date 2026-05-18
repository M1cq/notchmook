import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct NotchRootView: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        let expanded = model.isExpanded
        let peeking = model.isPeeking && expanded == false
        let panelSize = model.displayMetrics.expandedSize

        ZStack(alignment: .top) {
            ExpandedNookView()
                .scaleEffect(
                    x: expanded ? 1.0 : 0.20,
                    y: expanded ? 1.0 : 0.28,
                    anchor: .top
                )
                .opacity(expanded ? 1.0 : 0.0)
                .offset(y: expanded ? 0 : -10)
                .blur(radius: expanded ? 0 : 5)
                .allowsHitTesting(expanded)

            CollapsedNookView()
                .scaleEffect(expanded ? 0.82 : (peeking ? 1.0 : 0.98), anchor: .top)
                .opacity(expanded ? 0.0 : 1.0)
                .offset(y: expanded ? -4 : -1)
                .allowsHitTesting(!expanded)
        }
        .frame(width: panelSize.width, height: panelSize.height, alignment: .top)
        .background(Color.clear)
        .compositingGroup()
        .animation(
            .interpolatingSpring(mass: 0.72, stiffness: 310, damping: 34, initialVelocity: 0.08),
            value: model.isExpanded
        )
        .animation(
            .interpolatingSpring(mass: 0.60, stiffness: 420, damping: 36, initialVelocity: 0.04),
            value: model.isPeeking
        )
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            accepted = true
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
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
                    DispatchQueue.main.async {
                        model.addFiles([url])
                    }
                }
            }
        }
        return accepted
    }
}

struct CollapsedNookView: View {
    @EnvironmentObject private var model: NookModel
    @ObservedObject private var media: MediaController

    init(media: MediaController? = nil) {
        _media = ObservedObject(wrappedValue: media ?? MediaController())
    }

    var body: some View {
        let snapshot = model.mediaController.snapshot
        let hasMedia = snapshot.hasMedia
        let peeking = model.isPeeking

        Button {
            model.expand()
        } label: {
            HStack(spacing: 8) {
                if hasMedia {
                    MediaSourceIcon(snapshot: snapshot)
                        .frame(width: 22, height: 22)
                    Spacer(minLength: 0)
                    CollapsedAudioActivity(isPlaying: snapshot.isPlaying)
                } else {
                    Image(systemName: "platter.filled.top.iphone")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Nook")
                        .font(.system(size: 10, weight: .bold))
                    if model.trayItems.isEmpty == false {
                        CountBadge(count: model.trayItems.count)
                    }
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, hasMedia ? 14 : (peeking ? 14 : 0))
            .frame(width: width(hasMedia: hasMedia, peeking: peeking), height: height(hasMedia: hasMedia, peeking: peeking))
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: peeking ? 16 : 12,
                    bottomTrailingRadius: peeking ? 16 : 12,
                    topTrailingRadius: 0
                )
                .fill(.black)
                .shadow(color: .black.opacity(peeking ? 0.26 : (hasMedia ? 0.08 : 0.12)), radius: peeking ? 10 : (hasMedia ? 2 : 5), y: peeking ? 4 : (hasMedia ? 1 : 2))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open NotchDesk")
        .animation(
            .interpolatingSpring(mass: 0.68, stiffness: 360, damping: 38, initialVelocity: 0.05),
            value: hasMedia
        )
        .animation(
            .interpolatingSpring(mass: 0.60, stiffness: 420, damping: 36, initialVelocity: 0.04),
            value: model.isPeeking
        )
        .onAppear {
            model.mediaController.refresh()
        }
    }

    private func width(hasMedia: Bool, peeking: Bool) -> CGFloat {
        if hasMedia {
            return peeking ? model.displayMetrics.collapsedMediaPeekSize.width : model.displayMetrics.collapsedMediaSize.width
        }
        return peeking ? model.displayMetrics.collapsedIdlePeekSize.width : model.displayMetrics.collapsedIdleSize.width
    }

    private func height(hasMedia: Bool, peeking: Bool) -> CGFloat {
        if hasMedia {
            return peeking ? model.displayMetrics.collapsedMediaPeekSize.height : model.displayMetrics.collapsedMediaSize.height
        }
        return peeking ? model.displayMetrics.collapsedIdlePeekSize.height : model.displayMetrics.collapsedIdleSize.height
    }
}

private struct CollapsedAudioActivity: View {
    let isPlaying: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: isPlaying ? 0.10 : 1.0)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate

            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(.white.opacity(isPlaying ? 0.72 : 0.34))
                        .frame(width: 3, height: barHeight(index: index, phase: phase))
                }
            }
            .frame(width: 34, height: 18)
            .opacity(isPlaying ? 1.0 : 0.55)
        }
    }

    private func barHeight(index: Int, phase: TimeInterval) -> CGFloat {
        guard isPlaying else {
            return CGFloat([5, 10, 7][index])
        }

        let offsets: [Double] = [0.0, 1.2, 2.4]
        let base = sin((phase * 5.2) + offsets[index])
        let normalized = (base + 1.0) / 2.0
        return 5 + CGFloat(normalized) * 13
    }
}

private struct MediaSourceIcon: View {
    let snapshot: MediaSnapshot

    var body: some View {
        ZStack {
            MediaArtworkView(artworkURL: snapshot.artworkURL, cornerRadius: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: iconColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    Image(systemName: mediaSourceSymbol(for: snapshot.appName))
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: 18, height: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 0.5)
        )
    }

    private var iconColors: [Color] {
        mediaSourceColors(for: snapshot.appName)
    }
}

private func mediaSourceSymbol(for appName: String) -> String {
    switch appName {
    case "Spotify": "music.note"
    case "YouTube Music": "play.fill"
    case "YouTube": "play.rectangle.fill"
    case "Netflix": "n.square.fill"
    case "Dia": "play.square.stack.fill"
    case "Music": "music.note"
    case "Now Playing": "play.circle.fill"
    default: "music.note"
    }
}

private func mediaSourceColors(for appName: String) -> [Color] {
    switch appName {
    case "Spotify":
        [Color(red: 0.12, green: 0.72, blue: 0.32), Color(red: 0.04, green: 0.26, blue: 0.12)]
    case "YouTube Music", "YouTube":
        [Color(red: 0.96, green: 0.10, blue: 0.12), Color(red: 0.36, green: 0.04, blue: 0.08)]
    case "Netflix":
        [Color(red: 0.90, green: 0.02, blue: 0.04), Color(red: 0.14, green: 0.00, blue: 0.01)]
    case "Dia":
        [Color(red: 0.24, green: 0.24, blue: 0.28), Color(red: 0.04, green: 0.04, blue: 0.06)]
    case "Music":
        [Color(red: 1.00, green: 0.27, blue: 0.40), Color(red: 0.88, green: 0.12, blue: 0.34)]
    case "Now Playing":
        [Color(red: 0.18, green: 0.42, blue: 0.94), Color(red: 0.08, green: 0.12, blue: 0.34)]
    default:
        [Color(red: 0.56, green: 0.28, blue: 1.0), Color(red: 0.14, green: 0.08, blue: 0.28)]
    }
}

struct ExpandedNookView: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        let metrics = model.displayMetrics
        ZStack(alignment: .top) {
            StripBackground()
            VStack(spacing: 6) {
                HeaderTabs()
                content
                    .frame(height: metrics.contentHeight)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        .frame(width: metrics.expandedSize.width, height: metrics.expandedSize.height)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 24,
                bottomTrailingRadius: 24,
                topTrailingRadius: 0
            )
        )
    }

    @ViewBuilder
    private var content: some View {
        switch model.selectedTab {
        case .dashboard:
            NookStripContent()
        case .tray:
            TrayStripContent()
        case .mirror:
            MirrorStripContent()
        case .shortcuts:
            ShortcutsStripContent()
        case .settings:
            SettingsStripContent()
        }
    }
}

private struct HeaderTabs: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        HStack(spacing: 8) {
            CompactTabButton(tab: .dashboard, title: "Nook", icon: "platter.filled.top.iphone")
            CompactTabButton(tab: .tray, title: "トレイ", icon: "tray.full")
            Spacer()
            CompactTabButton(tab: .shortcuts, title: "Quick", icon: "bolt.fill")
            CompactIconTab(tab: .mirror, icon: "camera.viewfinder")
            CompactIconTab(tab: .settings, icon: "gearshape.fill")
        }
        .frame(height: 22)
    }
}

private struct CompactTabButton: View {
    @EnvironmentObject private var model: NookModel
    let tab: NookTab
    let title: String
    let icon: String

    var body: some View {
        Button {
            model.expand(tab: tab)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(model.selectedTab == tab ? .white : .white.opacity(0.72))
            .padding(.horizontal, 9)
            .frame(height: 22)
            .background(
                Capsule()
                    .fill(model.selectedTab == tab ? .black.opacity(0.42) : .white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CompactIconTab: View {
    @EnvironmentObject private var model: NookModel
    let tab: NookTab
    let icon: String

    var body: some View {
        Button {
            model.expand(tab: tab)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(model.selectedTab == tab ? .white : .white.opacity(0.64))
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(model.selectedTab == tab ? .black.opacity(0.42) : .white.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
        .help(tab.title)
    }
}

private struct StripBackground: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 24,
            bottomTrailingRadius: 24,
            topTrailingRadius: 0
        )
        .fill(.ultraThinMaterial)
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 24,
                bottomTrailingRadius: 24,
                topTrailingRadius: 0
            )
            .fill(
                LinearGradient(
                    colors: model.theme.gradient.map { $0.opacity(model.theme == .black ? 1.0 : 0.88) },
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 24,
                bottomTrailingRadius: 24,
                topTrailingRadius: 0
            )
            .stroke(.white.opacity(model.theme == .black ? 0.0 : 0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.34), radius: 18, y: 8)
    }
}

private struct NookStripContent: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        Group {
            switch model.nookLayout {
            case .classic:
                ClassicNookStripContent()
            case .musicLarge:
                MusicLargeNookStripContent()
            case .custom:
                CustomNookStripContent()
            }
        }
    }
}

private struct ClassicNookStripContent: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 8) {
                ForEach(Array(model.nookActions.prefix(2).enumerated()), id: \.element.id) { _, action in
                    NookActionButton(title: action.title, icon: action.symbol, tint: action.tint) {
                        model.performNookAction(action)
                    }
                }
            }
            .frame(width: 126)

            VerticalSeparator()

            MirrorWidgetButton(size: 54, iconSize: 22)

            VerticalSeparator()

            CompactMediaBlock(controller: model.mediaController)
                .frame(width: 144)

            VerticalSeparator()

            CompactCalendarBlock(provider: model.calendarProvider)
                .frame(width: 140)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MusicLargeNookStripContent: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        HStack(spacing: 14) {
            HeroMediaBlock(controller: model.mediaController)
                .frame(width: 216)

            VerticalSeparator()

            VStack(spacing: 8) {
                if let action = model.nookActions.first {
                    NookActionButton(title: action.title, icon: action.symbol, tint: action.tint) {
                        model.performNookAction(action)
                    }
                    .frame(width: 178)
                }
                if model.nookActions.count > 1 {
                    let action = model.nookActions[1]
                    NookActionButton(title: action.title, icon: action.symbol, tint: action.tint) {
                        model.performNookAction(action)
                    }
                    .frame(width: 178)
                }
            }
            .frame(width: 190)

            VerticalSeparator()

            MirrorWidgetButton(size: 64, iconSize: 25)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CustomNookStripContent: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        GeometryReader { proxy in
            let widgets = model.orderedWidgetConfigs().filter(\.isEnabled)
            let activeWidgets = widgets.isEmpty ? NookWidgetConfig.defaults.filter(\.isEnabled) : widgets
            let spacing: CGFloat = 10
            let totalSpacing = spacing * CGFloat(max(activeWidgets.count - 1, 0))
            let totalWeight = max(activeWidgets.reduce(0) { $0 + $1.weight }, 0.1)
            let availableWidth = max(proxy.size.width - totalSpacing, 1)

            HStack(spacing: spacing) {
                ForEach(activeWidgets) { config in
                    CustomNookWidget(config: config)
                        .frame(
                            width: max(44, availableWidth * CGFloat(config.weight / totalWeight)),
                            height: 64
                        )
                        .clipped()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct CustomNookWidget: View {
    @EnvironmentObject private var model: NookModel
    let config: NookWidgetConfig

    var body: some View {
        switch config.kind {
        case .actions:
            NookActionsWidget()
        case .media:
            CompactMediaBlock(controller: model.mediaController)
        case .calendar:
            CompactCalendarBlock(provider: model.calendarProvider)
        case .mirror:
            MirrorWidgetButton()
        case .shortcuts:
            CustomShortcutsWidget()
        case .notes:
            NotesWidget()
        }
    }
}

private struct NookActionsWidget: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        GeometryReader { proxy in
            let scale = min(1, max(0, (proxy.size.width - 118) / 110))
            let spacing = 8 + (2 * scale)
            let buttonHeight = min(31, max(27, (proxy.size.height - spacing - 4) / 2))
            let titleSize = 10 + (2 * scale)
            let iconSize = 10 + (2 * scale)

            VStack(spacing: spacing) {
                ForEach(Array(model.nookActions.prefix(2).enumerated()), id: \.element.id) { _, action in
                    NookActionButton(
                        title: action.title,
                        icon: action.symbol,
                        tint: action.tint,
                        height: buttonHeight,
                        titleSize: titleSize,
                        iconSize: iconSize
                    ) {
                        model.performNookAction(action)
                    }
                }
            }
            .padding(.vertical, 2)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
        }
    }
}

private struct MirrorWidgetButton: View {
    @EnvironmentObject private var model: NookModel
    var size: CGFloat = 58
    var iconSize: CGFloat = 23

    var body: some View {
        Button {
            model.expand(tab: .mirror)
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(model.theme == .black ? 0.13 : 0.10),
                                Color.black.opacity(model.theme == .black ? 0.78 : 0.42)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(model.theme == .black ? 0.22 : 0.14), lineWidth: 1)
                    )
                    .overlay(
                        Circle()
                            .stroke(.black.opacity(0.34), lineWidth: 1)
                            .blur(radius: 0.6)
                            .offset(y: 1)
                            .mask(Circle().fill(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)))
                    )

                VStack(spacing: 3) {
                    Image(systemName: "web.camera.fill")
                        .font(.system(size: iconSize, weight: .bold))
                    Text("ミラー")
                        .font(.system(size: 9, weight: .black))
                }
                .foregroundStyle(.white.opacity(0.68))
            }
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.22), radius: 5, y: 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }
}

private struct CustomShortcutsWidget: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        HStack(spacing: 6) {
            ForEach(model.shortcuts.prefix(2)) { shortcut in
                Button {
                    shortcut.action()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: shortcut.symbol)
                            .font(.system(size: 13, weight: .bold))
                        Text(shortcut.title)
                            .font(.system(size: 8, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: 56)
                    .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(.black.opacity(0.24)))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct NotesWidget: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.system(size: 17, weight: .bold))
            VStack(alignment: .leading, spacing: 3) {
                Text("Notes")
                    .font(.system(size: 11, weight: .bold))
                Text("Quick note")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.52))
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: 56)
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(.black.opacity(0.24)))
    }
}

private struct TrayStripContent: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        HStack(spacing: 10) {
            CompactDropZone()
                .frame(maxWidth: .infinity, minHeight: 64)
            AirDropDropZone(width: 0, height: 64, compact: false)
                .frame(maxWidth: .infinity, minHeight: 64)

            if model.trayItems.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(model.trayItems) { item in
                            FileChip(item: item)
                                .onDrag {
                                    NSItemProvider(contentsOf: item.url) ?? NSItemProvider(object: item.url.path as NSString)
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Button {
                    model.clearTray()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(ChromeIconButtonStyle())
            }
        }
    }
}

private struct MirrorStripContent: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        HStack(spacing: 12) {
            CameraPreview(session: model.cameraController.session)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .frame(width: 120, height: 64)
            VStack(alignment: .leading, spacing: 8) {
                Text("Mirror")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text(model.cameraController.authorizationLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
                HStack {
                    Button("Start") { model.cameraController.start() }
                    Button("Stop") { model.cameraController.stop() }
                }
                .buttonStyle(PrimaryTextButtonStyle())
            }
            Spacer()
        }
        .onAppear { model.cameraController.start() }
        .onDisappear { model.cameraController.stop() }
    }
}

private struct ShortcutsStripContent: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(model.shortcuts.prefix(5)) { shortcut in
                Button {
                    shortcut.action()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: shortcut.symbol)
                            .font(.system(size: 15, weight: .bold))
                        Text(shortcut.title)
                            .font(.system(size: 9, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 76, height: 54)
                    .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(.black.opacity(0.24)))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct SettingsStripContent: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        HStack(spacing: 8) {
            SettingsWindowButton()
            ThemeSwatches()
            CompactToggle(title: "Hover", icon: "cursorarrow.motionlines", isOn: $model.autoExpandOnHover)
            CompactToggle(title: "Pin", icon: "pin.fill", isOn: $model.isPinned)
            PermissionButton()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct SettingsWindowButton: View {
    var body: some View {
        Button {
            openSettingsWindow()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .bold))
                Text("Edit")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 13)
            .frame(height: 38)
            .background(SettingsControlBackground())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded(openSettingsWindow))
        .help("Open customization settings")
    }

    private func openSettingsWindow() {
        NotificationCenter.default.post(name: .openNotchDeskSettings, object: nil)
    }
}

private struct PermissionButton: View {
    var body: some View {
        Button {
            PermissionService.requestAutomationPrompts()
            PermissionService.openPrivacySettings()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 13, weight: .bold))
                Text("Perms")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 13)
            .frame(height: 38)
            .background(SettingsControlBackground())
        }
        .buttonStyle(.plain)
        .help("Request Automation permissions")
    }
}

private struct HeroMediaBlock: View {
    @ObservedObject var controller: MediaController

    var body: some View {
        let snapshot = controller.snapshot

        HStack(spacing: 10) {
            AlbumTile(snapshot: snapshot)
                .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.title)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(snapshot.artist)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Button { controller.previousTrack() } label: { Image(systemName: "backward.fill") }
                    Button { controller.togglePlayPause() } label: { Image(systemName: snapshot.isPlaying ? "pause.fill" : "play.fill") }
                    Button { controller.nextTrack() } label: { Image(systemName: "forward.fill") }
                    Spacer(minLength: 4)
                    MediaSourceBadge(snapshot: snapshot, showTitle: true)
                }
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white.opacity(0.90))
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { controller.refresh() }
    }
}

private struct CompactMediaBlock: View {
    @ObservedObject var controller: MediaController

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let scale = min(1, max(0, (width - 140) / 90))
            let artworkSize = 50 + (14 * scale)
            let titleSize = 11 + (3 * scale)
            let artistSize = 9 + (2 * scale)
            let controlSize = 10 + (2 * scale)
            let controlSpacing = 12 + (4 * scale)

            HStack(spacing: 10 + (2 * scale)) {
                AlbumTile(snapshot: controller.snapshot)
                    .frame(width: artworkSize, height: artworkSize)

                VStack(alignment: .leading, spacing: 4 + (2 * scale)) {
                    Text(controller.snapshot.title)
                        .font(.system(size: titleSize, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(scale > 0.65 ? 2 : 1)
                        .minimumScaleFactor(0.82)

                    Text(controller.snapshot.artist)
                        .font(.system(size: artistSize, weight: .bold))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    HStack(spacing: controlSpacing) {
                        Button { controller.previousTrack() } label: { Image(systemName: "backward.fill") }
                        Button { controller.togglePlayPause() } label: { Image(systemName: controller.snapshot.isPlaying ? "pause.fill" : "play.fill") }
                        Button { controller.nextTrack() } label: { Image(systemName: "forward.fill") }
                        Spacer(minLength: 3)
                        MediaSourceBadge(snapshot: controller.snapshot, showTitle: scale > 0.55)
                    }
                    .font(.system(size: controlSize, weight: .black))
                    .foregroundStyle(.white.opacity(0.88))
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { controller.refresh() }
    }
}

private struct CompactCalendarBlock: View {
    @EnvironmentObject private var model: NookModel
    @ObservedObject var provider: CalendarProvider

    var body: some View {
        let todayEntry = provider.todayEntries.first

        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(monthText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.70))
                Text(dayText)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 7) {
                ForEach(weekdays, id: \.self) { item in
                    Text(item)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(item == dayNumberText ? model.theme.accent : .white.opacity(0.34))
                }
            }

            HStack(spacing: 5) {
                Image(systemName: "calendar.badge.clock")
                if let entry = todayEntry {
                    Text(timeText(for: entry))
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(model.theme.accent)
                    Text(entry.title)
                        .lineLimit(1)
                } else {
                    Text("今日の予定はありません")
                        .lineLimit(1)
                }
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white.opacity(0.52))
        }
        .onAppear { provider.reload() }
    }

    private var monthText: String {
        Date().formatted(.dateTime.month(.abbreviated))
    }

    private var dayText: String {
        Date().formatted(.dateTime.day())
    }

    private var dayNumberText: String {
        Date().formatted(.dateTime.day(.twoDigits))
    }

    private var weekdays: [String] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<6).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - 2, to: today) else { return nil }
            return date.formatted(.dateTime.day(.twoDigits))
        }
    }

    private func timeText(for entry: CalendarEntry) -> String {
        if entry.isAllDay {
            return "終日"
        }
        return entry.startDate.formatted(date: .omitted, time: .shortened)
    }
}

private struct AlbumTile: View {
    @EnvironmentObject private var model: NookModel
    let snapshot: MediaSnapshot

    var body: some View {
        MediaArtworkView(artworkURL: snapshot.artworkURL, cornerRadius: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: model.theme.albumGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: snapshot.isPlaying ? "waveform" : "music.note")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if snapshot.hasMedia {
                MediaSourceIconBadge(snapshot: snapshot)
                    .offset(x: 4, y: 4)
            }
        }
    }
}

private struct MediaSourceBadge: View {
    let snapshot: MediaSnapshot
    let showTitle: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: mediaSourceSymbol(for: snapshot.appName))
                .font(.system(size: 7.5, weight: .black))
            if showTitle {
                Text(displayName)
                    .font(.system(size: 7.5, weight: .black))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.white.opacity(0.90))
        .padding(.horizontal, showTitle ? 6 : 5)
        .frame(height: 16)
        .background(
            Capsule()
                .fill(.white.opacity(0.10))
                .overlay(Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 0.8))
        )
        .fixedSize(horizontal: true, vertical: false)
        .opacity(snapshot.hasMedia ? 1 : 0)
    }

    private var displayName: String {
        if snapshot.appName.hasPrefix("com.") {
            return snapshot.appName.components(separatedBy: ".").last?.capitalized ?? "Media"
        }
        return snapshot.appName
    }
}

private struct MediaSourceIconBadge: View {
    let snapshot: MediaSnapshot

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: mediaSourceColors(for: snapshot.appName),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(.white.opacity(0.26), lineWidth: 0.8)
                )
            Image(systemName: mediaSourceSymbol(for: snapshot.appName))
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: 22, height: 22)
        .shadow(color: .black.opacity(0.26), radius: 4, y: 2)
    }
}
private struct NookActionButton: View {
    @EnvironmentObject private var model: NookModel
    let title: String
    let icon: String
    var tint: Color?
    var height: CGFloat = 28
    var titleSize: CGFloat = 10
    var iconSize: CGFloat = 10
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
            Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(tint ?? model.theme.accent)
                Text(title)
                    .font(.system(size: titleSize, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Spacer()
            }
            .padding(.horizontal, 12 + max(0, titleSize - 10))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(actionButtonBackground)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var actionButtonBackground: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(model.theme == .black ? 0.13 : 0.09),
                        Color.black.opacity(model.theme == .black ? 0.34 : 0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Capsule()
                    .strokeBorder(.white.opacity(model.theme == .black ? 0.20 : 0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
    }
}

private struct VerticalSeparator: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.12))
            .frame(width: 1, height: 58)
    }
}

private struct CompactDropZone: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tray.full.fill")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.blue.opacity(0.90))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text("ファイルトレイ")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.82))
                Text("Drop files here")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 64, maxHeight: 64)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            Color.blue.opacity(0.55),
                            style: StrokeStyle(lineWidth: 1.4, dash: [6, 7])
                        )
                )
        )
    }
}

private struct CompactToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isOn ? .white : .white.opacity(0.58))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                ToggleDot(isOn: isOn)
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(SettingsControlBackground(isActive: isOn))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ToggleDot: View {
    let isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? Color.white.opacity(0.28) : Color.white.opacity(0.10))
            Circle()
                .fill(isOn ? Color.white : Color.white.opacity(0.48))
                .frame(width: 12, height: 12)
                .padding(2)
        }
        .frame(width: 28, height: 16)
    }
}

private struct SettingsControlBackground: View {
    @EnvironmentObject private var model: NookModel
    var isActive = false

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isActive ? 0.18 : 0.10),
                        Color.black.opacity(model.theme == .black ? 0.42 : 0.28)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Capsule()
                    .strokeBorder(.white.opacity(isActive ? 0.20 : 0.12), lineWidth: 1)
            )
    }
}

private struct ThemeSwatches: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        Menu {
            Section("Theme") {
                ForEach(NookTheme.allCases) { theme in
                    Button(theme.title) {
                        model.theme = theme
                    }
                }
            }
            Section("Layout") {
                ForEach(NookLayout.allCases) { layout in
                    Button(layout.title) {
                        model.nookLayout = layout
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: model.theme.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(Circle().strokeBorder(.white.opacity(0.24), lineWidth: 1))
                    .frame(width: 16, height: 16)
                Text(model.theme.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                Image(systemName: model.nookLayout.systemImage)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(SettingsControlBackground())
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
        .help("Theme and layout")
    }
}
