import Foundation

struct CalendarUpcomingEvent: Identifiable {
    let id: String
    let title: String
    let date: Date
    let daysUntil: Int
    let dateLabel: String
}

