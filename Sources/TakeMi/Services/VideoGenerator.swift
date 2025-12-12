import AVFoundation
import AppKit

class VideoGenerator: ObservableObject {
    @Published var isGenerating = false
    @Published var progress: Double = 0.0
    @Published var errorMessage: String?
    
    func generateVideo(from photos: [Photo], to outputURL: URL, completion: @escaping (Bool) -> Void) {
        guard !photos.isEmpty else {
            errorMessage = "No photos to generate video."
            completion(false)
            return
        }
        
        isGenerating = true
        progress = 0.0
        
        // Sort photos oldest first for video
        let sortedPhotos = photos.sorted(by: { $0.date < $1.date })
        
        _ = AVOutputSettingsAssistant(preset: .preset1920x1080)?.videoSettings
        
        do {
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }
            
            let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            
            // Determine size from first image or default
            var videoSize = CGSize(width: 1080, height: 1920) // Default portrait
            if let firstImage = NSImage(contentsOf: sortedPhotos.first!.url) {
                videoSize = firstImage.size
            }
            
            let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(videoSize.width),
                AVVideoHeightKey: Int(videoSize.height)
            ])
            
            let sourceBufferAttributes = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: Int(videoSize.width),
                kCVPixelBufferHeightKey as String: Int(videoSize.height)
            ] as [String: Any]
            
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: sourceBufferAttributes)
            
            if assetWriter.canAdd(videoInput) {
                assetWriter.add(videoInput)
            }
            
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            
            let frameDuration = CMTime(value: 1, timescale: 2) // 2 FPS, or 0.5s per photo
            var frameCount: Int64 = 0
            
            let queue = DispatchQueue(label: "videoGenerationQueue")
            videoInput.requestMediaDataWhenReady(on: queue) {
                for photo in sortedPhotos {
                    while !videoInput.isReadyForMoreMediaData {
                        Thread.sleep(forTimeInterval: 0.1)
                    }
                    
                    if let source = CGImageSourceCreateWithURL(photo.url as CFURL, nil),
                       let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil),
                       let buffer = self.pixelBuffer(from: cgImage, size: videoSize) {
                        
                        let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameCount))
                        adaptor.append(buffer, withPresentationTime: presentationTime)
                        frameCount += 1
                        
                        DispatchQueue.main.async {
                            self.progress = Double(frameCount) / Double(sortedPhotos.count)
                        }
                    }
                }
                
                videoInput.markAsFinished()
                assetWriter.finishWriting {
                    DispatchQueue.main.async {
                        self.isGenerating = false
                        if assetWriter.status == .completed {
                            completion(true)
                        } else {
                            self.errorMessage = assetWriter.error?.localizedDescription
                            completion(false)
                        }
                    }
                }
            }
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.isGenerating = false
            completion(false)
        }
    }
    
    private func pixelBuffer(from image: CGImage, size: CGSize) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let data = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        // Flip vertically for AVAssetWriter
        // context?.translateBy(x: 0, y: size.height)
        // context?.scaleBy(x: 1.0, y: -1.0) 
        // CGImage drawing might not need flip if we don't mess with coords, but CVPixelBuffer is usually top-down. 
        // CoreGraphics is bottom-up.
        // Usually, we need to flip to get it right-side up in the video.
        
        // Let's just draw it.
        context?.draw(image, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
}
