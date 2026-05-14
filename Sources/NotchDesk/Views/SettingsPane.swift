import SwiftUI

private enum SettingsCategory: String, CaseIterable, Identifiable {
    case general
    case gestures
    case liveActivities
    case nook
    case tray
    case dropArea
    case license
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .gestures: "Gestures"
        case .liveActivities: "Live Activities"
        case .nook: "Nook"
        case .tray: "Tray"
        case .dropArea: "Drop Area"
        case .license: "License"
        case .about: "About"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape.fill"
        case .gestures: "hand.tap.fill"
        case .liveActivities: "clock.fill"
        case .nook: "platter.filled.top.iphone"
        case .tray: "tray.full"
        case .dropArea: "rectangle.dashed"
        case .license: "key.fill"
        case .about: "ellipsis.circle.fill"
        }
    }
}

struct SettingsPane: View {
    @EnvironmentObject private var model: NookModel
    @State private var selectedCategory: SettingsCategory = .nook

    var body: some View {
        VStack(spacing: 0) {
            SettingsToolbar(selectedCategory: $selectedCategory)
            Divider()
                .background(.white.opacity(0.10))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    content
                }
                .padding(18)
            }
        }
        .frame(width: 700, height: 540)
        .background(Color(red: 0.17, green: 0.18, blue: 0.21))
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        switch selectedCategory {
        case .general:
            GeneralSettings()
        case .gestures:
            GesturesSettings()
        case .liveActivities:
            LiveActivitiesSettings()
        case .nook:
            NookSettings()
        case .tray:
            TraySettings()
        case .dropArea:
            DropAreaSettings()
        case .license:
            LicenseSettings()
        case .about:
            AboutSettings()
        }
    }
}

private struct SettingsToolbar: View {
    @Binding var selectedCategory: SettingsCategory

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SettingsCategory.allCases) { category in
                Button {
                    selectedCategory = category
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: category.symbol)
                            .font(.system(size: 19, weight: .semibold))
                        Text(category.title)
                            .font(.system(size: category == .liveActivities ? 9 : 10, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                    .foregroundStyle(selectedCategory == category ? .blue : .white.opacity(0.52))
                    .frame(width: category == .liveActivities ? 86 : 70, height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedCategory == category ? .blue.opacity(0.10) : .clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.20, green: 0.21, blue: 0.24))
    }
}

private struct GeneralSettings: View {
    @EnvironmentObject private var model: NookModel
    @AppStorage("NotchDesk.showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("NotchDesk.reduceMotion") private var reduceMotion = false
    @AppStorage("NotchDesk.hapticFeedback") private var hapticFeedback = true
    @AppStorage("NotchDesk.openAtLogin") private var openAtLogin = false

    var body: some View {
        SettingsSection(title: "General", subtitle: "Core behavior and system presence.") {
            VStack(spacing: 10) {
                ToggleRow(title: "Open at login", subtitle: "Start NotchDesk when you sign in.", isOn: $openAtLogin)
                ToggleRow(title: "Show menu bar icon", subtitle: "Keep the small status menu for settings and quit.", isOn: $showMenuBarIcon)
                ToggleRow(title: "Notchless handler", subtitle: "Show a top handle on Macs without a physical notch.", isOn: $model.notchlessHandler)
                ToggleRow(title: "Haptic feedback", subtitle: "Use subtle feedback when opening or switching sections.", isOn: $hapticFeedback)
                ToggleRow(title: "Reduce motion", subtitle: "Use calmer transitions for the Nook and live activities.", isOn: $reduceMotion)
            }
        }
    }
}

private struct GesturesSettings: View {
    @EnvironmentObject private var model: NookModel
    @AppStorage("NotchDesk.swipeMediaGestures") private var swipeMediaGestures = true
    @AppStorage("NotchDesk.swipeWidgetGestures") private var swipeWidgetGestures = true
    @AppStorage("NotchDesk.dragToTray") private var dragToTray = true
    @AppStorage("NotchDesk.clickToOpenAfterPeek") private var clickToOpenAfterPeek = true
    @AppStorage("NotchDesk.gestureSensitivity") private var gestureSensitivity = 0.45

