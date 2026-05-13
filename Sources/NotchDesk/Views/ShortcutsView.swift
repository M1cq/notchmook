import SwiftUI

struct ShortcutsView: View {
    @EnvironmentObject private var model: NookModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Actions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Open common Mac utilities or act on the current tray.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.52))
            }

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
            Spacer(minLength: 0)
        }
        .frame(width: 640, height: 292)
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
