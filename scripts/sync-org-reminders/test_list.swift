import EventKit

let store = EKEventStore()
store.requestAccess(to: .reminder) { granted, error in
    if granted {
        var orgList = store.calendars(for: .reminder).first(where: { $0.title == "Org Todo" })
        if orgList == nil {
            let newList = EKCalendar(for: .reminder, eventStore: store)
            newList.title = "Org Todo"
            newList.source = store.defaultCalendarForNewReminders()?.source ?? store.sources.first(where: { $0.sourceType == .local })
            do {
                try store.saveCalendar(newList, commit: true)
                print("Created Org Todo list")
                orgList = newList
            } catch {
                print("Failed to create list: \(error)")
            }
        } else {
            print("Org Todo list exists")
        }
    } else {
        print("Denied")
    }
    exit(0)
}
RunLoop.main.run()