    var body: some View {
        SettingsSection(title: "Gestures", subtitle: "Three-stage opening and quick interactions.") {
            VStack(spacing: 12) {
                ToggleRow(title: "Open on hover", subtitle: "Near the notch, show a small preview before click-to-open.", isOn: $model.autoExpandOnHover)
                ToggleRow(title: "Click after peek", subtitle: "Require a click before expanding the full Nook.", isOn: $clickToOpenAfterPeek)
                ToggleRow(title: "Swipe media controls", subtitle: "Use horizontal swipes for previous and next media.", isOn: $swipeMediaGestures)
                ToggleRow(title: "Swipe between widgets", subtitle: "Move through Nook widgets with trackpad gestures.", isOn: $swipeWidgetGestures)
                ToggleRow(title: "Drag files to tray", subtitle: "Open the tray when files are dragged to the notch.", isOn: $dragToTray)
                SliderRow(title: "Gesture sensitivity", value: $gestureSensitivity, range: 0...1, valueText: "\(Int(gestureSensitivity * 100))%")
            }
        }
    }
}

private struct LiveActivitiesSettings: View {
    @AppStorage("NotchDesk.mediaLiveActivity") private var mediaLiveActivity = true
    @AppStorage("NotchDesk.calendarLiveActivity") private var calendarLiveActivity = true
    @AppStorage("NotchDesk.volumeHudLiveActivity") private var volumeHudLiveActivity = true
    @AppStorage("NotchDesk.brightnessHudLiveActivity") private var brightnessHudLiveActivity = true
    @AppStorage("NotchDesk.showInFullscreen") private var showInFullscreen = false
    @AppStorage("NotchDesk.liveActivityDelay") private var liveActivityDelay = 4.0

    var body: some View {
        VStack(spacing: 18) {
            SettingsSection(title: "Live Activities", subtitle: "Small temporary indicators around the notch.") {
                VStack(spacing: 10) {
                    ToggleRow(title: "Now Playing", subtitle: "Show cover art and state when media starts playing.", isOn: $mediaLiveActivity)
                    ToggleRow(title: "Calendar alerts", subtitle: "Show upcoming events and countdowns near the notch.", isOn: $calendarLiveActivity)
                    ToggleRow(title: "Volume HUD", subtitle: "Replace the native volume overlay with a notch activity.", isOn: $volumeHudLiveActivity)
                    ToggleRow(title: "Brightness HUD", subtitle: "Replace the native brightness overlay with a notch activity.", isOn: $brightnessHudLiveActivity)
                    ToggleRow(title: "Show in fullscreen", subtitle: "Allow live activities above fullscreen apps.", isOn: $showInFullscreen)
                    SliderRow(title: "Auto-hide delay", value: $liveActivityDelay, range: 1...10, valueText: "\(Int(liveActivityDelay))s")
                }
            }
        }
    }
}

private struct NookSettings: View {
    var body: some View {
        VStack(spacing: 18) {
            NookPreviewCard()
            AppearanceSettings()
            WidgetSettings()
            CalendarWidgetSettings()
            NookActionsSettings()
        }
    }
}

private struct TraySettings: View {
    @EnvironmentObject private var model: NookModel
    @AppStorage("NotchDesk.trayEnabled") private var trayEnabled = true
    @AppStorage("NotchDesk.traySameWidth") private var traySameWidth = true
    @AppStorage("NotchDesk.clearTrayOnQuit") private var clearTrayOnQuit = true
    @AppStorage("NotchDesk.showTrayCount") private var showTrayCount = true
    @AppStorage("NotchDesk.airDropTarget") private var airDropTarget = true

    var body: some View {
        SettingsSection(title: "Tray", subtitle: "Temporary file shelf and AirDrop helpers.") {
            VStack(spacing: 10) {
                ToggleRow(title: "Enable tray", subtitle: "Show the tray tab next to the Nook.", isOn: $trayEnabled)
                ToggleRow(title: "Match Nook width", subtitle: "Keep tray and Nook the same width to prevent accidental closes.", isOn: $traySameWidth)
                ToggleRow(title: "Show item count", subtitle: "Display the number of held files on the collapsed Nook.", isOn: $showTrayCount)
                ToggleRow(title: "AirDrop target", subtitle: "Drop files onto the AirDrop area to share immediately.", isOn: $airDropTarget)
                ToggleRow(title: "Clear on quit", subtitle: "Remove temporary files from memory when NotchDesk quits.", isOn: $clearTrayOnQuit)

                HStack {
                    Label("\(model.trayItems.count) files in memory", systemImage: "tray.full")
                    Spacer()
                    Button("Clear tray") {
                        model.clearTray()
                    }
                    .buttonStyle(SettingsPillButtonStyle())
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.72))
                .padding(12)
                .background(InnerPanelBackground())
            }
        }
    }
}

