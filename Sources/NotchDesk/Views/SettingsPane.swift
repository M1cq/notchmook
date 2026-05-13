import SwiftUI

struct SettingsPane: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
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
        .padding(.vertical, 2)
        .frame(width: 640, height: 292, alignment: .topLeading)
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
