import SwiftUI

struct CalendarUpcomingListView: View {
    let events: [CalendarUpcomingEvent]
    let palette: CalendarPalette

    var body: some View {
        VStack(spacing: 0) {
            if events.isEmpty {
                Text("暂无后续节日或节气")
                    .font(.system(size: 14))
                    .foregroundStyle(palette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 65)
                    .padding(.horizontal, 18)
            } else {
                ForEach(events) { event in
                    CalendarUpcomingRowView(event: event, palette: palette)
                    if event.id != events.last?.id {
                        Divider()
                            .overlay(palette.separator)
                            .padding(.leading, 20)
                    }
                }
            }
        }
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: palette.shadow, radius: 0, x: 0, y: 1)
    }
}
