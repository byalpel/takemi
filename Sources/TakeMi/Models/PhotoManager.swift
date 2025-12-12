import Foundation

struct Photo: Identifiable, Hashable {
    let id: UUID = UUID()
    let url: URL
    let date: Date
}

class PhotoManager: ObservableObject {
    static let shared = PhotoManager()
    @Published var photos: [Photo] = []
    
    private var settings = SettingsManager.shared
    
    init() {
        loadPhotos()
    }
    
    func loadPhotos() {
        let directory = settings.storageURL
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
            
            let photoFiles = fileURLs.filter { url in
                let ext = url.pathExtension.lowercased()
                return ["jpg", "jpeg", "png", "heic"].contains(ext)
            }
            
            self.photos = photoFiles.compactMap { url -> Photo? in
                // Try to get date from filename first (YYYY-MM-DD_HH-mm-ss)
                let filename = url.deletingPathExtension().lastPathComponent
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                if let date = formatter.date(from: filename) {
                    return Photo(url: url, date: date)
                }
                // Fallback to creation date
                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let date = attributes[.creationDate] as? Date {
                    return Photo(url: url, date: date)
                }
                return nil
            }.sorted(by: { $0.date > $1.date }) // Newest first
            
        } catch {
            print("Error loading photos: \(error)")
            self.photos = []
        }
    }
    
    func savePhoto(data: Data) -> Bool {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = formatter.string(from: date) + ".jpg"
        let url = settings.storageURL.appendingPathComponent(filename)
        
        do {
            try data.write(to: url)
            loadPhotos() // Refresh list
            return true
        } catch {
            print("Error saving photo: \(error)")
            return false
        }
    }
    
    func deletePhoto(_ photo: Photo) {
        do {
            try FileManager.default.removeItem(at: photo.url)
            loadPhotos()
        } catch {
            print("Error deleting photo: \(error)")
        }
    }
    
    var lastPhoto: Photo? {
        return photos.first
    }
}
