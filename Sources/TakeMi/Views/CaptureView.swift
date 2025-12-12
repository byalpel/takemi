import SwiftUI

struct CaptureView: View {
    @StateObject private var cameraService = CameraService()
    @ObservedObject var photoManager = PhotoManager.shared
    @State private var capturedData: Data?
    @State private var ghostOpacity: Double = 0.3
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            ZStack {
                // Live Camera Feed
                if let frame = cameraService.currentFrame {
                    Image(decorative: frame, scale: 1.0, orientation: .up)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped() // Ensure it stays within bounds
                        .scaleEffect(x: -1, y: 1) // Mirror front camera
                } else {
                    Color.black
                    if !cameraService.isPermissionGranted {
                        Text("Camera access required")
                            .foregroundColor(.white)
                    }
                }
                
                // Ghost Overlay
                if capturedData == nil, let lastPhoto = photoManager.lastPhoto, let nsImage = NSImage(contentsOf: lastPhoto.url) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .opacity(ghostOpacity)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .allowsHitTesting(false)
                }
                
                // Captured Image Review
                if let data = capturedData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Controls
            HStack {
                if capturedData != nil {
                    Button("Retake") {
                        capturedData = nil
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button("Save & Close") {
                        if let data = capturedData {
                            _ = photoManager.savePhoto(data: data)
                            dismiss()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    
                } else {
                    VStack {
                        Slider(value: $ghostOpacity, in: 0...1) {
                            Text("Ghost")
                        }
                        .frame(width: 100)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        cameraService.capturePhoto { data in
                            self.capturedData = data
                        }
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    }
                    
                    Spacer()
                    
                    // Spacer to balance the slider
                    Spacer().frame(width: 100) 
                }
            }
            .padding()
            .background(Material.regular)
        }
        .onAppear {
            cameraService.start()
        }
        .onDisappear {
            cameraService.stop()
        }
    }
}
