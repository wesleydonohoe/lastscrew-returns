import AVFoundation
import UIKit

@MainActor
final class CameraController: NSObject, ObservableObject {
    @Published private(set) var isReady = false
    @Published private(set) var capturedImage: UIImage?
    @Published private(set) var setupError: String?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "lastscrew.camera.session")
    private var continuation: CheckedContinuation<UIImage, Error>?

    func startIfNeeded() {
        guard !isReady, setupError == nil else { return }
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func capture() async throws -> UIImage {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<UIImage, Error>) in
            self.continuation = cont
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            sessionQueue.async { [weak self] in
                guard let self else { return }
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    private func configureSession() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }
            Task { @MainActor in
                if !granted {
                    self.setupError = "Camera access denied. Enable it in Settings to verify packaging."
                    return
                }
                self.sessionQueue.async {
                    self.session.beginConfiguration()
                    self.session.sessionPreset = .photo
                    guard
                        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ??
                            AVCaptureDevice.default(for: .video),
                        let input = try? AVCaptureDeviceInput(device: device),
                        self.session.canAddInput(input),
                        self.session.canAddOutput(self.photoOutput)
                    else {
                        DispatchQueue.main.async {
                            self.setupError = "No camera available. Use a real device to capture packaging photos."
                        }
                        return
                    }
                    self.session.addInput(input)
                    self.session.addOutput(self.photoOutput)
                    self.session.commitConfiguration()
                    self.session.startRunning()
                    DispatchQueue.main.async {
                        self.isReady = true
                    }
                }
            }
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        Task { @MainActor in
            if let error {
                self.continuation?.resume(throwing: error)
                self.continuation = nil
                return
            }
            guard let data = photo.fileDataRepresentation(), let img = UIImage(data: data) else {
                self.continuation?.resume(throwing: NSError(domain: "Lastscrew", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not decode photo data"]))
                self.continuation = nil
                return
            }
            self.capturedImage = img
            self.continuation?.resume(returning: img)
            self.continuation = nil
        }
    }
}
