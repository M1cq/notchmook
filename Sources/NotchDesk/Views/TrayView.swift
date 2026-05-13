import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct TrayView: View {
    @EnvironmentObject private var model: NookModel

    private let columns = [
        GridItem(.adaptive(minimum: 96, maximum: 116), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Temporary Tray")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Drop files into the notch, then drag them out when needed.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.52))
                }
                Spacer()
                Button {
                    AirDropService.share(model.trayItems.map(\.url))
                } label: {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                }
                .buttonStyle(ChromeIconButtonStyle())
                .help("AirDrop tray files")
                Button {
                    model.clearTray()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(ChromeIconButtonStyle())
                .help("Clear tray")
            }

            if model.trayItems.isEmpty {
                HStack(spacing: 14) {
                    DropHint()
                    AirDropDropZone(width: 180, height: 180, compact: false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .top, spacing: 14) {
                    AirDropDropZone(width: 118, height: 124, compact: false)
                    ScrollView {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                            ForEach(model.trayItems) { item in
                                TrayItemCard(item: item)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .frame(width: 640, height: 292)
    }
}

private struct TrayItemCard: View {
    @EnvironmentObject private var model: NookModel
    let item: TrayItem

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.08))
                    .frame(height: 70)
                Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(item.isDirectory ? .yellow : .white.opacity(0.86))
            }
            Text(item.displayName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 30)
        }
        .padding(8)
        .frame(width: 106, height: 124)
        .background(WidgetBackground(cornerRadius: 18))
        .onDrag {
            NSItemProvider(contentsOf: item.url) ?? NSItemProvider(object: item.url.path as NSString)
        }
        .contextMenu {
            Button("Open") {
                NSWorkspace.shared.open(item.url)
            }
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
            Divider()
            Button("Remove") {
                model.remove(item)
            }
        }
    }
}
