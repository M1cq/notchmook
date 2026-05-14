import SwiftUI

struct SettingsPane: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Panel Tuning")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Public APIs only: no private notch control, no copied assets.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.52))
            }

            VStack(spacing: 12) {
                NookActionsSettings()
                ToggleRow(
                    title: "Open on hover",
                    subtitle: "The panel expands when the pointer reaches the notch area.",
                    isOn: $model.autoExpandOnHover
                )
                ToggleRow(
                    title: "Pinned panel",
                    subtitle: "Keep the panel open until you close it.",
                    isOn: $model.isPinned
                )
                ToggleRow(
                    title: "Notchless handler",
                    subtitle: "Use a visible top handle on Macs without a physical notch.",
                    isOn: $model.notchlessHandler
                )
            }

            HStack(spacing: 10) {
                Button {
                    model.calendarProvider.requestAndLoad()
                } label: {
                    Label("Calendar Access", systemImage: "calendar.badge.checkmark")
                }
                Button {
                    model.cameraController.start()
                } label: {
                    Label("Camera Access", systemImage: "camera.fill")
                }
                Button {
                    model.mediaController.refresh()
                } label: {
                    Label("Refresh Media", systemImage: "waveform")
                }
            }
            .buttonStyle(PrimaryTextButtonStyle())

            Spacer()
            }
        }
        .padding(.vertical, 2)
        .frame(width: 640, height: 292, alignment: .topLeading)
    }
}

private struct NookActionsSettings: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Nook Shortcuts")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Choose the two buttons shown inside the Nook.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.52))
                }
                Spacer()
                Button {
                    model.refreshAvailableShortcutNames()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.7))
            }

            HStack(spacing: 10) {
                ForEach(0..<2, id: \.self) { index in
                    NookActionPicker(index: index)
                }
            }
        }
        .padding(14)
        .background(WidgetBackground(cornerRadius: 18))
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
            HStack(spacing: 8) {
                Image(systemName: action.symbol)
                    .foregroundStyle(action.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Slot \(index + 1)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.46))
                    Text(action.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.42))
            }
            .padding(.horizontal, 10)
            .frame(width: 174, height: 42)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.black.opacity(0.26)))
        }
        .buttonStyle(.plain)
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.52))
                    .lineLimit(2)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(14)
        .background(WidgetBackground(cornerRadius: 18))
    }
}
