import SwiftUI

struct CalendarLunarCardView: View {
    let selectedDate: Date
    let palette: CalendarPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ChineseCalendarSupport.lunarMonthDayLabel(for: selectedDate))
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(palette.accent)
                .contentTransition(.numericText())

            Text(ChineseCalendarSupport.lunarDetailMeta(for: selectedDate))
                .font(.system(size: 13))
                .foregroundStyle(palette.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(height: 72)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: palette.shadow, radius: 0, x: 0, y: 1)
    }
}
