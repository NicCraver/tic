import SwiftUI

struct CalendarPopoverView: View {
    @State private var selectedDate = Date.now
    @State private var displayedMonth = Date.now
    @State private var isMonthPickerPresented = false
    @State private var pickerYear: Int = Calendar.current.component(.year, from: .now)
    @Environment(\.colorScheme) private var systemColorScheme

    @AppStorage(AppSettings.appThemeKey) private var appThemeRaw = AppTheme.system.rawValue
    @AppStorage(AppSettings.showAnnotationDotsKey) private var showAnnotationDots = true
    @AppStorage(AppSettings.showSolarTermsKey) private var showSolarTerms = true

    private let calendar = Calendar.current
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var resolvedColorScheme: ColorScheme {
        switch AppTheme(rawValue: appThemeRaw) ?? .system {
        case .system: systemColorScheme
        case .light: .light
        case .dark: .dark
        }
    }

    private var palette: CalendarPalette {
        CalendarPopoverTheme.palette(for: resolvedColorScheme)
    }

    private var gridDays: [CalendarGridDay] {
        ChineseCalendarSupport.monthGrid(for: displayedMonth)
    }

    private var displayedMonthNumber: Int {
        calendar.component(.month, from: displayedMonth)
    }

    private var displayedYear: Int {
        calendar.component(.year, from: displayedMonth)
    }

