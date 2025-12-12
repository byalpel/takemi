import Foundation
import Combine

class Scheduler: ObservableObject {
    static let shared = Scheduler()
    @Published var shouldShowCaptureWindow: Bool = false
    
    private var timer: Timer?
    
    init() {
        startTimer()
    }
    
    func startTimer() {
        timer?.invalidate()
        // Check every minute
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkTime()
        }
        checkTime() // Check immediately on launch
    }
    
    private func checkTime() {
        let settings = SettingsManager.shared
        let now = Date()
        let calendar = Calendar.current
        
        let targetHour = settings.dailyCaptureHour
        let targetMinute = settings.dailyCaptureMinute
        
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // Simple trigger: if time matches exactly. 
        // Robust trigger: check if we haven't taken a photo today yet AND it's past the time.
        // For this prototype, we will stick to the prompt: "on scheduled time... bring up the window".
        // A simple minute-match is okay, but we should avoid re-triggering constantly during that minute.
        // We can track "last triggered date".
        
        if currentHour == targetHour && currentMinute == targetMinute {
            // Check if we already triggered today to prevent multiple triggers in the same minute
            let lastTrigger = UserDefaults.standard.object(forKey: "lastTriggerDate") as? Date ?? Date.distantPast
            if !calendar.isDateInToday(lastTrigger) {
                print("Triggering Capture Window")
                shouldShowCaptureWindow = true
                UserDefaults.standard.set(now, forKey: "lastTriggerDate")
            }
        }
    }
    
    func forceTrigger() {
        shouldShowCaptureWindow = true
    }
}
