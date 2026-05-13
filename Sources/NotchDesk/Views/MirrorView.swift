import AVFoundation
import SwiftUI

struct MirrorView: View {
    @EnvironmentObject private var model: NookModel

    var body: some View {
        HStack(spacing: 16) {
            CameraPreview(session: model.cameraController.session)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
                .frame(width: 392, height: 292)

            VStack(alignment: .leading, spacing: 16) {
                Text("Mirror")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text(model.cameraController.authorizationLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(3)

                VStack(spacing: 10) {
                    Button {
                        model.cameraController.start()
                    } label: {
                        Label("Start camera", systemImage: "camera.fill")
                    }
                    Button {
                        model.cameraController.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                }
                .buttonStyle(PrimaryTextButtonStyle())

                Spacer()

                HStack(spacing: 10) {
                    Image(systemName: "video.badge.checkmark")
                    Text("Preview stays local and uses AVFoundation.")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.42))
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(WidgetBackground())
        }
        .frame(width: 640, height: 292)
        .onAppear {
            model.cameraController.start()
        }
        .onDisappear {
            model.cameraController.stop()
        }
    }
}

struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateNSView(_ nsView: PreviewView, context: Context) {
        nsView.previewLayer.session = session
    }

    final class PreviewView: NSView {
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func makeBackingLayer() -> CALayer {
            AVCaptureVideoPreviewLayer()
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as? AVCaptureVideoPreviewLayer ?? AVCaptureVideoPreviewLayer()
        }
    }
}
