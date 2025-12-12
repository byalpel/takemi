import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("Schedule")) {
                HStack {
                    Text("Daily Capture Time")
                    Spacer()
                    // Simple integer pickers as DatePicker can be complex with storing just hour/minute reliably across timezones if not careful, but DatePicker is standard.
                    // Let's use DatePicker for better UI but only persist hour/minute.
                    DatePicker("", selection: Binding(get: {
                        settings.dailyCaptureDate
                    }, set: { newDate in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                        settings.dailyCaptureHour = components.hour ?? 14
                        settings.dailyCaptureMinute = components.minute ?? 0
                        // Reschedule handled by Scheduler (polling) or we can force update?
                        // Scheduler polls settings, so it picks up change automatically next minute.
                    }), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                }
            }
            
            Section(header: Text("Storage")) {
                HStack {
                    Text(settings.storageURL.path)
                        .truncationMode(.middle)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button("Choose...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.allowsMultipleSelection = false
                        
                        panel.begin { response in
                            if response == .OK, let url = panel.url {
                                settings.setStorageURL(url)
                                PhotoManager.shared.loadPhotos()
                            }
                        }
                    }
                }
            }
            
            Section {
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 350)
    }
}
