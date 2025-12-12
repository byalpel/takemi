import SwiftUI

struct GalleryView: View {
    @ObservedObject var photoManager = PhotoManager.shared
    @StateObject private var videoGenerator = VideoGenerator()
    @State private var selectedPhoto: Photo?
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        VStack {
            if photoManager.photos.isEmpty {
                Text("No photos yet.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(photoManager.photos) { photo in
                            if let image = NSImage(contentsOf: photo.url) {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selectedPhoto = photo
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            photoManager.deletePhoto(photo)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            Divider()
            
            HStack {
                Button("Generate Video") {
                    generateVideo()
                }
                .disabled(videoGenerator.isGenerating || photoManager.photos.count < 2)
                
                if videoGenerator.isGenerating {
                    ProgressView(value: videoGenerator.progress)
                        .frame(width: 100)
                }
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 500)
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
        }
        .alert(isPresented: .constant(videoGenerator.errorMessage != nil)) {
            Alert(title: Text("Error"), message: Text(videoGenerator.errorMessage ?? ""), dismissButton: .default(Text("OK")) {
                videoGenerator.errorMessage = nil
            })
        }
    }
    
    func generateVideo() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.nameFieldStringValue = "TakeMi_Timelapse.mp4"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                videoGenerator.generateVideo(from: photoManager.photos, to: url) { success in
                    if success {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}

struct PhotoDetailView: View {
    let photo: Photo
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            if let image = NSImage(contentsOf: photo.url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            
            Text(photo.date.formatted())
                .padding()
            
            Button("Close") {
                dismiss()
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 600)
    }
}