    private var isShowingCurrentMonth: Bool {
        calendar.isDate(displayedMonth, equalTo: .now, toGranularity: .month)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                header
                weekdayHeader
                calendarGrid
                selectedDateCard
                bottomBar
            }
            .padding(14)
        }
        .background(palette.background)
        .preferredColorScheme(AppTheme(rawValue: appThemeRaw)?.colorScheme)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.leftArrow) {
            shiftSelectedDate(by: -1)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            shiftSelectedDate(by: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            shiftSelectedDate(by: -7)
            return .handled
        }
        .onKeyPress(.downArrow) {
            shiftSelectedDate(by: 7)
            return .handled
        }
        .background { monthKeyboardShortcuts }
    }

    private var monthKeyboardShortcuts: some View {
        Group {
            Button("") { shiftMonth(by: -1) }
                .keyboardShortcut(.leftArrow, modifiers: [.option])
            Button("") { shiftMonth(by: 1) }
                .keyboardShortcut(.rightArrow, modifiers: [.option])
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            HStack(spacing: 4) {
                navButton(icon: "chevron.left", accessibilityLabel: "上一月") {
                    shiftMonth(by: -1)
                }
                navButton(
                    icon: "circle",
                    accessibilityLabel: "今天",
                    emphasized: isShowingCurrentMonth && calendar.isDateInToday(selectedDate)
                ) {
                    goToToday()
                }
                navButton(icon: "chevron.right", accessibilityLabel: "下一月") {
                    shiftMonth(by: 1)
                }
            }

            monthYearPickerButton

            Spacer(minLength: 0)

            dateContextPills
        }
    }

    private var monthYearPickerButton: some View {
        Button {
            pickerYear = displayedYear
            isMonthPickerPresented = true
        } label: {
            Text("\(displayedMonthNumber)月 \(displayedYear)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(palette.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isMonthPickerPresented, arrowEdge: .top) {
            MonthYearPickerPopover(
                pickerYear: $pickerYear,
                selectedMonth: displayedMonthNumber,
                onSelectMonth: { month in
                    setDisplayed(month: month, year: pickerYear)
                    isMonthPickerPresented = false
                },
                onGoToCurrentYear: {
                    pickerYear = calendar.component(.year, from: .now)
                }
            )
            .preferredColorScheme(AppTheme(rawValue: appThemeRaw)?.colorScheme)
        }
    }

    private var dateContextPills: some View {
        VStack(alignment: .trailing, spacing: 6) {
            contextPill(ChineseCalendarSupport.relativeDayLabel(for: selectedDate))

            if let festival = ChineseCalendarSupport.nextFestivalCountdown(from: selectedDate) {
                let suffix = ChineseCalendarSupport.festivalCountdownLabel(days: festival.days)
                contextPill("\(festival.name) · \(suffix)")
            }
        }
    }

    private func contextPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(palette.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .overlay {
                Capsule()
                    .strokeBorder(palette.accent.opacity(0.55), lineWidth: 1)
            }
            .fixedSize()
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(weekdays, id: \.self) { label in
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(gridDays) { day in
                dayCell(day)
            }
        }
    }

    private var selectedDateCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(weekdayLabel(for: selectedDate))
                    .font(.system(size: 11))
                    .foregroundStyle(palette.secondaryText)
                Text("\(calendar.component(.day, from: selectedDate))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                    .monospacedDigit()
            }
            .frame(width: 64, alignment: .leading)

            Rectangle()
                .fill(palette.separator)
                .frame(width: 1)
                .padding(.vertical, 6)
                .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(ChineseCalendarSupport.lunarYearLabel(for: selectedDate)) \(ChineseCalendarSupport.lunarMonthDayLabel(for: selectedDate))")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.primaryText)
                if showSolarTerms, let term = ChineseCalendarSupport.solarTermName(for: selectedDate) {
                    Text(term)
                        .font(.system(size: 12))
                        .foregroundStyle(palette.accent)
                }
                Text("第\(ChineseCalendarSupport.weekOfYear(for: selectedDate))周")
                    .font(.system(size: 12))
                    .foregroundStyle(palette.secondaryText)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var bottomBar: some View {
        HStack {
            Button("今天") {
                goToToday()
            }

            Spacer()

            Button("设置…") {
                SettingsWindowManager.show()
            }

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .controlSize(.small)
        .foregroundStyle(palette.secondaryText)
    }

    private func dayCell(_ day: CalendarGridDay) -> some View {
        let isSelected = calendar.isDate(day.date, inSameDayAs: selectedDate)
        let dayNumber = calendar.component(.day, from: day.date)
        let subtitle = ChineseCalendarSupport.cellSubtitle(for: day.date, showSolarTerms: showSolarTerms)
        let badge = ChineseCalendarSupport.badge(for: day.date)
        let showDot = showAnnotationDots && ChineseCalendarSupport.hasAnnotation(for: day.date)

        return Button {
            selectedDate = day.date
            if !day.isInDisplayedMonth {
                displayedMonth = day.date
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottom) {
                    VStack(spacing: 2) {
                        Text("\(dayNumber)")
                            .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(dayTextColor(isSelected: isSelected, inMonth: day.isInDisplayedMonth))
                        Text(subtitle)
                            .font(.system(size: 9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(daySubtitleColor(isSelected: isSelected, inMonth: day.isInDisplayedMonth))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 41)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected ? palette.accent : palette.cell.opacity(day.isInDisplayedMonth ? 1 : 0.35))
                    }

                    if showDot {
                        Circle()
                            .fill(isSelected ? Color.white : palette.accent)
                            .frame(width: 4, height: 4)
                            .padding(.bottom, 3)
                    }
                }

                if let badge {
                    Text(badge.rawValue)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(
                            badge == .rest ? palette.restBadge : palette.workBadge,
                            in: RoundedRectangle(cornerRadius: 3, style: .continuous)
                        )
                        .offset(x: 2, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func navButton(
        icon: String,
        accessibilityLabel: String,
        emphasized: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: icon == "circle" ? 8 : 11, weight: .semibold))
                .foregroundStyle(emphasized ? palette.accent : palette.secondaryText)
                .frame(width: 26, height: 26)
                .background(palette.surface, in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(accessibilityLabel)
    }

    private func shiftMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: startOfMonth(displayedMonth)) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = newMonth
            pickerYear = calendar.component(.year, from: newMonth)
        }
    }

    private func shiftSelectedDate(by days: Int) {
        guard let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedDate = newDate
            if !calendar.isDate(newDate, equalTo: displayedMonth, toGranularity: .month) {
                displayedMonth = newDate
                pickerYear = calendar.component(.year, from: newDate)
            }
        }
    }

    private func goToToday() {
        let today = Date.now
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDate = today
            displayedMonth = today
            pickerYear = calendar.component(.year, from: today)
        }
    }

    private func setDisplayed(month: Int, year: Int) {
        let components = DateComponents(year: year, month: month, day: 1)
        guard let newMonth = calendar.date(from: components) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = newMonth
            pickerYear = year
        }
    }

    private func startOfMonth(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func weekdayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func dayTextColor(isSelected: Bool, inMonth: Bool) -> Color {
        if isSelected { return .white }
        return inMonth ? palette.primaryText : palette.mutedText
    }

    private func daySubtitleColor(isSelected: Bool, inMonth: Bool) -> Color {
        if isSelected { return .white.opacity(0.85) }
        return inMonth ? palette.secondaryText : palette.mutedText
    }
}
