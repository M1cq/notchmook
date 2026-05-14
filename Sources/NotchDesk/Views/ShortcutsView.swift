import AppKit
import SwiftUI

struct ShortcutsView: View {
    @EnvironmentObject private var model: NookModel
    @State private var manualShortcutName = ""

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Actions")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Pin Shortcuts app actions and common Mac utilities.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.52))
                }

                Spacer()
                shortcutAddMenu
            }

            customShortcutEditor

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(model.shortcuts) { shortcut in
                        Button {
                            shortcut.action()
                        } label: {
                            ShortcutTile(shortcut: shortcut)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(width: 640, height: 292)
        .onAppear {
            model.refreshAvailableShortcutNames()
        }
    }

    private var shortcutAddMenu: some View {
        HStack(spacing: 8) {
            Button {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Shortcuts.app"))
            } label: {
                Image(systemName: "square.grid.2x2")
            }
            .help("Open Shortcuts")

            Button {
                model.refreshAvailableShortcutNames()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Reload shortcuts")

            Menu {
                if model.availableShortcutNames.isEmpty {
                    Button("Open Shortcuts app") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Shortcuts.app"))
                    }
                } else {
                    ForEach(model.availableShortcutNames, id: \.self) { name in
                        Button(name) {
                            model.addShortcut(named: name)
                        }
                        .disabled(model.customShortcutItems.contains(where: { $0.shortcutName == name }))
                    }
                }
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        .font(.system(size: 12, weight: .bold))
        .buttonStyle(ShortcutToolbarButtonStyle())
    }

    @ViewBuilder
    private var customShortcutEditor: some View {
        if model.customShortcutItems.isEmpty {
            HStack(spacing: 8) {
                TextField("Shortcut name", text: $manualShortcutName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(width: 190, height: 28)
                    .background(Capsule().fill(.black.opacity(0.28)))

                Button {
                    model.addShortcut(named: manualShortcutName)
                    manualShortcutName = ""
                } label: {
                    Label("Pin Shortcut", systemImage: "pin.fill")
                }
                .buttonStyle(ShortcutToolbarButtonStyle())
            }
        } else {
            HStack(spacing: 8) {
                ForEach(model.customShortcutItems.prefix(4)) { item in
                    HStack(spacing: 6) {
                        Image(systemName: item.symbol)
                            .foregroundStyle(item.tint)
                        Text(item.title)
                            .lineLimit(1)
                        Button {
                            model.removeCustomShortcut(item)
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.48))
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(Capsule().fill(.black.opacity(0.28)))
                }

                TextField("Shortcut name", text: $manualShortcutName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(width: 160, height: 28)
                    .background(Capsule().fill(.black.opacity(0.20)))

                Button {
                    model.addShortcut(named: manualShortcutName)
                    manualShortcutName = ""
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(ShortcutToolbarButtonStyle())
            }
        }
    }
}

private struct ShortcutTile: View {
    let shortcut: NookShortcut

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: shortcut.symbol)
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(shortcut.tint)
                .frame(width: 42, height: 42)
                .background(Circle().fill(shortcut.tint.opacity(0.16)))

            VStack(alignment: .leading, spacing: 3) {
                Text(shortcut.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(shortcut.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.50))
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .background(WidgetBackground(cornerRadius: 20))
    }
}

private struct ShortcutToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(Capsule().fill(.black.opacity(configuration.isPressed ? 0.46 : 0.28)))
    }
}
