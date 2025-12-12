import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("dailyCaptureHour") var dailyCaptureHour: Int = 14
    @AppStorage("dailyCaptureMinute") var dailyCaptureMinute: Int = 0
    @AppStorage("photoStoragePath") var photoStoragePath: String = ""
    
    var storageURL: URL {
        if !photoStoragePath.isEmpty {
            return URL(fileURLWithPath: photoStoragePath)
        }
        // Default to ~/Documents/TakeMe
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let defaultPath = documents.appendingPathComponent("TakeMe")
        return defaultPath
    }
    
    init() {
        if photoStoragePath.isEmpty {
            // Set default path if not set
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let defaultPath = documents.appendingPathComponent("TakeMe")
            photoStoragePath = defaultPath.path
            ensureDirectoryExists(at: defaultPath)
        } else {
            ensureDirectoryExists(at: URL(fileURLWithPath: photoStoragePath))
        }
    }
    
    func setStorageURL(_ url: URL) {
        photoStoragePath = url.path
        ensureDirectoryExists(at: url)
    }
    
    private func ensureDirectoryExists(at url: URL) {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            print("Error creating directory: \(error)")
        }
    }
    
    var dailyCaptureDate: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = dailyCaptureHour
        components.minute = dailyCaptureMinute
        return Calendar.current.date(from: components) ?? Date()
    }
}
