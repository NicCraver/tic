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
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
        Button(label, systemImage: icon, action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: isDot ? 6 : 10, weight: .semibold))
            .foregroundStyle(palette.secondaryText)
            .frame(width: 24, height: 24)
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
