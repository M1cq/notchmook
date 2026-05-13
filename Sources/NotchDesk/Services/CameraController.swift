import AVFoundation
import Combine
import Foundation

final class CameraController: ObservableObject {
    @Published private(set) var authorizationLabel = "Camera access not requested"
    let session = AVCaptureSession()

    private var isConfigured = false

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureIfNeeded()
            DispatchQueue.global(qos: .userInitiated).async {
                if self.session.isRunning == false {
                    self.session.startRunning()
                }
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationLabel = granted ? "Camera access granted" : "Camera access denied"
                    if granted {
                        self?.start()
                    }
                }
            }
        case .denied, .restricted:
            authorizationLabel = "Camera access is disabled"
        @unknown default:
            authorizationLabel = "Camera unavailable"
        }
    }

    func stop() {
        DispatchQueue.global(qos: .utility).async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func configureIfNeeded() {
        guard isConfigured == false else { return }

        session.beginConfiguration()
        session.sessionPreset = .medium

        defer {
            session.commitConfiguration()
        }

        guard let camera = AVCaptureDevice.default(for: .video) else {
            authorizationLabel = "No camera found"
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            authorizationLabel = "Mirror ready"
            isConfigured = true
        } catch {
            authorizationLabel = error.localizedDescription
        }
    }
}
