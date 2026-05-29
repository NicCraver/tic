import SwiftUI

struct CalendarUpcomingRowView: View {
    let event: CalendarUpcomingEvent
    let palette: CalendarPalette

    private let calendar = Calendar(identifier: .gregorian)

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(event.dateLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(palette.secondaryText)
            }

            Spacer(minLength: 12)

            if showsTodayLabel {
                Text("今天")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(palette.accent)
                    .accessibilityLabel("今天")
            } else if event.daysUntil > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(event.daysUntil))
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(palette.primaryText)
                        .monospacedDigit()
                    Text("天")
                        .font(.system(size: 14))
                        .foregroundStyle(palette.primaryText)
                }
                .accessibilityLabel("还有\(event.daysUntil)天")
            }
        }
        .frame(height: 65)
        .padding(.horizontal, 18)
        .accessibilityElement(children: .combine)
    }

    private var showsTodayLabel: Bool {
        event.daysUntil == 0 && calendar.isDateInToday(event.date)
    }
}
