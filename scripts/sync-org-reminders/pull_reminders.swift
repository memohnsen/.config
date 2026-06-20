import Foundation
import EventKit
import CryptoKit

struct PulledReminder: Codable {
    let title: String
    let priority: Int
    let dueDate: String?
}

func getMD5(string: String) -> String {
    let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())
    return digest.map { String(format: "%02x", $0) }.joined()
}

func pullReminders() {
    let store = EKEventStore()
    
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()
    
    store.requestAccess(to: .reminder) { granted, error in
        guard granted else {
            print("[]")
            exit(1)
        }
        
        guard let orgList = store.calendars(for: .reminder).first(where: { $0.title == "Org Todo" }) else {
            print("[]")
            exit(0)
        }
        
        let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [orgList])
        store.fetchReminders(matching: predicate) { existingReminders in
            let existingReminders = existingReminders ?? []
            var pulled = [PulledReminder]()
            var changed = false
            
            for rem in existingReminders {
                let notes = rem.notes ?? ""
                
                // If the reminder doesn't have a sync-id, it's new
                if !notes.contains("[sync-id: ") {
                    let title = rem.title ?? "Untitled Reminder"
                    
                    // Logic MUST match python exactly: MD5(title.strip() + "-")
                    let idString = "\(title.trimmingCharacters(in: .whitespacesAndNewlines))-"
                    let hashFull = getMD5(string: idString)
                    let syncId = String(hashFull.prefix(12))
                    
                    // Update notes so it doesn't get pulled again
                    let newNotes = notes.isEmpty ? "[sync-id: \(syncId)]" : "\(notes)\n[sync-id: \(syncId)]"
                    rem.notes = newNotes
                    
                    do {
                        try store.save(rem, commit: false)
                        changed = true
                    } catch {
                        // Ignore individual save errors
                    }
                    
                    var priorityVal = 9 // Default C
                    if rem.priority == 1 { priorityVal = 1 }
                    else if rem.priority == 5 { priorityVal = 5 }
                    
                    var dateStr: String? = nil
                    if let components = rem.dueDateComponents, let date = Calendar.current.date(from: components) {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withYear, .withMonth, .withDay, .withDashSeparatorInDate]
                        dateStr = formatter.string(from: date) // YYYY-MM-DD format
                    }
                    
                    pulled.append(PulledReminder(title: title, priority: priorityVal, dueDate: dateStr))
                }
            }
            
            if changed {
                do {
                    try store.commit()
                } catch {
                    // if commit fails, maybe we still output but we'd rather not.
                }
            }
            
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(pulled), let string = String(data: data, encoding: .utf8) {
                print(string)
            } else {
                print("[]")
            }
            
            dispatchGroup.leave()
        }
    }
    
    dispatchGroup.wait()
}

pullReminders()
