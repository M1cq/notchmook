import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct NotchRootView: View {
    @EnvironmentObject private var model: NookModel
    private let panelSize = CGSize(width: 590, height: 116)

    var body: some View {
        let expanded = model.isExpanded

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
                .scaleEffect(expanded ? 0.82 : 1.0, anchor: .top)
                .opacity(expanded ? 0.0 : 1.0)
                .offset(y: expanded ? -4 : 0)
                .allowsHitTesting(!expanded)
        }
        .frame(width: panelSize.width, height: panelSize.height, alignment: .top)
        .background(Color.clear)
        .compositingGroup()
        .animation(
            .interpolatingSpring(mass: 0.72, stiffness: 310, damping: 34, initialVelocity: 0.08),
            value: model.isExpanded
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

        Button {
            model.expand()
        } label: {
            HStack(spacing: 8) {
                if hasMedia {
                    MediaSourceIcon(snapshot: snapshot)
                    Text(snapshot.title)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.86))
                        .lineLimit(1)
                        .frame(maxWidth: 94, alignment: .leading)
                    Spacer(minLength: 0)
                    Image(systemName: snapshot.isPlaying ? "waveform" : "pause.fill")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white.opacity(0.62))
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
            .padding(.horizontal, hasMedia ? 9 : 0)
            .frame(width: hasMedia ? 180 : 112, height: 24)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 0
                )
                .fill(.black)
                .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open NotchDesk")
        .animation(
            .interpolatingSpring(mass: 0.68, stiffness: 360, damping: 38, initialVelocity: 0.05),
            value: hasMedia
        )
        .onAppear {
            model.mediaController.refresh()
        }
    }
}

private struct MediaSourceIcon: View {
    let snapshot: MediaSnapshot

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: iconColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: 18, height: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 0.5)
        )
    }

    private var symbol: String {
        switch snapshot.appName {
        case "Spotify": "music.note"
        case "YouTube Music": "play.fill"
        case "YouTube": "play.rectangle.fill"
        case "Now Playing": "play.circle.fill"
        default: "music.note"
        }
    }

    private var iconColors: [Color] {
        switch snapshot.appName {
        case "Spotify":
            [Color(red: 0.12, green: 0.72, blue: 0.32), Color(red: 0.04, green: 0.26, blue: 0.12)]
        case "YouTube Music", "YouTube":
            [Color(red: 0.96, green: 0.10, blue: 0.12), Color(red: 0.36, green: 0.04, blue: 0.08)]
        case "Now Playing":
            [Color(red: 0.18, green: 0.42, blue: 0.94), Color(red: 0.08, green: 0.12, blue: 0.34)]
        default:
            [Color(red: 0.56, green: 0.28, blue: 1.0), Color(red: 0.14, green: 0.08, blue: 0.28)]
        }
    }
}

struct ExpandedNookView: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        ZStack(alignment: .top) {
            StripBackground()
            VStack(spacing: 6) {
                HeaderTabs()
                content
                    .frame(height: 64)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        .frame(width: 590, height: 116)
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
            CompactIconTab(tab: .mirror, icon: "camera.viewfinder")
            CompactIconTab(tab: .shortcuts, icon: "bolt.fill")
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
                    colors: model.theme.gradient.map { $0.opacity(0.88) },
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
            .stroke(.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.34), radius: 18, y: 8)
    }
}

private struct NookStripContent: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 8) {
                NookActionButton(title: "AirDrop", icon: "sparkles") {
                    openAirDrop()
                }
                NookActionButton(title: "Open Music", icon: "sparkles") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Music.app"))
                }
            }
            .frame(width: 126)

            VerticalSeparator()

            Button {
                model.expand(tab: .mirror)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 23, weight: .semibold))
                    Text("ミラー")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(.white.opacity(0.78))
                .frame(width: 48, height: 54)
                .background(Circle().fill(.black.opacity(0.32)))
            }
            .buttonStyle(.plain)

            VerticalSeparator()

            CompactMediaBlock(controller: model.mediaController)
                .frame(width: 144)

            VerticalSeparator()

            CompactCalendarBlock(provider: model.calendarProvider)
                .frame(width: 140)
        }
        .frame(maxWidth: .infinity)
    }

    private func openAirDrop() {
        AirDropService.share(model.trayItems.map(\.url))
    }
}

private struct TrayStripContent: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        HStack(spacing: 12) {
            CompactDropZone()
            AirDropDropZone()

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
        HStack(spacing: 12) {
            CompactToggle(title: "Hover", isOn: $model.autoExpandOnHover)
            CompactToggle(title: "Pinned", isOn: $model.isPinned)
            PermissionButton()
            ThemeSwatches()
            Spacer()
        }
    }
}

private struct PermissionButton: View {
    var body: some View {
        Button {
            PermissionService.requestAutomationPrompts()
            PermissionService.openPrivacySettings()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 15, weight: .bold))
                Text("Perms")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(width: 70, height: 54)
            .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(.black.opacity(0.24)))
        }
        .buttonStyle(.plain)
        .help("Request Automation permissions")
    }
}

private struct CompactMediaBlock: View {
    @ObservedObject var controller: MediaController

    var body: some View {
        HStack(spacing: 10) {
            AlbumTile(isPlaying: controller.snapshot.isPlaying)
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 5) {
                Text(controller.snapshot.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(controller.snapshot.artist)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                HStack(spacing: 12) {
                    Button { controller.previousTrack() } label: { Image(systemName: "backward.fill") }
                    Button { controller.togglePlayPause() } label: { Image(systemName: controller.snapshot.isPlaying ? "pause.fill" : "play.fill") }
                    Button { controller.nextTrack() } label: { Image(systemName: "forward.fill") }
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.86))
                .buttonStyle(.plain)
            }
        }
        .onAppear { controller.refresh() }
    }
}

private struct CompactCalendarBlock: View {
    @EnvironmentObject private var model: NookModel
    @ObservedObject var provider: CalendarProvider

    var body: some View {
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

            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                Text(provider.entries.first?.title ?? "今日の予定はありません")
                    .lineLimit(1)
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
}

private struct AlbumTile: View {
    @EnvironmentObject private var model: NookModel
    let isPlaying: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: model.theme.albumGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: isPlaying ? "waveform" : "music.note")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Image(systemName: "music.note.list")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(model.theme.accent))
                .offset(x: 4, y: 4)
        }
    }
}

private struct NookActionButton: View {
    @EnvironmentObject private var model: NookModel
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
            Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(model.theme.accent)
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(Capsule().fill(.black.opacity(0.42)))
        }
        .buttonStyle(.plain)
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
        VStack(spacing: 5) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 17, weight: .semibold))
            Text("Drop files here")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white.opacity(0.72))
        .frame(width: 154, height: 56)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [6, 6]))
                .foregroundStyle(.white.opacity(0.22))
        )
    }
}

private struct CompactToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .frame(width: 86, height: 54)
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(.black.opacity(0.24)))
    }
}

private struct ThemeSwatches: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(NookTheme.allCases) { theme in
                Button {
                    model.theme = theme
                } label: {
                    VStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: theme.gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 26, height: 26)
                            if model.theme == theme {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(.white)
                            }
                        }
                        Text(theme.title)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(model.theme == theme ? 0.92 : 0.52))
                            .lineLimit(1)
                    }
                    .frame(width: 48, height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(model.theme == theme ? .white.opacity(0.12) : .black.opacity(0.18))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(model.theme == theme ? theme.accent.opacity(0.8) : .clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help(theme.title)
            }
        }
    }
}
