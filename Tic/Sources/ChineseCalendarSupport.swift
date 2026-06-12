import Foundation
import LunarSwift

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

    /// 农历、节气、调休均以北京时间（东八区）为「当天」边界，与 LunarSwift / holiday-cn 一致。
    private static let beijingTimeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current

    private static let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = beijingTimeZone
        // 与月历网格一致：周一为每周第一天（zh_CN 默认周日为首，此处显式对齐）。
        calendar.firstWeekday = 2
        return calendar
    }()
    private static let chinese: Calendar = {
        var calendar = Calendar(identifier: .chinese)
        calendar.timeZone = beijingTimeZone
        return calendar
    }()

    private static let heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    private static let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    private static let zodiacAnimals = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
    private static let lunarMonthNames = [
        "正月", "二月", "三月", "四月", "五月", "六月",
        "七月", "八月", "九月", "十月", "冬月", "腊月",
    ]
    private static let digitNames = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

    // 法定节假日 / 调休（休/班）来自 `HolidayStore` 内置打包 JSON，不再内置硬编码表。


    private static let solarFestivalTemplates: [(month: Int, day: Int, cellTitle: String, eventTitle: String)] = [
        (1, 1, "元旦", "元旦"),
        (2, 14, "情人节", "情人节"),
        (3, 8, "妇女节", "妇女节"),
        (5, 1, "劳动节", "劳动节"),
        (5, 4, "青年节", "青年节"),
        (5, 8, "微笑日", "世界微笑日"),
        (5, 12, "护士节", "护士节"),
        (5, 18, "博物馆日", "国际博物馆日"),
        (5, 21, "国际茶日", "国际茶日"),
        (6, 1, "儿童节", "儿童节"),
        (6, 5, "环境日", "世界环境日"),
        (8, 1, "建军节", "建军节"),
        (9, 10, "教师节", "教师节"),
        (10, 1, "国庆节", "国庆节"),
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

    /// 农历传统节日（农历月, 农历日, 月历格短名, 事件名）；除夕单独按「次日为正月初一」判定。
    private static let lunarFestivalTemplates: [(month: Int, day: Int, cellTitle: String, eventTitle: String)] = [
        (1, 1, "春节", "春节"),
        (1, 15, "元宵", "元宵节"),
        (2, 2, "龙抬头", "龙抬头"),
        (5, 5, "端午", "端午节"),
        (7, 7, "七夕", "七夕"),
        (7, 15, "中元", "中元节"),
        (8, 15, "中秋", "中秋节"),
        (9, 9, "重阳", "重阳节"),
        (12, 8, "腊八", "腊八节"),
        (12, 23, "小年", "小年"),
    ]

    static func annotation(for date: Date) -> DayAnnotation {
        if let stored = storedAnnotation(for: date) {
            return stored
        }
        if let festival = solarFestival(for: date)?.cellTitle {
            return DayAnnotation(subtitle: festival, badge: nil)
        }
        if let festival = lunarFestival(for: date)?.cellTitle {
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
        let lunarFest = lunarFestival(for: date)

        if let term = solarTerm {
            subtitles.append(term)
        }
        if let festival = festival?.cellTitle {
            subtitles.append(festival)
        }
        if let lunarFest = lunarFest?.cellTitle {
            subtitles.append(lunarFest)
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
            || lunarFest != nil

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
        if lunarFestival(for: date) != nil { return true }
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

    /// 距下一法定休首日（HolidayStore 中 badge 为「休」的首日）的天数；今天已是休假日则跳过当前连休。
    static func nextRestDayCountdown(from date: Date) -> (name: String, days: Int)? {
        let start = gregorian.startOfDay(for: date)
        for offset in 0..<370 {
            guard let candidate = gregorian.date(byAdding: .day, value: offset, to: start),
                  let stored = storedAnnotation(for: candidate),
                  stored.badge == .rest,
                  let name = stored.subtitle,
                  isFirstAnnotatedHoliday(candidate, subtitle: name)
            else { continue }
            if offset > 0 {
                return (name, offset)
            }
        }
        return nil
    }

    static func nextRestDayCountdownLabel(from date: Date) -> String? {
        guard let next = nextRestDayCountdown(from: date) else { return nil }
        return "\(next.name) \(festivalCountdownLabel(days: next.days))"
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

        appendSolarFestivalEvents(from: start, through: end, into: &candidates)
        appendLunarFestivalEvents(from: start, through: end, into: &candidates)
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
        let leading = mondayBasedLeadingBlankCount(
            weekdayOfFirst: gregorian.component(.weekday, from: firstOfMonth)
        )
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
        let day = gregorian.startOfDay(for: date)
        let year = gregorian.component(.year, from: day)
        let month = gregorian.component(.month, from: day)
        let dayOfMonth = gregorian.component(.day, from: day)
        return Solar.fromYmdHms(year: year, month: month, day: dayOfMonth).lunar.dayInGanZhi
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

    private static func appendLunarFestivalEvents(
        from start: Date,
        through end: Date,
        into candidates: inout [CalendarEventCandidate]
    ) {
        var date = start
        while date <= end {
            if let festival = lunarFestival(for: date) {
                candidates.append(CalendarEventCandidate(
                    date: date,
                    title: festival.eventTitle,
                    dateLabel: lunarDateLabel(for: date),
                    priority: 1
                ))
            }
            guard let next = gregorian.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
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

    private static func lunarFestival(for date: Date) -> (cellTitle: String, eventTitle: String)? {
        if isLunarNewYearEve(date) {
            return ("除夕", "除夕")
        }
        let components = chinese.dateComponents([.month, .day], from: date)
        guard components.isLeapMonth != true,
              let month = components.month,
              let day = components.day,
              let template = lunarFestivalTemplates.first(where: { $0.month == month && $0.day == day })
        else {
            return nil
        }
        return (template.cellTitle, template.eventTitle)
    }

    /// 除夕 = 次日为正月初一（腊月最后一日，廿九或三十均可）。
    private static func isLunarNewYearEve(_ date: Date) -> Bool {
        guard let next = gregorian.date(byAdding: .day, value: 1, to: date) else { return false }
        let components = chinese.dateComponents([.month, .day], from: next)
        return components.isLeapMonth != true && components.month == 1 && components.day == 1
    }

    /// 法定连休仅首日显示节日名；向前最多 14 天跳过数据缺口，避免缺前一天条目时重复显示。
    private static func isFirstAnnotatedHoliday(_ date: Date, subtitle: String) -> Bool {
        var cursor = date
        for _ in 0..<14 {
            guard let previousDate = gregorian.date(byAdding: .day, value: -1, to: cursor) else {
                return true
            }
            cursor = previousDate
            guard let previous = HolidayStore.shared.annotation(forKey: dateKey(previousDate)) else {
                continue
            }
            if previous.badge == .rest && previous.subtitle == subtitle {
                return false
            }
            return true
        }
        return true
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

    private static func storedAnnotation(for date: Date) -> DayAnnotation? {
        HolidayStore.shared.annotation(forKey: dateKey(date))
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

    /// 月历网格周一为首列：`weekday` 为 `Calendar` 标准（1=周日 … 7=周六）。
    private static func mondayBasedLeadingBlankCount(weekdayOfFirst: Int) -> Int {
        positiveModulo(weekdayOfFirst + 5, 7)
    }

    private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
