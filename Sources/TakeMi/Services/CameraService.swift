import AVFoundation
import AppKit
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var currentFrame: CGImage?
    @Published var isPermissionGranted = false
    
    private var captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera_session_queue")
    
    override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isPermissionGranted = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isPermissionGranted = granted
                    if granted {
                        self?.setupSession()
                    }
                }
            }
        default:
            isPermissionGranted = false
        }
    }
    
    private func setupSession() {
        sessionQueue.async {
            self.captureSession.beginConfiguration()
            
            // Input
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ?? AVCaptureDevice.default(for: .video) else {
                print("No camera found")
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }
            } catch {
                print("Error setting up input: \(error)")
                return
            }
            
            // Video Output for Preview
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
                self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video_output_queue"))
            }
            
            // Photo Output
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
            }
            
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }
    
    func start() {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stop() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func capturePhoto(completion: @escaping (Data?) -> Void) {
        let settings = AVCapturePhotoSettings()
        let delegate = PhotoCaptureDelegate(completion: completion)
        // Retain delegate? The output captures it, but we need to ensure it lives long enough.
        // For simplicity in this scope, we can rely on the photo output holding the request. 
        // Actually, we need to store the delegate reference or use a block-based wrapper.
        // We will create a simple wrapper in this class.
        self.photoCaptureDelegate = delegate 
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
    
    private var photoCaptureDelegate: PhotoCaptureDelegate?
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        // Ensure orientation is correct for macOS (usually fine, but sometimes mirrored)
        // Front camera might be mirrored.
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            DispatchQueue.main.async {
                self.currentFrame = cgImage
            }
        }
    }
}

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (Data?) -> Void
    
    init(completion: @escaping (Data?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            completion(nil)
            return
        }
        
        guard let data = photo.fileDataRepresentation(),
              let nsImage = NSImage(data: data) else {
            completion(nil)
            return
        }
        
        // Flip image
        let flippedImage = NSImage(size: nsImage.size)
        flippedImage.lockFocus()
        
        let transform = NSAffineTransform()
        transform.translateX(by: nsImage.size.width, yBy: 0)
        transform.scaleX(by: -1, yBy: 1)
        transform.concat()
        
        nsImage.draw(at: .zero, from: NSRect(origin: .zero, size: nsImage.size), operation: .copy, fraction: 1.0)
        
        flippedImage.unlockFocus()
        
        // Convert back to Data
        if let tiffData = flippedImage.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let jpegData = bitmap.representation(using: .jpeg, properties: [:]) {
            completion(jpegData)
        } else {
            completion(data) // Fallback to original
        }
    }
}
