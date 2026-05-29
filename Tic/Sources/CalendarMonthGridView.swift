import SwiftUI

struct CalendarMonthGridView: View {
    let slots: [CalendarMonthSlot]
    let selectedDate: Date
    let palette: CalendarPalette
    let showAnnotationDots: Bool
    let subtitleRotationIndex: Int
    let onSelectDate: (Date) -> Void

    private let calendar = Calendar(identifier: .gregorian)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var rowCount: Int {
        Int(ceil(Double(slots.count) / 7.0))
    }

    private var rowSpacing: CGFloat {
        rowCount > 5 ? 10 : 17
    }

    private var cellHeight: CGFloat {
        rowCount > 5 ? 46 : 55
    }

    var body: some View {
        let selectedDayID = dayID(for: selectedDate)
        let todayID = dayID(for: .now)

        LazyVGrid(columns: columns, spacing: rowSpacing) {
            ForEach(slots) { slot in
                if let date = slot.date {
                    let subtitle = slot.subtitle(rotationIndex: subtitleRotationIndex)
                    CalendarDayCellView(
                        date: date,
                        monthNumber: slot.monthNumber,
                        dayNumber: slot.dayNumber,
                        isToday: slot.id == todayID,
                        isWeekend: slot.isWeekend,
                        isSelected: slot.id == selectedDayID,
                        palette: palette,
                        showAnnotationDot: showAnnotationDots && slot.hasAnnotation,
                        subtitle: subtitle,
                        badge: slot.badge,
                        cellHeight: cellHeight,
                        onSelect: { onSelectDate(date) }
                    )
                    .equatable()
                } else {
                    Color.clear
                        .frame(height: cellHeight)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private func dayID(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return "\(year)-\(Self.twoDigit(month))-\(Self.twoDigit(day))"
    }

    private static func twoDigit(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
