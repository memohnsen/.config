import EventKit
import Foundation

let args = CommandLine.arguments
let daysAhead = Int(args.count > 1 ? args[1] : "14") ?? 14
let includePattern = args.count > 2 ? args[2] : ""
let outputPath = args.count > 3 ? args[3] : nil

let store = EKEventStore()
let semaphore = DispatchSemaphore(value: 0)
var accessGranted = false

if #available(macOS 14.0, *) {
    store.requestFullAccessToEvents { granted, _ in
        accessGranted = granted
        semaphore.signal()
    }
} else {
    store.requestAccess(to: .event) { granted, _ in
        accessGranted = granted
        semaphore.signal()
    }
}

semaphore.wait()

guard accessGranted else {
    fputs("Calendar access was not granted for macos-calendar-to-org-helper.\n", stderr)
    exit(1)
}

let calendar = Calendar.current
let now = Date()
let end = calendar.date(byAdding: .day, value: daysAhead, to: now) ?? now
let includeRegex = includePattern.isEmpty ? nil : try? NSRegularExpression(
    pattern: includePattern,
    options: [.caseInsensitive]
)

let dateFormatter = DateFormatter()
dateFormatter.locale = Locale(identifier: "en_US_POSIX")
dateFormatter.dateFormat = "yyyy-MM-dd EEE"

let timeFormatter = DateFormatter()
timeFormatter.locale = Locale(identifier: "en_US_POSIX")
timeFormatter.dateFormat = "HH:mm"

let generatedFormatter = DateFormatter()
generatedFormatter.locale = Locale.current
generatedFormatter.dateStyle = .full
generatedFormatter.timeStyle = .medium

func calendarIncluded(_ name: String) -> Bool {
    guard let includeRegex else { return true }
    let range = NSRange(name.startIndex..<name.endIndex, in: name)
    return includeRegex.firstMatch(in: name, range: range) != nil
}

func cleanOrg(_ value: String?) -> String {
    (value ?? "")
        .replacingOccurrences(of: "\r", with: " ")
        .replacingOccurrences(of: "\n", with: " ")
        .replacingOccurrences(of: "\t", with: " ")
}

func orgStamp(start: Date, end: Date, allDay: Bool) -> String {
    if allDay {
        return "<\(dateFormatter.string(from: start))>"
    }

    if calendar.isDate(start, inSameDayAs: end) {
        return "<\(dateFormatter.string(from: start)) \(timeFormatter.string(from: start))-\(timeFormatter.string(from: end))>"
    }

    return "<\(dateFormatter.string(from: start)) \(timeFormatter.string(from: start))>--<\(dateFormatter.string(from: end)) \(timeFormatter.string(from: end))>"
}

func eventStart(_ event: EKEvent) -> Date {
    event.startDate ?? now
}

func eventEnd(_ event: EKEvent) -> Date {
    event.endDate ?? eventStart(event)
}

func eventEndDay(_ event: EKEvent) -> Date {
    // EventKit stores all-day event end dates as exclusive midnight boundaries.
    let adjustedEnd = event.isAllDay ? eventEnd(event).addingTimeInterval(-1) : eventEnd(event)
    return calendar.startOfDay(for: adjustedEnd)
}

func eventDays(_ event: EKEvent, windowStart: Date, windowEnd: Date) -> [Date] {
    let firstEventDay = calendar.startOfDay(for: eventStart(event))
    let lastEventDay = eventEndDay(event)
    let firstWindowDay = calendar.startOfDay(for: windowStart)
    let lastWindowDay = calendar.startOfDay(for: windowEnd.addingTimeInterval(-1))
    let firstDay = max(firstEventDay, firstWindowDay)
    let lastDay = min(lastEventDay, lastWindowDay)

    if firstDay > lastDay {
        return []
    }

    var days: [Date] = []
    var day = firstDay
    while day <= lastDay {
        days.append(day)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
            break
        }
        day = nextDay
    }
    return days
}

func stampForOccurrence(event: EKEvent, day: Date) -> String {
    if calendar.isDate(eventStart(event), inSameDayAs: eventEnd(event)) {
        return orgStamp(start: eventStart(event), end: eventEnd(event), allDay: event.isAllDay)
    }

    return "<\(dateFormatter.string(from: day))>"
}

var output = """
#+title: macOS Calendar
#+startup: overview
#+generated: \(generatedFormatter.string(from: now))

"""

for ekCalendar in store.calendars(for: .event) where calendarIncluded(ekCalendar.title) {
    let predicate = store.predicateForEvents(withStart: now, end: end, calendars: [ekCalendar])
    let events = store.events(matching: predicate).sorted { eventStart($0) < eventStart($1) }

    for event in events {
        if eventEnd(event) <= now || eventStart(event) >= end {
            continue
        }

        let title = event.title ?? ""
        if title.localizedCaseInsensitiveContains("birthday") {
            continue
        }

        for day in eventDays(event, windowStart: now, windowEnd: end) {
            output += "* \(cleanOrg(title))\n"
            output += "SCHEDULED: \(stampForOccurrence(event: event, day: day))\n"
            output += ":PROPERTIES:\n"
            output += ":CALENDAR: \(cleanOrg(ekCalendar.title))\n"

            let location = cleanOrg(event.location)
            if !location.isEmpty {
                output += ":LOCATION: \(location)\n"
            }

            output += ":END:\n\n"
        }
    }
}

if let outputPath {
    do {
        try output.write(toFile: outputPath, atomically: true, encoding: .utf8)
    } catch {
        fputs("Failed to write \(outputPath): \(error)\n", stderr)
        exit(1)
    }
} else {
    print(output, terminator: "")
}
