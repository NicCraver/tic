import SwiftUI

struct MonthYearPickerPopover: View {
    @Binding var pickerYear: Int
    let selectedMonth: Int
    let onSelectMonth: (Int) -> Void
    let onGoToCurrentYear: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let monthColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    private var palette: CalendarPalette {
        CalendarPopoverTheme.palette(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            yearHeader
            monthGrid
        }
        .padding(14)
        .frame(width: 223)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var yearHeader: some View {
        HStack {
            Text(String(pickerYear))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(palette.primaryText)

            Spacer()

            HStack(spacing: 6) {
                yearNavButton(icon: "chevron.left", label: "上一年") {
                    pickerYear -= 1
                }
                yearNavButton(icon: "circle.fill", label: "今年", isDot: true) {
                    onGoToCurrentYear()
                }
                yearNavButton(icon: "chevron.right", label: "下一年") {
                    pickerYear += 1
                }
            }
        }
    }

    private var monthGrid: some View {
        LazyVGrid(columns: monthColumns, spacing: 8) {
            ForEach(1...12, id: \.self) { month in
                monthButton(month)
            }
        }
    }

    private func monthButton(_ month: Int) -> some View {
        let isSelected = month == selectedMonth

        return Button {
            onSelectMonth(month)
        } label: {
            Text("\(month)月")
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : palette.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? palette.accent : Color.clear)
                }
        }
        .buttonStyle(.plain)
    }

    private func yearNavButton(
        icon: String,
        label: String,
        isDot: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: isDot ? 6 : 10, weight: .semibold))
                .foregroundStyle(palette.secondaryText)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct CalendarPalette {
    let background: Color
    let surface: Color
    let cell: Color
    let accent: Color
    let primaryText: Color
    let secondaryText: Color
    let mutedText: Color
    let restBadge: Color
    let workBadge: Color
    let separator: Color
}

enum CalendarPopoverTheme {
    static func palette(for scheme: ColorScheme) -> CalendarPalette {
        switch scheme {
        case .dark:
            return CalendarPalette(
                background: Color(red: 0.07, green: 0.07, blue: 0.08),
                surface: Color(red: 0.14, green: 0.14, blue: 0.16),
                cell: Color(red: 0.18, green: 0.18, blue: 0.20),
                accent: Color(red: 0.0, green: 0.48, blue: 1.0),
                primaryText: .white,
                secondaryText: Color.white.opacity(0.45),
                mutedText: Color.white.opacity(0.22),
                restBadge: Color(red: 1.0, green: 0.32, blue: 0.32),
                workBadge: Color(red: 0.35, green: 0.62, blue: 1.0),
                separator: Color.white.opacity(0.12)
            )
        default:
            return CalendarPalette(
                background: Color(red: 0.95, green: 0.95, blue: 0.97),
                surface: .white,
                cell: Color(red: 0.92, green: 0.92, blue: 0.94),
                accent: Color(red: 0.0, green: 0.48, blue: 1.0),
                primaryText: Color(red: 0.1, green: 0.1, blue: 0.12),
                secondaryText: Color.black.opacity(0.45),
                mutedText: Color.black.opacity(0.25),
                restBadge: Color(red: 1.0, green: 0.32, blue: 0.32),
                workBadge: Color(red: 0.35, green: 0.62, blue: 1.0),
                separator: Color.black.opacity(0.12)
            )
        }
    }
}
