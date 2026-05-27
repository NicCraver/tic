import SwiftUI

struct MonthYearPickerPopover: View {
    @Binding var pickerYear: Int
    let selectedMonth: Int
    let onSelectMonth: (Int) -> Void
    let onGoToCurrentYear: () -> Void

    private let monthColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            yearHeader
            monthGrid
        }
        .padding(14)
        .frame(width: 223)
        .background(CalendarPopoverTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var yearHeader: some View {
        HStack {
            Text(String(pickerYear))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(CalendarPopoverTheme.primaryText)

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
                .foregroundStyle(isSelected ? .white : CalendarPopoverTheme.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? CalendarPopoverTheme.accent : Color.clear)
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
                .foregroundStyle(CalendarPopoverTheme.secondaryText)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

enum CalendarPopoverTheme {
    static let background = Color(red: 0.07, green: 0.07, blue: 0.08)
    static let surface = Color(red: 0.14, green: 0.14, blue: 0.16)
    static let cell = Color(red: 0.18, green: 0.18, blue: 0.20)
    static let accent = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.45)
    static let mutedText = Color.white.opacity(0.22)
    static let restBadge = Color(red: 1.0, green: 0.32, blue: 0.32)
    static let workBadge = Color(red: 0.35, green: 0.62, blue: 1.0)
}
