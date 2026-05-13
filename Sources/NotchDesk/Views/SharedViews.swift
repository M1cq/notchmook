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
            VStack(spacing: compact ? 5 : 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: compact ? 17 : 26, weight: .semibold))
                Text("AirDrop")
                    .font(.system(size: compact ? 10 : 14, weight: .bold))
                if compact == false {
                    Text("Drop files to send")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.46))
                }
            }
            .foregroundStyle(isTargeted ? .black : .white.opacity(0.78))
            .frame(width: width, height: height)
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
            .fill(isTargeted ? .white.opacity(0.90) : .black.opacity(0.22))
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 18 : 20, style: .continuous)
                    .stroke(
                        isTargeted ? .white.opacity(0.95) : .white.opacity(0.18),
                        style: StrokeStyle(lineWidth: 1.2, dash: isTargeted ? [] : [6, 6])
                    )
            )
    }
}

struct FileChip: View {
    let item: TrayItem

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(item.isDirectory ? .yellow : .white.opacity(0.78))
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
