import SwiftUI

struct CalendarPopoverView: View {
    @State private var selectedDate: Date
    @State private var displayedMonth: Date
    @State private var isMonthPickerPresented = false
    @State private var pickerYear: Int
    @State private var subtitleRotationIndex = 0
    @State private var monthSlots: [CalendarMonthSlot]
    @State private var upcomingEvents: [CalendarUpcomingEvent]
    @State private var dataCache = CalendarPopoverDataCache()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var systemColorScheme

    @AppStorage(AppSettings.appThemeKey) private var appThemeRaw = AppTheme.system.rawValue
    @AppStorage(AppSettings.showAnnotationDotsKey) private var showAnnotationDots = true
    @AppStorage(AppSettings.showSolarTermsKey) private var showSolarTerms = true

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        return calendar
    }()

    init(initialDate: Date = .now) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        let initialDay = calendar.startOfDay(for: initialDate)
        let year = calendar.component(.year, from: initialDay)
        let usesSolarTerms = UserDefaults.standard.object(forKey: AppSettings.showSolarTermsKey) as? Bool ?? true
        _selectedDate = State(initialValue: initialDay)
        _displayedMonth = State(initialValue: initialDay)
        _pickerYear = State(initialValue: year)
        _monthSlots = State(initialValue: ChineseCalendarSupport.monthSlots(for: initialDay, showSolarTerms: usesSolarTerms))
        _upcomingEvents = State(initialValue: ChineseCalendarSupport.upcomingEvents(
            from: initialDay,
            limit: 3,
            includeSolarTerms: usesSolarTerms
        ))
    }

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

    private var displayedMonthNumber: Int {
        calendar.component(.month, from: displayedMonth)
    }

    private var displayedYear: Int {
        calendar.component(.year, from: displayedMonth)
    }

    private var relativeOffsetLabel: String? {
        let label = ChineseCalendarSupport.relativeDayLabel(for: selectedDate)
        return label == "今天" ? nil : label
    }

    private var themeToggleTitle: String {
        resolvedColorScheme == .dark ? "浅色" : "深色"
    }

    private var themeToggleSystemImage: String {
        resolvedColorScheme == .dark ? "sun.max.fill" : "moon.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CalendarPopoverHeader(
                monthNumber: displayedMonthNumber,
                year: displayedYear,
                relativeOffsetLabel: relativeOffsetLabel,
                themeToggleTitle: themeToggleTitle,
                themeToggleSystemImage: themeToggleSystemImage,
                palette: palette,
                onShowMonthPicker: showMonthPicker,
                onToggleTheme: toggleTheme,
                onShowSettings: showSettings
            )
            .popover(isPresented: $isMonthPickerPresented, arrowEdge: .top) {
                monthYearPicker
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            CalendarWeekdayRow(palette: palette)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            CalendarMonthGridView(
                slots: monthSlots,
                selectedDate: selectedDate,
                palette: palette,
                showAnnotationDots: showAnnotationDots,
                subtitleRotationIndex: subtitleRotationIndex,
                onSelectDate: selectDate
            )
            .padding(.horizontal, 8)

            CalendarDetailsSection(
                selectedDate: selectedDate,
                upcomingEvents: upcomingEvents,
                palette: palette
            )
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .top)
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
        .onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect()) { _ in
            rotateSubtitles()
        }
        .onAppear {
            refreshCalendarData(displayedMonth: displayedMonth, selectedDate: selectedDate)
        }
        .onChange(of: showSolarTerms) {
            refreshCalendarData(displayedMonth: displayedMonth, selectedDate: selectedDate)
        }
        .onReceive(NotificationCenter.default.publisher(for: .holidayDataDidUpdate)) { _ in
            dataCache = CalendarPopoverDataCache()
            refreshCalendarData(displayedMonth: displayedMonth, selectedDate: selectedDate)
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

    private func showMonthPicker() {
        pickerYear = displayedYear
        isMonthPickerPresented = true
    }

    private func selectDate(_ date: Date) {
        let nextDate = startOfDay(date)
        guard !calendar.isDate(nextDate, inSameDayAs: selectedDate) else {
            return
        }
        let nextUpcomingEvents = upcomingEvents(from: nextDate)
        selectedDate = nextDate
        upcomingEvents = nextUpcomingEvents
    }

    private func shiftMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: startOfMonth(displayedMonth)) else {
            return
        }
        setDisplayedMonth(newMonth, preservingSelectedDay: true)
    }

    private func shiftSelectedDate(by days: Int) {
        guard let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) else {
            return
        }

        let changesMonth = !calendar.isDate(newDate, equalTo: displayedMonth, toGranularity: .month)
        let nextMonthSlots = changesMonth ? monthSlots(for: newDate) : nil
        let nextUpcomingEvents = upcomingEvents(from: newDate)

        let updates = {
            selectedDate = newDate
            upcomingEvents = nextUpcomingEvents
            if changesMonth {
                displayedMonth = newDate
                if let nextMonthSlots {
                    monthSlots = nextMonthSlots
                }
                pickerYear = calendar.component(.year, from: newDate)
            }
        }

        if changesMonth {
            withOptionalAnimation(.easeOut(duration: 0.10), updates)
        } else {
            updates()
        }
    }

    private func goToToday() {
        let today = startOfDay(.now)
        let nextMonthSlots = monthSlots(for: today)
        let nextUpcomingEvents = upcomingEvents(from: today)
        withOptionalAnimation(.easeInOut(duration: 0.18)) {
            selectedDate = today
            displayedMonth = today
            monthSlots = nextMonthSlots
            upcomingEvents = nextUpcomingEvents
            pickerYear = calendar.component(.year, from: today)
        }
    }

    private func toggleTheme() {
        appThemeRaw = resolvedColorScheme == .dark ? AppTheme.light.rawValue : AppTheme.dark.rawValue
    }

    private func showSettings() {
        SettingsWindowManager.show()
    }

    private func setDisplayed(month: Int, year: Int) {
        let components = DateComponents(year: year, month: month, day: 1)
        guard let newMonth = calendar.date(from: components) else { return }
        setDisplayedMonth(newMonth, preservingSelectedDay: true)
    }

    private func setDisplayedMonth(_ newMonth: Date, preservingSelectedDay: Bool) {
        let nextSelectedDate = preservingSelectedDay ? dateInMonth(newMonth, matchingDayOf: selectedDate) : newMonth
        let nextMonthSlots = monthSlots(for: newMonth)
        let nextUpcomingEvents = upcomingEvents(from: nextSelectedDate)
        withOptionalAnimation(.easeInOut(duration: 0.18)) {
            displayedMonth = newMonth
            selectedDate = nextSelectedDate
            monthSlots = nextMonthSlots
            upcomingEvents = nextUpcomingEvents
            pickerYear = calendar.component(.year, from: newMonth)
        }
    }

    private func refreshCalendarData(displayedMonth: Date, selectedDate: Date) {
        monthSlots = monthSlots(for: displayedMonth)
        upcomingEvents = upcomingEvents(from: selectedDate)
    }

    private func monthSlots(for month: Date) -> [CalendarMonthSlot] {
        dataCache.monthSlots(for: month, showSolarTerms: showSolarTerms, calendar: calendar)
    }

    private func upcomingEvents(from date: Date) -> [CalendarUpcomingEvent] {
        dataCache.upcomingEvents(
            from: date,
            limit: 3,
            includeSolarTerms: showSolarTerms,
            calendar: calendar
        )
    }

    private func dateInMonth(_ month: Date, matchingDayOf date: Date) -> Date {
        let targetDay = calendar.component(.day, from: date)
        let firstOfMonth = startOfMonth(month)
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? targetDay
        let clampedDay = min(targetDay, daysInMonth)
        return calendar.date(byAdding: .day, value: clampedDay - 1, to: firstOfMonth) ?? firstOfMonth
    }

    private func startOfMonth(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func rotateSubtitles() {
        if reduceMotion {
            subtitleRotationIndex += 1
        } else {
            withAnimation(.easeInOut(duration: 0.18)) {
                subtitleRotationIndex += 1
            }
        }
    }

    private func withOptionalAnimation<Result>(
        _ animation: Animation,
        _ updates: () throws -> Result
    ) rethrows -> Result {
        if reduceMotion {
            return try updates()
        }
        return try withAnimation(animation, updates)
    }
}

private extension CalendarPopoverView {
    var monthYearPicker: some View {
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
