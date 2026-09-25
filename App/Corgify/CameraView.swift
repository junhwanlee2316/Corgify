#if os(iOS)
import AVFoundation
import CorgifyCore
import SwiftUI

/// Live camera preview backed by `AVCaptureSession`.
///
/// Kept deliberately small: it captures a still image and hands the `CGImage`
/// to `CorgifyViewModel`. All the interesting logic lives in CorgifyCore.
@available(iOS 18.4, *)
struct CameraView: UIViewControllerRepresentable {

    let onCapture: (CGImage) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onCapture = onCapture
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

@available(iOS 18.4, *)
final class CameraViewController: UIViewController {

    var onCapture: ((CGImage) -> Void)?

    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .front
            ),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input),
            session.canAddOutput(output)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        session.addOutput(output)
        session.commitConfiguration()

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        previewLayer = layer

        Task.detached { [session] in
            session.startRunning()
        }
    }

    /// Captures a still photo. Call from the shutter button.
    func capture() {
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
}

@available(iOS 18.4, *)
extension CameraViewController: AVCapturePhotoCaptureDelegate {

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil, let cgImage = photo.cgImageRepresentation() else { return }
        onCapture?(cgImage)
    }
}
#endif
