import Foundation
import EventKit

struct OrgTodo: Codable {
    let id: String
    let title: String
    let priority: Int
    let dueDate: String?
    let state: String
}

func syncTodos() {
    // 1. Read JSON from standard input
    let inputData = FileHandle.standardInput.readDataToEndOfFile()
    let decoder = JSONDecoder()
    
    guard let todos = try? decoder.decode([OrgTodo].self, from: inputData) else {
        print("Error: Could not parse JSON from stdin")
        exit(1)
    }

    let store = EKEventStore()
    
    // 2. Request Access
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()
    
    store.requestAccess(to: .reminder) { granted, error in
        guard granted else {
            print("Error: Reminders access denied")
            exit(1)
        }
        
        // 3. Find or Create List
        var orgList = store.calendars(for: .reminder).first(where: { $0.title == "Org Todo" })
        if orgList == nil {
            let newList = EKCalendar(for: .reminder, eventStore: store)
            newList.title = "Org Todo"
            newList.source = store.defaultCalendarForNewReminders()?.source ?? store.sources.first(where: { $0.sourceType == .local })
            do {
                try store.saveCalendar(newList, commit: true)
                orgList = newList
            } catch {
                print("Failed to create list: \(error)")
                exit(1)
            }
        }
        
        guard let list = orgList else {
            print("Could not resolve list")
            exit(1)
        }
        
        // 4. Fetch existing reminders
        let predicate = store.predicateForReminders(in: [list])
        store.fetchReminders(matching: predicate) { existingReminders in
            let existingReminders = existingReminders ?? []
            
            var existingBySyncId = [String: EKReminder]()
            for rem in existingReminders {
                if let notes = rem.notes, let range = notes.range(of: "\\[sync-id: (.*?)\\]", options: .regularExpression) {
                    let match = String(notes[range])
                    let id = match.replacingOccurrences(of: "[sync-id: ", with: "").replacingOccurrences(of: "]", with: "")
                    existingBySyncId[id] = rem
                }
            }
            

            
            // 5. Update or Create
            for todo in todos {
                // If it's done or not TODO/WAIT in org but we still parsed it, we ignore it? 
                // Our python script only outputs TODO and WAIT states.
                
                let rem: EKReminder
                if let existing = existingBySyncId[todo.id] {
                    rem = existing
                } else {
                    rem = EKReminder(eventStore: store)
                    rem.calendar = list
                    rem.notes = "[sync-id: \(todo.id)]\nAuto-synced from Org Mode."
                }
                
                rem.title = todo.title
                rem.priority = todo.priority
                
                if let dateString = todo.dueDate {
                    let parts = dateString.split(separator: "-").compactMap { Int($0) }
                    if parts.count == 3 {
                        var components = DateComponents()
                        components.year = parts[0]
                        components.month = parts[1]
                        components.day = parts[2]
                        rem.dueDateComponents = components
                    } else {
                        rem.dueDateComponents = nil
                    }
                } else {
                    rem.dueDateComponents = nil
                }
                
                do {
                    try store.save(rem, commit: false)
                } catch {
                    print("Failed to save reminder \(todo.title): \(error)")
                }
            }
            
            // 6. Commit changes
            do {
                try store.commit()
            } catch {
                print("Failed to commit changes: \(error)")
                exit(1)
            }
            
            dispatchGroup.leave()
        }
    }
    
    dispatchGroup.wait()
}

syncTodos()
