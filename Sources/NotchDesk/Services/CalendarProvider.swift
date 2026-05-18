import EventKit
import SwiftUI

final class CalendarProvider: ObservableObject {
    @Published private(set) var entries: [CalendarEntry] = []
    @Published private(set) var authorizationLabel = "Calendar access not requested"

    private let store = EKEventStore()

    var todayEntries: [CalendarEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            calendar.isDate(entry.startDate, inSameDayAs: Date())
                || calendar.isDate(entry.endDate, inSameDayAs: Date())
                || (entry.startDate < Date() && entry.endDate > Date())
        }
    }

    func requestAndLoad() {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { [weak self] granted, error in
                self?.handleAuthorization(granted: granted, error: error)
            }
        } else {
            store.requestAccess(to: .event) { [weak self] granted, error in
                self?.handleAuthorization(granted: granted, error: error)
            }
        }
    }

    func reload() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .authorized:
            loadEvents()
        case .notDetermined:
            requestAndLoad()
        case .denied, .restricted, .writeOnly:
            DispatchQueue.main.async {
                self.authorizationLabel = "Calendar access is disabled"
                self.entries = []
            }
        @unknown default:
            DispatchQueue.main.async {
                self.authorizationLabel = "Calendar access unavailable"
                self.entries = []
            }
        }
    }

    private func handleAuthorization(granted: Bool, error: Error?) {
        DispatchQueue.main.async {
            if let error {
                self.authorizationLabel = error.localizedDescription
            } else {
                self.authorizationLabel = granted ? "Calendar access granted" : "Calendar access denied"
            }
        }

        if granted {
            loadEvents()
        }
    }

    private func loadEvents() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = store.events(matching: predicate)
            .filter { $0.calendar.allowsContentModifications || $0.calendar.type != .birthday }
            .sorted { $0.startDate < $1.startDate }
            .prefix(6)
            .map { event in
                CalendarEntry(
                    title: event.title ?? "Untitled",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    calendarColor: Color(nsColor: NSColor(cgColor: event.calendar.cgColor) ?? .systemBlue),
                    isAllDay: event.isAllDay
                )
            }

        DispatchQueue.main.async {
            self.authorizationLabel = events.isEmpty ? "No upcoming events" : "Upcoming events"
            self.entries = Array(events)
        }
    }
}
