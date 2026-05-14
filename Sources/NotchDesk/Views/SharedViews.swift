import AppKit
import QuickLookThumbnailing
import SwiftUI
import UniformTypeIdentifiers

struct WidgetBackground: View {
    var cornerRadius: CGFloat = 22

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.white.opacity(0.075))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
    }
}

struct ChromeIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.52 : 0.88))
            .frame(width: 30, height: 30)
            .background(
                Circle()
                    .fill(.white.opacity(configuration.isPressed ? 0.14 : 0.08))
            )
    }
}

struct MediaButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.5 : 0.82))
            .frame(width: 34, height: 34)
            .background(
                Circle()
                    .fill(.white.opacity(configuration.isPressed ? 0.14 : 0.08))
            )
    }
}

struct PrimaryTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(configuration.isPressed ? .black.opacity(0.62) : .black)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(
                Capsule()
                    .fill(.white.opacity(configuration.isPressed ? 0.72 : 0.92))
            )
    }
}

struct CountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.black)
            .frame(minWidth: 20, minHeight: 20)
            .background(Capsule().fill(.white))
    }
}

struct DropHint: View {
    var body: some View {
        VStack(spacing: 11) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white.opacity(0.62))
            Text("Drop files here")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.82))
            Text("Files are held in memory and clear when the app quits.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [6, 6]))
                .foregroundStyle(.white.opacity(0.16))
        )
    }
}

struct AirDropDropZone: View {
    @EnvironmentObject private var model: NookModel
    @State private var isTargeted = false

    var width: CGFloat = 154
    var height: CGFloat = 56
    var compact = true

    var body: some View {
        Button {
            AirDropService.share(model.trayItems.map(\.url))
        } label: {
            HStack(spacing: compact ? 6 : 12) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: compact ? 17 : 26, weight: .semibold))
                    .foregroundStyle(isTargeted ? .black : Color.blue.opacity(compact ? 0.85 : 0.95))
                    .frame(width: compact ? 20 : 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text("AirDrop")
                        .font(.system(size: compact ? 10 : 13, weight: .bold))
                    if compact == false {
                        Text("Drop files to send")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(isTargeted ? .black.opacity(0.54) : .white.opacity(0.46))
                    }
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(isTargeted ? .black : .white.opacity(0.78))
            .padding(.horizontal, compact ? 0 : 16)
            .frame(width: width > 0 ? width : nil, height: height)
            .frame(maxWidth: width > 0 ? nil : .infinity)
            .background(background)
        }
        .buttonStyle(.plain)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            AirDropService.shareFileProviders(providers)
        }
        .help("Drop files to AirDrop, or click to AirDrop current tray files")
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: compact ? 18 : 20, style: .continuous)
            .fill(
                isTargeted
                    ? .white.opacity(0.90)
                    : (compact ? .black.opacity(0.22) : Color(red: 0.02, green: 0.12, blue: 0.25).opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 18 : 20, style: .continuous)
                    .stroke(
                        isTargeted ? .white.opacity(0.95) : (compact ? .white.opacity(0.18) : Color.blue.opacity(0.18)),
                        style: StrokeStyle(lineWidth: compact ? 1.2 : 1.0, dash: compact && isTargeted == false ? [6, 6] : [])
                    )
            )
    }
}

struct FileChip: View {
    let item: TrayItem

    var body: some View {
        VStack(spacing: 5) {
            FileThumbnail(url: item.url, isDirectory: item.isDirectory)
                .frame(width: 42, height: 34)
            Text(item.displayName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
                .frame(width: 48)
        }
        .frame(width: 58, height: 58)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.07))
        )
    }
}

private struct FileThumbnail: View {
    let url: URL
    let isDirectory: Bool
    @State private var image: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.black.opacity(0.20))

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 42, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            } else {
                Image(systemName: isDirectory ? "folder.fill" : "doc.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(isDirectory ? .yellow : .white.opacity(0.78))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.8)
        )
        .task(id: url) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard isDirectory == false else { return }

        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: 84, height: 68),
            scale: NSScreen.main?.backingScaleFactor ?? 2,
            representationTypes: .thumbnail
        )

        do {
            let representation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            await MainActor.run {
                image = representation.nsImage
            }
        } catch {
            await MainActor.run {
                image = NSWorkspace.shared.icon(forFile: url.path)
            }
        }
    }
}