private struct DropAreaSettings: View {
    @AppStorage("NotchDesk.dropAreaEnabled") private var dropAreaEnabled = true
    @AppStorage("NotchDesk.acceptFolders") private var acceptFolders = true
    @AppStorage("NotchDesk.dropAreaPreview") private var dropAreaPreview = true
    @AppStorage("NotchDesk.pipelineZip") private var pipelineZip = false
    @AppStorage("NotchDesk.pipelineCompress") private var pipelineCompress = false
    @AppStorage("NotchDesk.pipelineShareLink") private var pipelineShareLink = false

    var body: some View {
        VStack(spacing: 18) {
            SettingsSection(title: "Drop Area", subtitle: "File drop behavior and future pipeline-style actions.") {
                VStack(spacing: 10) {
                    ToggleRow(title: "Enable drop area", subtitle: "Show a larger target when dragging files near the notch.", isOn: $dropAreaEnabled)
                    ToggleRow(title: "Accept folders", subtitle: "Allow folders to be held in the tray.", isOn: $acceptFolders)
                    ToggleRow(title: "Preview dropped files", subtitle: "Show filename chips after dropping files.", isOn: $dropAreaPreview)
                }
            }

            SettingsSection(title: "Pipelines", subtitle: "Planned file actions inspired by NotchNook's roadmap.") {
                VStack(spacing: 10) {
                    ToggleRow(title: "Zip or unzip files", subtitle: "Create or extract archives after dropping files.", isOn: $pipelineZip)
                    ToggleRow(title: "Compress images", subtitle: "Reduce image file size from the drop area.", isOn: $pipelineCompress)
                    ToggleRow(title: "Create share link", subtitle: "Upload and copy a public link after drop.", isOn: $pipelineShareLink)
                }
            }
        }
    }
}

private struct LicenseSettings: View {
    @AppStorage("NotchDesk.licenseEmail") private var licenseEmail = ""
    @AppStorage("NotchDesk.licenseKey") private var licenseKey = ""
    @AppStorage("NotchDesk.updateChannel") private var updateChannel = "Stable"

    var body: some View {
        SettingsSection(title: "License", subtitle: "Purchase status, updates, and account details.") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    TextField("Email", text: $licenseEmail)
                    TextField("License key", text: $licenseKey)
                }
                .textFieldStyle(.roundedBorder)

                Picker("Update channel", selection: $updateChannel) {
                    Text("Stable").tag("Stable")
                    Text("Beta").tag("Beta")
                }
                .pickerStyle(.segmented)
                .frame(width: 220)

                HStack {
                    Label("Local development build", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Button("Check for updates") {}
                        .buttonStyle(SettingsPillButtonStyle())
                }
                .font(.system(size: 12, weight: .bold))
            }
        }
    }
}

private struct AboutSettings: View {
    var body: some View {
        SettingsSection(title: "About", subtitle: "NotchDesk build information.") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.black)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "platter.filled.top.iphone")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("NotchDesk")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)
                        Text("A NotchNook-inspired notch utility built with SwiftUI.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.52))
                    }
                    Spacer()
                }

                Divider().background(.white.opacity(0.12))

                InfoRow(title: "Build", value: "Local release")
                InfoRow(title: "Framework", value: "SwiftUI + AppKit")
                InfoRow(title: "Distribution", value: "Local .app")
            }
        }
    }
}

private struct NookPreviewCard: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $model.nookLayout) {
                ForEach(NookLayout.allCases) { layout in
                    Text(layout.title).tag(layout)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)

            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(model.theme.accent.opacity(0.9), lineWidth: 5)
                    )
                    .shadow(color: model.theme.accent.opacity(0.32), radius: 12, y: 5)

                HStack(spacing: 8) {
                    PreviewWidget(icon: "music.note", title: "Media Player")
                    PreviewWidget(icon: "calendar", title: "Calendar")
                    PreviewWidget(icon: "note.text", title: "Notes")
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 92)
        }
        .padding(14)
        .background(SettingsCardBackground())
    }
}

