import SwiftUI

struct CalendarDayCellView: View {
    let date: Date
    let monthNumber: Int
    let dayNumber: Int
    let isToday: Bool
    let isWeekend: Bool
    let isSelected: Bool
    let palette: CalendarPalette
    let showAnnotationDot: Bool
    let subtitle: String
    let badge: DayBadge?
    let cellHeight: CGFloat
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottom) {
                    VStack(spacing: cellSpacing) {
                        Text(String(dayNumber))
                            .font(.system(size: dayNumberFontSize, weight: .semibold))
                            .foregroundStyle(dayTextColor)
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        Text(subtitle)
                            .font(.system(size: subtitleFontSize))
                            .foregroundStyle(subtitleTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(height: subtitleHeight)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, contentTopPadding)
                    .frame(maxHeight: .infinity, alignment: .top)

                    if showAnnotationDot {
                        Circle()
                            .fill(dotColor)
                            .frame(width: 4, height: 4)
                            .padding(.bottom, dotBottomPadding)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: cellHeight)
                .background(cellBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isSelected && !isToday ? palette.accent : Color.clear, lineWidth: 2)
                }

                if let badge {
                    Text(badge.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 17, height: 17)
                        .background(badge == .rest ? palette.restBadge : palette.workBadge, in: Circle())
                        .offset(x: 1, y: -1)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var contentTopPadding: CGFloat {
        cellHeight < 50 ? 0 : 5
    }

    private var cellSpacing: CGFloat {
        cellHeight < 50 ? 0 : 3
    }

    private var dayNumberFontSize: CGFloat {
        cellHeight < 50 ? 20 : 22
    }

    private var subtitleFontSize: CGFloat {
        cellHeight < 50 ? 11 : 12
    }

    private var subtitleHeight: CGFloat {
        cellHeight < 50 ? 12 : 13
    }

    private var dotBottomPadding: CGFloat {
        cellHeight < 50 ? 3 : 4
    }

    private var cellBackground: Color {
        if isToday { return palette.accent }
        switch badge {
        case .rest: return palette.holidayBackground
        case .work: return palette.workdayBackground
        case nil: return .clear
        }
    }

    private var dayTextColor: Color {
        if isToday { return .white }
        if isWeekend || badge == .rest { return palette.accent }
        return palette.primaryText
    }

    private var subtitleTextColor: Color {
        isToday ? Color.white.opacity(0.94) : palette.secondaryText
    }

    private var dotColor: Color {
        isToday ? Color.white.opacity(0.78) : palette.dot
    }

    private var accessibilityLabel: String {
        "\(monthNumber)月\(dayNumber)日，\(subtitle)"
    }
}

extension CalendarDayCellView: Equatable {
    nonisolated static func == (lhs: CalendarDayCellView, rhs: CalendarDayCellView) -> Bool {
        lhs.date == rhs.date
            && lhs.monthNumber == rhs.monthNumber
            && lhs.dayNumber == rhs.dayNumber
            && lhs.isToday == rhs.isToday
            && lhs.isWeekend == rhs.isWeekend
            && lhs.isSelected == rhs.isSelected
            && lhs.palette.appearance == rhs.palette.appearance
            && lhs.showAnnotationDot == rhs.showAnnotationDot
            && lhs.subtitle == rhs.subtitle
            && lhs.badge == rhs.badge
            && lhs.cellHeight == rhs.cellHeight
    }
}
