import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        HStack(spacing: 14) {
            MediaWidgetView(controller: model.mediaController)
                .frame(width: 322)
            VStack(spacing: 14) {
                CalendarWidgetView(provider: model.calendarProvider)
                TraySummaryView()
            }
            .frame(width: 316)
        }
        .frame(height: 292)
        .onAppear {
            model.mediaController.refresh()
            model.calendarProvider.reload()
        }
    }
}

struct MediaWidgetView: View {
    @ObservedObject var controller: MediaController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 13) {
                AlbumArtView(snapshot: controller.snapshot)
                    .frame(width: 94, height: 94)
                VStack(alignment: .leading, spacing: 7) {
                    Text(controller.snapshot.appName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.52))
                    Text(controller.snapshot.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(controller.snapshot.artist)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                }
            }

            HStack(spacing: 16) {
                Button {
                    controller.previousTrack()
                } label: {
                    Image(systemName: "backward.fill")
                }
                Button {
                    controller.togglePlayPause()
                } label: {
                    Image(systemName: controller.snapshot.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(width: 46, height: 46)
                .background(Circle().fill(.white))
                .foregroundStyle(.black)

                Button {
                    controller.nextTrack()
                } label: {
                    Image(systemName: "forward.fill")
                }

                Spacer()
            }
            .buttonStyle(MediaButtonStyle())

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                    Slider(
                        value: Binding(
                            get: { Double(controller.snapshot.outputVolume) },
                            set: { controller.setVolume($0) }
                        ),
                        in: 0...100
                    )
                }
                EqualizerBars(isActive: controller.snapshot.isPlaying)
                    .frame(height: 44)
            }
            .foregroundStyle(.white.opacity(0.8))

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxHeight: .infinity)
        .background(WidgetBackground())
        .onAppear {
            controller.refresh()
        }
    }
}

private struct AlbumArtView: View {
    let snapshot: MediaSnapshot

    var body: some View {
        MediaArtworkView(artworkURL: snapshot.artworkURL, cornerRadius: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.30, green: 0.75, blue: 0.86),
                                Color(red: 0.98, green: 0.41, blue: 0.47),
                                Color(red: 0.98, green: 0.82, blue: 0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Circle()
                    .fill(.black.opacity(0.28))
                    .frame(width: 42, height: 42)
                Image(systemName: snapshot.isPlaying ? "waveform" : "music.note")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct EqualizerBars: View {
    let isActive: Bool
    private let values: [Double] = [0.34, 0.78, 0.48, 0.92, 0.56, 0.70, 0.42, 0.86, 0.62, 0.38, 0.74, 0.50]

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.16)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    let motion = isActive ? (sin(phase * 3.5 + Double(index)) + 1) * 0.22 : 0
                    Capsule()
                        .fill(.white.opacity(0.20 + value * 0.42))
                        .frame(width: 8, height: 10 + (value + motion) * 32)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct CalendarWidgetView: View {
    @ObservedObject var provider: CalendarProvider

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Calendar", systemImage: "calendar")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Button {
                    provider.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(ChromeIconButtonStyle())
                .help("Reload events")
            }
            .foregroundStyle(.white)

            if provider.entries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(provider.authorizationLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.62))
                    Button("Enable Calendar") {
                        provider.requestAndLoad()
                    }
                    .buttonStyle(PrimaryTextButtonStyle())
                }
                Spacer(minLength: 0)
            } else {
                VStack(spacing: 8) {
                    ForEach(provider.entries.prefix(3)) { entry in
                        CalendarRow(entry: entry)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WidgetBackground())
        .onAppear {
            provider.reload()
        }
    }
}

private struct CalendarRow: View {
    let entry: CalendarEntry

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 4)
                .fill(entry.calendarColor)
                .frame(width: 5, height: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(timeText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer(minLength: 0)
        }
    }

    private var timeText: String {
        if entry.isAllDay {
            return "All day"
        }
        return entry.startDate.formatted(date: .abbreviated, time: .shortened)
    }
}

private struct TraySummaryView: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tray", systemImage: "tray.full")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                CountBadge(count: model.trayItems.count)
            }

            if model.trayItems.isEmpty {
                DropHint()
            } else {
                HStack(spacing: 8) {
                    ForEach(model.trayItems.prefix(4)) { item in
                        FileChip(item: item)
                    }
                    if model.trayItems.count > 4 {
                        Text("+\(model.trayItems.count - 4)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                Button {
                    model.expand(tab: .tray)
                } label: {
                    Label("Open tray", systemImage: "arrow.right")
                }
                .buttonStyle(PrimaryTextButtonStyle())
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WidgetBackground())
    }
}
