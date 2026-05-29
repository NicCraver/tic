import Foundation

enum DayBadge: String {
    case rest = "休"
    case work = "班"
}

struct DayAnnotation {
    var subtitle: String?
    var badge: DayBadge?
}

enum ChineseCalendarSupport {
    private struct CalendarEventCandidate {
        let date: Date
        let title: String
        let dateLabel: String
        let priority: Int
    }

    private static let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        return calendar
    }()
    private static let chinese = Calendar(identifier: .chinese)

    private static let heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    private static let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    private static let zodiacAnimals = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
    private static let lunarMonthNames = [
        "正月", "二月", "三月", "四月", "五月", "六月",
        "七月", "八月", "九月", "十月", "冬月", "腊月",
    ]
    private static let digitNames = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

    // 国务院公布的调休安排（覆盖弹窗常见浏览区间）
    private static let annotations: [String: DayAnnotation] = [
        // 2025
        "2025-01-01": .init(subtitle: "元旦", badge: .rest),
        "2025-01-26": .init(badge: .work),
        "2025-01-28": .init(subtitle: "除夕", badge: .rest),
        "2025-01-29": .init(subtitle: "春节", badge: .rest),
        "2025-01-30": .init(subtitle: "春节", badge: .rest),
        "2025-01-31": .init(subtitle: "春节", badge: .rest),
        "2025-02-01": .init(subtitle: "春节", badge: .rest),
        "2025-02-02": .init(subtitle: "春节", badge: .rest),
        "2025-02-03": .init(subtitle: "春节", badge: .rest),
        "2025-02-04": .init(subtitle: "春节", badge: .rest),
        "2025-02-08": .init(badge: .work),
        "2025-04-04": .init(subtitle: "清明", badge: .rest),
        "2025-04-05": .init(subtitle: "清明", badge: .rest),
        "2025-04-06": .init(subtitle: "清明", badge: .rest),
        "2025-04-27": .init(badge: .work),
        "2025-05-01": .init(subtitle: "劳动节", badge: .rest),
        "2025-05-02": .init(subtitle: "劳动节", badge: .rest),
        "2025-05-03": .init(subtitle: "劳动节", badge: .rest),
        "2025-05-04": .init(subtitle: "劳动节", badge: .rest),
        "2025-05-05": .init(subtitle: "劳动节", badge: .rest),
        "2025-05-31": .init(subtitle: "端午", badge: .rest),
        "2025-06-01": .init(subtitle: "端午", badge: .rest),
        "2025-06-02": .init(subtitle: "端午", badge: .rest),
        "2025-09-28": .init(badge: .work),
        "2025-10-01": .init(subtitle: "国庆", badge: .rest),
        "2025-10-02": .init(subtitle: "国庆", badge: .rest),
        "2025-10-03": .init(subtitle: "国庆", badge: .rest),
        "2025-10-04": .init(subtitle: "国庆", badge: .rest),
        "2025-10-05": .init(subtitle: "国庆", badge: .rest),
        "2025-10-06": .init(subtitle: "中秋", badge: .rest),
        "2025-10-07": .init(subtitle: "国庆", badge: .rest),
        "2025-10-08": .init(subtitle: "国庆", badge: .rest),
        "2025-10-11": .init(badge: .work),
        // 2026
        "2026-01-01": .init(subtitle: "元旦", badge: .rest),
        "2026-01-02": .init(subtitle: "元旦", badge: .rest),
        "2026-01-03": .init(subtitle: "元旦", badge: .rest),
        "2026-02-14": .init(badge: .work),
        "2026-02-15": .init(subtitle: "春节", badge: .rest),
        "2026-02-16": .init(subtitle: "除夕", badge: .rest),
        "2026-02-17": .init(subtitle: "春节", badge: .rest),
        "2026-02-18": .init(subtitle: "春节", badge: .rest),
        "2026-02-19": .init(subtitle: "春节", badge: .rest),
        "2026-02-20": .init(subtitle: "春节", badge: .rest),
        "2026-02-21": .init(subtitle: "春节", badge: .rest),
        "2026-02-22": .init(subtitle: "春节", badge: .rest),
        "2026-02-23": .init(subtitle: "春节", badge: .rest),
        "2026-02-28": .init(badge: .work),
        "2026-04-04": .init(subtitle: "清明", badge: .rest),
        "2026-04-05": .init(subtitle: "清明", badge: .rest),
        "2026-04-06": .init(subtitle: "清明", badge: .rest),
        "2026-05-01": .init(subtitle: "劳动节", badge: .rest),
        "2026-05-02": .init(subtitle: "劳动节", badge: .rest),
        "2026-05-03": .init(subtitle: "劳动节", badge: .rest),
        "2026-05-04": .init(subtitle: "劳动节", badge: .rest),
        "2026-05-05": .init(subtitle: "劳动节", badge: .rest),
        "2026-05-09": .init(badge: .work),
        "2026-06-19": .init(subtitle: "端午", badge: .rest),
        "2026-06-20": .init(subtitle: "端午", badge: .rest),
        "2026-06-21": .init(subtitle: "端午", badge: .rest),
        "2026-09-20": .init(badge: .work),
        "2026-09-25": .init(subtitle: "中秋", badge: .rest),
        "2026-09-26": .init(subtitle: "中秋", badge: .rest),
        "2026-09-27": .init(subtitle: "中秋", badge: .rest),
        "2026-10-01": .init(subtitle: "国庆", badge: .rest),
        "2026-10-02": .init(subtitle: "国庆", badge: .rest),
        "2026-10-03": .init(subtitle: "国庆", badge: .rest),
        "2026-10-04": .init(subtitle: "国庆", badge: .rest),
        "2026-10-05": .init(subtitle: "国庆", badge: .rest),
        "2026-10-06": .init(subtitle: "国庆", badge: .rest),
        "2026-10-07": .init(subtitle: "国庆", badge: .rest),
        "2026-10-10": .init(badge: .work),
        // 2027
        "2027-01-01": .init(subtitle: "元旦", badge: .rest),
        "2027-01-02": .init(subtitle: "元旦", badge: .rest),
        "2027-01-03": .init(subtitle: "元旦", badge: .rest),
    ]

    private static let solarFestivalTemplates: [(month: Int, day: Int, cellTitle: String, eventTitle: String)] = [
        (1, 1, "元旦", "元旦"),
        (2, 14, "情人节", "情人节"),
        (3, 8, "妇女节", "妇女节"),
        (5, 4, "青年节", "青年节"),
        (5, 8, "微笑日", "世界微笑日"),
        (5, 12, "护士节", "护士节"),
        (5, 18, "博物馆日", "国际博物馆日"),
        (5, 21, "国际茶日", "国际茶日"),
        (6, 1, "儿童节", "儿童节"),
        (6, 5, "环境日", "世界环境日"),
        (8, 1, "建军节", "建军节"),
        (9, 10, "教师节", "教师节"),
        (12, 24, "平安夜", "平安夜"),
        (12, 25, "圣诞节", "圣诞节"),
    ]

    private static let solarFestivalLookup: [String: (cellTitle: String, eventTitle: String)] = {
        Dictionary(uniqueKeysWithValues: solarFestivalTemplates.map { template in
            (
                monthDayKey(month: template.month, day: template.day),
                (cellTitle: template.cellTitle, eventTitle: template.eventTitle)
            )
        })
    }()

    private static let publicHolidayEvents: [CalendarEventCandidate] = {
        annotations.compactMap { key, ann -> CalendarEventCandidate? in
            guard ann.badge == .rest,
                  let subtitle = ann.subtitle,
                  let date = date(fromKey: key),
                  isFirstAnnotatedHoliday(date, subtitle: subtitle)
            else { return nil }

            return CalendarEventCandidate(
                date: date,
                title: festivalDisplayName(subtitle),
                dateLabel: gregorianDateLabel(for: date),
                priority: 0
            )
        }
        .sorted { lhs, rhs in
            if !gregorian.isDate(lhs.date, inSameDayAs: rhs.date) {
                return lhs.date < rhs.date
            }
            return lhs.priority < rhs.priority
        }
    }()

    static func annotation(for date: Date) -> DayAnnotation {
        if let stored = storedAnnotation(for: date) {
            return stored
        }
        if let festival = solarFestival(for: date)?.cellTitle {
            return DayAnnotation(subtitle: festival, badge: nil)
        }
        return DayAnnotation(subtitle: lunarDayLabel(for: date), badge: nil)
    }

    static func cellSubtitle(for date: Date, showSolarTerms: Bool = true) -> String {
        cellSubtitles(for: date, showSolarTerms: showSolarTerms).first ?? lunarDayLabel(for: date)
    }

    static func cellSubtitles(for date: Date, showSolarTerms: Bool = true) -> [String] {
        dayCellMetadata(for: date, showSolarTerms: showSolarTerms).subtitles
    }

    private static func dayCellMetadata(
        for date: Date,
        showSolarTerms: Bool
    ) -> (subtitles: [String], hasAnnotation: Bool, badge: DayBadge?) {
        var subtitles: [String] = []
        let ann = storedAnnotation(for: date)
        let solarTerm = showSolarTerms ? SolarTermSupport.name(for: date) : nil
        let festival = solarFestival(for: date)

        if let term = solarTerm {
            subtitles.append(term)
        }
        if let festival = festival?.cellTitle {
            subtitles.append(festival)
        }
        if let subtitle = ann?.subtitle,
           ann?.badge != .rest || isFirstAnnotatedHoliday(date, subtitle: subtitle) {
            subtitles.append(subtitle)
        }

        let unique = subtitles.reduce(into: [String]()) { result, subtitle in
            if !result.contains(subtitle) {
                result.append(subtitle)
            }
        }
        let hasAnnotation = ann?.badge != nil
            || ann?.subtitle.map(isSolarHoliday) == true
            || solarTerm != nil
            || festival != nil

        return (
            subtitles: unique.isEmpty ? [lunarDayLabel(for: date)] : unique,
            hasAnnotation: hasAnnotation,
            badge: ann?.badge
        )
    }

    static func solarTermName(for date: Date) -> String? {
        SolarTermSupport.name(for: date)
    }

    static func hasAnnotation(for date: Date) -> Bool {
        let ann = annotation(for: date)
        if ann.badge != nil { return true }
        if let subtitle = ann.subtitle, isSolarHoliday(subtitle) { return true }
        if SolarTermSupport.hasTerm(on: date) { return true }
        if solarFestival(for: date) != nil { return true }
        return false
    }

    static func badge(for date: Date) -> DayBadge? {
        annotation(for: date).badge
    }

    static func lunarMonthDayLabel(for date: Date) -> String {
        let month = chinese.component(.month, from: date)
        let day = chinese.component(.day, from: date)
        let monthName = lunarMonthNames[safe: month - 1] ?? "\(month)月"
        let leapPrefix = chinese.dateComponents([.month], from: date).isLeapMonth == true ? "闰" : ""
        return leapPrefix + monthName + lunarDayName(day)
    }

    static func lunarYearLabel(for date: Date) -> String {
        let yearInCycle = chinese.component(.year, from: date)
        let index = positiveModulo(yearInCycle - 1, 60)
        let stem = heavenlyStems[index % 10]
        let branch = earthlyBranches[index % 12]
        let animal = zodiacAnimals[index % 12]
        return "\(stem)\(branch)\(animal)年"
    }

    static func lunarDetailMeta(for date: Date) -> String {
        "\(lunarYearLabel(for: date)) \(sexagenaryMonthLabel(for: date))月 \(sexagenaryDayLabel(for: date))日"
    }

    static func weekOfYear(for date: Date) -> Int {
        gregorian.component(.weekOfYear, from: date)
    }

    /// 相对今天：今天 / 昨天 / 明天 / N天前 / N天后
    static func relativeDayLabel(
        for date: Date,
        relativeTo reference: Date = .now
    ) -> String {
        let target = gregorian.startOfDay(for: date)
        let anchor = gregorian.startOfDay(for: reference)
        let days = gregorian.dateComponents([.day], from: anchor, to: target).day ?? 0
        switch days {
        case 0: return "今天"
        case 1: return "明天"
        case -1: return "昨天"
        case let offset where offset > 0: return "\(offset)天后"
        default: return "\(-days)天前"
        }
    }

    static func festivalCountdownLabel(days: Int) -> String {
        switch days {
        case 0: return "今天"
        case 1: return "明天"
        default: return "\(days)天后"
        }
    }

    static func nextFestivalCountdown(from date: Date) -> (name: String, days: Int)? {
        upcomingEvents(from: date, limit: 1, includeSolarTerms: true)
            .first
            .map { ($0.title, $0.daysUntil) }
    }

    static func upcomingEvents(
        from date: Date,
        limit: Int = 3,
        includeSolarTerms: Bool = true
    ) -> [CalendarUpcomingEvent] {
        let start = gregorian.startOfDay(for: date)
        let end = gregorian.date(byAdding: .day, value: 370, to: start) ?? start
        var candidates: [CalendarEventCandidate] = []
        candidates.reserveCapacity(includeSolarTerms ? 96 : 48)

        appendPublicHolidayEvents(from: start, through: end, into: &candidates)
        appendSolarFestivalEvents(from: start, through: end, into: &candidates)
        if includeSolarTerms {
            appendSolarTermEvents(from: start, through: end, into: &candidates)
        }

        let unique = candidates
            .filter { $0.date >= start && $0.date <= end }
            .sorted {
                if !gregorian.isDate($0.date, inSameDayAs: $1.date) {
                    return $0.date < $1.date
                }
                return $0.priority < $1.priority
            }
            .reduce(into: [CalendarEventCandidate]()) { result, candidate in
                let alreadyIncluded = result.contains {
                    $0.title == candidate.title && gregorian.isDate($0.date, inSameDayAs: candidate.date)
                }
                if !alreadyIncluded {
                    result.append(candidate)
                }
            }
            .prefix(limit)

        return unique.map { item in
            let days = gregorian.dateComponents([.day], from: start, to: item.date).day ?? 0
            return CalendarUpcomingEvent(
                id: "\(dateKey(item.date))-\(item.title)",
                title: item.title,
                date: item.date,
                daysUntil: days,
                dateLabel: item.dateLabel
            )
        }
    }

    static func monthSlots(for month: Date) -> [CalendarMonthSlot] {
        monthSlots(for: month, showSolarTerms: true)
    }

    static func monthSlots(for month: Date, showSolarTerms: Bool) -> [CalendarMonthSlot] {
        let firstOfMonth = gregorian.date(from: gregorian.dateComponents([.year, .month], from: month))!
        let daysInMonth = gregorian.range(of: .day, in: .month, for: firstOfMonth)!.count
        let leading = positiveModulo(gregorian.component(.weekday, from: firstOfMonth) + 5, 7)
        let monthKey = dateKey(firstOfMonth)
        let monthNumber = gregorian.component(.month, from: firstOfMonth)

        var slots: [CalendarMonthSlot] = []
        slots.reserveCapacity(leading + daysInMonth)

        for index in 0..<leading {
            slots.append(CalendarMonthSlot.empty(monthKey: monthKey, index: index))
        }

        for day in 1...daysInMonth {
            let date = gregorian.date(byAdding: .day, value: day - 1, to: firstOfMonth)!
            let weekday = gregorian.component(.weekday, from: date)
            let metadata = dayCellMetadata(for: date, showSolarTerms: showSolarTerms)
            slots.append(
                .day(
                    date,
                    key: dateKey(date),
                    monthNumber: monthNumber,
                    dayNumber: day,
                    isWeekend: weekday == 1 || weekday == 7,
                    subtitles: metadata.subtitles,
                    hasAnnotation: metadata.hasAnnotation,
                    badge: metadata.badge
                )
            )
        }

        return slots
    }

    static func monthGrid(for month: Date) -> [CalendarGridDay] {
        let firstOfMonth = gregorian.date(from: gregorian.dateComponents([.year, .month], from: month))!
        let daysInMonth = gregorian.range(of: .day, in: .month, for: firstOfMonth)!.count
        let leading = gregorian.component(.weekday, from: firstOfMonth) - 1

        var days: [CalendarGridDay] = []

        if leading > 0 {
            let prevMonth = gregorian.date(byAdding: .month, value: -1, to: firstOfMonth)!
            let prevDays = gregorian.range(of: .day, in: .month, for: prevMonth)!.count
            for offset in (prevDays - leading + 1)...prevDays {
                let date = gregorian.date(byAdding: .day, value: offset - 1, to: prevMonth)!
                days.append(CalendarGridDay(date: date, isInDisplayedMonth: false))
            }
        }

        for day in 1...daysInMonth {
            let date = gregorian.date(byAdding: .day, value: day - 1, to: firstOfMonth)!
            days.append(CalendarGridDay(date: date, isInDisplayedMonth: true))
        }

        let trailing = (7 - (days.count % 7)) % 7
        if trailing > 0 {
            let nextMonth = gregorian.date(byAdding: .month, value: 1, to: firstOfMonth)!
            for day in 0..<trailing {
                let date = gregorian.date(byAdding: .day, value: day, to: nextMonth)!
                days.append(CalendarGridDay(date: date, isInDisplayedMonth: false))
            }
        }

        return days
    }

    private static func lunarDayLabel(for date: Date) -> String {
        lunarDayName(chinese.component(.day, from: date))
    }

    private static func lunarDayName(_ day: Int) -> String {
        switch day {
        case 1...10:
            return "初" + digitNames[day - 1]
        case 11...19:
            return "十" + digitNames[day - 11]
        case 20:
            return "二十"
        case 21...29:
            return "廿" + digitNames[day - 21]
        case 30:
            return "三十"
        default:
            return ""
        }
    }

    private static func isSolarHoliday(_ name: String) -> Bool {
        ["元旦", "劳动节", "国庆", "清明", "端午", "中秋", "春节", "除夕"].contains(where: name.contains)
    }

    private static func sexagenaryMonthLabel(for date: Date) -> String {
        let year = gregorian.component(.year, from: date)
        let lichun = dateOfSolarTerm("立春", in: year) ?? gregorian.date(from: DateComponents(year: year, month: 2, day: 4))!
        let solarYear = date < lichun ? year - 1 : year
        let branchIndex = solarMonthBranchIndex(for: date, in: year)
        let yinStemIndex = yinMonthStemIndex(forYearStem: positiveModulo(solarYear - 4, 10))
        let monthOffset = positiveModulo(branchIndex - 2, 12)
        let stemIndex = positiveModulo(yinStemIndex + monthOffset, 10)
        return heavenlyStems[stemIndex] + earthlyBranches[branchIndex]
    }

    private static func sexagenaryDayLabel(for date: Date) -> String {
        let anchor = gregorian.date(from: DateComponents(year: 2026, month: 5, day: 29))!
        let days = gregorian.dateComponents(
            [.day],
            from: gregorian.startOfDay(for: anchor),
            to: gregorian.startOfDay(for: date)
        ).day ?? 0
        let index = positiveModulo(39 + days, 60)
        return heavenlyStems[index % 10] + earthlyBranches[index % 12]
    }

    private static func solarMonthBranchIndex(for date: Date, in year: Int) -> Int {
        let boundaries: [(term: String, branchIndex: Int)] = [
            ("小寒", 1),
            ("立春", 2),
            ("惊蛰", 3),
            ("清明", 4),
            ("立夏", 5),
            ("芒种", 6),
            ("小暑", 7),
            ("立秋", 8),
            ("白露", 9),
            ("寒露", 10),
            ("立冬", 11),
            ("大雪", 0),
        ]

        return boundaries.reduce(0) { current, boundary in
            guard let boundaryDate = dateOfSolarTerm(boundary.term, in: year), date >= boundaryDate else {
                return current
            }
            return boundary.branchIndex
        }
    }

    private static func yinMonthStemIndex(forYearStem yearStem: Int) -> Int {
        switch yearStem {
        case 0, 5: return 2
        case 1, 6: return 4
        case 2, 7: return 6
        case 3, 8: return 8
        default: return 0
        }
    }

    private static func dateOfSolarTerm(_ term: String, in year: Int) -> Date? {
        SolarTermSupport.date(of: term, in: year)
    }

    private static func appendPublicHolidayEvents(
        from start: Date,
        through end: Date,
        into candidates: inout [CalendarEventCandidate]
    ) {
        for event in publicHolidayEvents where event.date >= start && event.date <= end {
            candidates.append(event)
        }
    }

    private static func appendSolarFestivalEvents(
        from start: Date,
        through end: Date,
        into candidates: inout [CalendarEventCandidate]
    ) {
        let startYear = gregorian.component(.year, from: start)
        let endYear = gregorian.component(.year, from: end)

        for year in startYear...endYear {
            for template in solarFestivalTemplates {
                guard let date = gregorian.date(from: DateComponents(year: year, month: template.month, day: template.day)) else {
                    continue
                }
                guard date >= start && date <= end else { continue }

                candidates.append(CalendarEventCandidate(
                    date: date,
                    title: template.eventTitle,
                    dateLabel: gregorianDateLabel(for: date),
                    priority: 1
                ))
            }

            for event in dynamicSolarFestivals(in: year) {
                guard event.date >= start && event.date <= end else { continue }

                candidates.append(CalendarEventCandidate(
                    date: event.date,
                    title: event.eventTitle,
                    dateLabel: gregorianDateLabel(for: event.date),
                    priority: 1
                ))
            }
        }
    }

    private static func appendSolarTermEvents(
        from start: Date,
        through end: Date,
        into candidates: inout [CalendarEventCandidate]
    ) {
        let startYear = gregorian.component(.year, from: start)
        let endYear = gregorian.component(.year, from: end)

        for year in startYear...endYear {
            for term in SolarTermSupport.terms(in: year) where term.date >= start && term.date <= end {
                candidates.append(CalendarEventCandidate(
                    date: term.date,
                    title: term.name,
                    dateLabel: lunarDateLabel(for: term.date),
                    priority: 2
                ))
            }
        }
    }

    private static func solarFestival(for date: Date) -> (cellTitle: String, eventTitle: String)? {
        let month = gregorian.component(.month, from: date)
        let day = gregorian.component(.day, from: date)
        if let template = solarFestivalLookup[monthDayKey(month: month, day: day)] {
            return template
        }

        let year = gregorian.component(.year, from: date)
        return dynamicSolarFestivals(in: year).first {
            gregorian.isDate($0.date, inSameDayAs: date)
        }.map {
            ($0.cellTitle, $0.eventTitle)
        }
    }

    private static func dynamicSolarFestivals(
        in year: Int
    ) -> [(date: Date, cellTitle: String, eventTitle: String)] {
        var result: [(date: Date, cellTitle: String, eventTitle: String)] = []
        if let mother = nthWeekdayDate(year: year, month: 5, weekday: 1, ordinal: 2) {
            result.append((mother, "母亲节", "母亲节"))
        }
        if let father = nthWeekdayDate(year: year, month: 6, weekday: 1, ordinal: 3) {
            result.append((father, "父亲节", "父亲节"))
        }
        return result
    }

    private static func nthWeekdayDate(year: Int, month: Int, weekday: Int, ordinal: Int) -> Date? {
        guard let firstOfMonth = gregorian.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return nil
        }
        let firstWeekday = gregorian.component(.weekday, from: firstOfMonth)
        let offset = positiveModulo(weekday - firstWeekday, 7) + (ordinal - 1) * 7
        return gregorian.date(byAdding: .day, value: offset, to: firstOfMonth)
    }

    private static func isFirstAnnotatedHoliday(_ date: Date, subtitle: String) -> Bool {
        guard let previousDate = gregorian.date(byAdding: .day, value: -1, to: date) else {
            return true
        }
        let previous = annotations[dateKey(previousDate)]
        return previous?.badge != .rest || previous?.subtitle != subtitle
    }

    private static func gregorianDateLabel(for date: Date) -> String {
        "\(gregorian.component(.month, from: date))月\(gregorian.component(.day, from: date))日 | \(weekdayLabel(for: date))"
    }

    private static func lunarDateLabel(for date: Date) -> String {
        "\(lunarMonthDayLabel(for: date)) | \(weekdayLabel(for: date))"
    }

    private static func weekdayLabel(for date: Date) -> String {
        let labels = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let index = gregorian.component(.weekday, from: date) - 1
        return labels[safe: index] ?? ""
    }

    private static func festivalDisplayName(_ subtitle: String) -> String {
        switch subtitle {
        case "国庆": return "国庆节"
        case "端午": return "端午节"
        case "中秋": return "中秋节"
        case "清明": return "清明节"
        case "劳动": return "劳动节"
        default:
            return subtitle.hasSuffix("节") ? subtitle : subtitle + "节"
        }
    }

    private static func storedAnnotation(for date: Date) -> DayAnnotation? {
        annotations[dateKey(date)]
    }

    private static func date(fromKey key: String) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else {
            return nil
        }
        return gregorian.date(from: DateComponents(year: year, month: month, day: day))
    }

    private static func dateKey(_ date: Date) -> String {
        let components = gregorian.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return "\(year)-\(twoDigit(month))-\(twoDigit(day))"
    }

    private static func monthDayKey(month: Int, day: Int) -> String {
        "\(twoDigit(month))-\(twoDigit(day))"
    }

    private static func twoDigit(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }

    private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}

struct CalendarGridDay: Identifiable {
    let date: Date
    let isInDisplayedMonth: Bool

    var id: Date { date }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