private struct PreviewWidget: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white.opacity(0.82))
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: 58)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.11))
        )
    }
}

private struct AppearanceSettings: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        SettingsSection(title: "Appearance", subtitle: "Theme and Nook content layout.") {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Theme")
                    HStack(spacing: 10) {
                        ForEach(NookTheme.allCases) { theme in
                            ThemeTile(theme: theme)
                        }
                    }
                }

                Divider()
                    .frame(height: 78)
                    .background(.white.opacity(0.10))

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Layout")
                    HStack(spacing: 8) {
                        ForEach(NookLayout.allCases) { layout in
                            LayoutButton(layout: layout)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }
}

private struct WidgetSettings: View {
    @AppStorage("NotchDesk.mediaWidgetEnabled") private var mediaWidgetEnabled = true
    @AppStorage("NotchDesk.calendarWidgetEnabled") private var calendarWidgetEnabled = true
    @AppStorage("NotchDesk.shortcutsWidgetEnabled") private var shortcutsWidgetEnabled = true
    @AppStorage("NotchDesk.mirrorWidgetEnabled") private var mirrorWidgetEnabled = true
    @AppStorage("NotchDesk.notesWidgetEnabled") private var notesWidgetEnabled = false
    @AppStorage("NotchDesk.nookAutoWidth") private var nookAutoWidth = true
    @AppStorage("NotchDesk.nookWidthCells") private var nookWidthCells = 5.0

    var body: some View {
        SettingsSection(title: "Customize widgets", subtitle: "Enable widgets and tune the Nook width.") {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    WidgetToggleTile(title: "Media", subtitle: "5 cells", icon: "music.note", isOn: $mediaWidgetEnabled)
                    WidgetToggleTile(title: "Calendar", subtitle: "4 cells", icon: "calendar", isOn: $calendarWidgetEnabled)
                    WidgetToggleTile(title: "Shortcuts", subtitle: "2 buttons", icon: "sparkles", isOn: $shortcutsWidgetEnabled)
                    WidgetToggleTile(title: "Mirror", subtitle: "Camera", icon: "camera.fill", isOn: $mirrorWidgetEnabled)
                    WidgetToggleTile(title: "Notes", subtitle: "Preview", icon: "note.text", isOn: $notesWidgetEnabled)
                }

                ToggleRow(title: "Auto width", subtitle: "Let the Nook adjust when widgets are added or removed.", isOn: $nookAutoWidth)
                SliderRow(title: "Manual width", value: $nookWidthCells, range: 3...8, valueText: "\(Int(nookWidthCells)) cells")
            }
        }
    }
}

private struct CalendarWidgetSettings: View {
    @AppStorage("NotchDesk.calendarPastEvents") private var calendarPastEvents = false
    @AppStorage("NotchDesk.daysBehind") private var daysBehind = 2.0
    @AppStorage("NotchDesk.daysAhead") private var daysAhead = 7.0
    @AppStorage("NotchDesk.homeCalendar") private var homeCalendar = true
    @AppStorage("NotchDesk.birthdaysCalendar") private var birthdaysCalendar = false
    @AppStorage("NotchDesk.holidaysCalendar") private var holidaysCalendar = true

    var body: some View {
        SettingsSection(title: "Calendar", subtitle: "Choose which events are visible in the Nook.") {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Calendars to show")
                    CheckRow(title: "Home", color: .blue, isOn: $homeCalendar)
                    CheckRow(title: "Birthdays", color: .purple, isOn: $birthdaysCalendar)
                    CheckRow(title: "US Holidays", color: .pink, isOn: $holidaysCalendar)
                }
                .frame(width: 230, alignment: .leading)

                Divider()
                    .frame(height: 130)
                    .background(.white.opacity(0.10))

                VStack(spacing: 12) {
                    ToggleRow(title: "Show today's past events", subtitle: "Keep earlier events visible for context.", isOn: $calendarPastEvents)
                    SliderRow(title: "Number of days behind", value: $daysBehind, range: 0...7, valueText: "\(Int(daysBehind))")
                    SliderRow(title: "Number of days ahead", value: $daysAhead, range: 1...14, valueText: "\(Int(daysAhead))")
                }
            }
        }
    }
}

