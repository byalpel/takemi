import SwiftUI

@main
struct TakeMiApp: App {
    @StateObject var scheduler = Scheduler.shared
    @Environment(\.openWindow) var openWindow
    
    init() {
        print("TakeMi App Launched.")
    }
    
    var body: some Scene {
        MenuBarExtra("TakeMi", systemImage: "face.smiling") {
            AppMenu()
                .environmentObject(scheduler)
        }
        
        WindowGroup("Capture", id: "capture") {
            CaptureView()
                .frame(minWidth: 400, minHeight: 600)
                .onDisappear {
                    scheduler.shouldShowCaptureWindow = false
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 600)
        
        WindowGroup("Gallery", id: "gallery") {
            GalleryView()
        }
        
        Window("Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
    }
}

struct AppMenu: View {
    @Environment(\.openWindow) var openWindow
    @EnvironmentObject var scheduler: Scheduler
    
    var body: some View {
        Button("Capture Now") {
            openWindow(id: "capture")
            NSApp.activate(ignoringOtherApps: true)
        }
        
        Button("Gallery") {
            openWindow(id: "gallery")
            NSApp.activate(ignoringOtherApps: true)
        }
        
        Divider()
        
        Button("Settings...") {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        }
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
        
        // Invisible view to handle the scheduler trigger
        .onChange(of: scheduler.shouldShowCaptureWindow) { shouldShow in
            if shouldShow {
                openWindow(id: "capture")
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
