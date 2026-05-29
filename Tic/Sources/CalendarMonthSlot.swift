import Foundation

struct CalendarMonthSlot: Identifiable {
    let id: String
    let date: Date?
    let monthNumber: Int
    let dayNumber: Int
    let isWeekend: Bool
    let subtitles: [String]
    let hasAnnotation: Bool
    let badge: DayBadge?

    static func empty(monthKey: String, index: Int) -> CalendarMonthSlot {
        CalendarMonthSlot(
            id: "\(monthKey)-empty-\(index)",
            date: nil,
            monthNumber: 0,
            dayNumber: 0,
            isWeekend: false,
            subtitles: [],
            hasAnnotation: false,
            badge: nil
        )
    }

    static func day(
        _ date: Date,
        key: String,
        monthNumber: Int,
        dayNumber: Int,
        isWeekend: Bool,
        subtitles: [String],
        hasAnnotation: Bool,
        badge: DayBadge?
    ) -> CalendarMonthSlot {
        CalendarMonthSlot(
            id: key,
            date: date,
            monthNumber: monthNumber,
            dayNumber: dayNumber,
            isWeekend: isWeekend,
            subtitles: subtitles,
            hasAnnotation: hasAnnotation,
            badge: badge
        )
    }

    func subtitle(rotationIndex: Int) -> String {
        guard !subtitles.isEmpty else { return "" }
        return subtitles[rotationIndex % subtitles.count]
    }
}