private struct NookActionsSettings: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        SettingsSection(title: "Nook shortcuts", subtitle: "Choose the two buttons shown inside the Nook.") {
            HStack(spacing: 12) {
                ForEach(0..<2, id: \.self) { index in
                    NookActionPicker(index: index)
                }

                Spacer()

                Button {
                    model.refreshAvailableShortcutNames()
                } label: {
                    Label("Reload Shortcuts", systemImage: "arrow.clockwise")
                }
                .buttonStyle(SettingsPillButtonStyle())
            }
        }
    }
}

private struct ThemeTile: View {
    @EnvironmentObject private var model: NookModel
    let theme: NookTheme

    var body: some View {
        Button {
            model.theme = theme
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: theme.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(theme == .black ? 0.24 : 0.0), lineWidth: 1)
                        )

                    if model.theme == theme {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                    }
                }

                Text(theme.title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(model.theme == theme ? 0.95 : 0.58))
                    .lineLimit(1)
            }
            .frame(width: 68, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(model.theme == theme ? .white.opacity(0.14) : .black.opacity(0.20))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(model.theme == theme ? theme.accent.opacity(0.85) : .clear, lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct LayoutButton: View {
    @EnvironmentObject private var model: NookModel
    let layout: NookLayout

    var body: some View {
        Button {
            model.nookLayout = layout
        } label: {
            HStack(spacing: 8) {
                Image(systemName: layout.systemImage)
                Text(layout.title)
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(model.nookLayout == layout ? .white : .white.opacity(0.70))
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(
                Capsule()
                    .fill(model.nookLayout == layout ? .blue.opacity(0.75) : .black.opacity(0.20))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct NookActionPicker: View {
    @EnvironmentObject private var model: NookModel
    let index: Int

    var body: some View {
        let action = model.nookActions.indices.contains(index)
            ? model.nookActions[index]
            : NookActionConfig.defaults[index]

        Menu {
            Section("Built in") {
                ForEach(NookActionConfig.builtInOptions) { option in
                    Button(option.title) {
                        model.setNookAction(option, at: index)
                    }
                }
            }

            if model.customShortcutItems.isEmpty == false || model.availableShortcutNames.isEmpty == false {
                Section("Shortcuts") {
                    ForEach(model.customShortcutItems) { item in
                        Button(item.title) {
                            model.setNookAction(model.customShortcutNookAction(named: item.shortcutName), at: index)
                        }
                    }
                    ForEach(model.availableShortcutNames.filter({ name in
                        model.customShortcutItems.contains(where: { $0.shortcutName == name }) == false
                    }), id: \.self) { name in
                        Button(name) {
                            model.setNookAction(model.customShortcutNookAction(named: name), at: index)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: action.symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(action.tint)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Slot \(index + 1)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                    Text(action.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 14)
            .frame(width: 220, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.10))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct WidgetToggleTile: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Toggle("", isOn: $isOn)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .scaleEffect(0.62)
                        .frame(width: 34)
                }
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.48))
            }
            .foregroundStyle(.white)
            .padding(10)
            .frame(width: 116, height: 84, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isOn ? .blue.opacity(0.34) : .black.opacity(0.18))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.48))
            }

            content
        }
        .padding(14)
        .background(SettingsCardBackground())
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(2)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(12)
        .background(InnerPanelBackground())
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let valueText: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.80))
                .frame(width: 170, alignment: .leading)
            Slider(value: $value, in: range)
            Text(valueText)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.62))
                .frame(width: 58, alignment: .trailing)
        }
        .padding(12)
        .background(InnerPanelBackground())
    }
}

private struct CheckRow: View {
    let title: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isOn ? color : .white.opacity(0.16))
                    .frame(width: 14, height: 14)
                    .overlay {
                        if isOn {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(.white)
                        }
                    }
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .buttonStyle(.plain)
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.white.opacity(0.52))
            Spacer()
            Text(value)
                .foregroundStyle(.white.opacity(0.86))
        }
        .font(.system(size: 12, weight: .bold))
    }
}

private struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white.opacity(0.48))
    }
}

private struct SettingsCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(red: 0.20, green: 0.21, blue: 0.25))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct InnerPanelBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(.black.opacity(0.16))
    }
}

private struct SettingsPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.62 : 0.92))
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(
                Capsule()
                    .fill(.white.opacity(configuration.isPressed ? 0.08 : 0.12))
            )
    }
}
