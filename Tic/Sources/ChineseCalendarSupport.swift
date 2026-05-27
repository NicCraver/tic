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

    private static let upcomingFestivals: [(month: Int, day: Int, name: String)] = [
        (1, 1, "元旦"),
        (2, 14, "情人节"),
        (5, 1, "劳动节"),
        (6, 1, "儿童节"),
        (6, 19, "端午节"),
        (10, 1, "国庆节"),
        (12, 25, "圣诞节"),
    ]

    static func annotation(for date: Date) -> DayAnnotation {
        let key = dateKey(date)
        if let stored = annotations[key] {
            return stored
        }
        if let festival = solarFestivalName(for: date) {
            return DayAnnotation(subtitle: festival, badge: nil)
        }
        return DayAnnotation(subtitle: lunarDayLabel(for: date), badge: nil)
    }

    static func cellSubtitle(for date: Date, showSolarTerms: Bool = true) -> String {
        let ann = annotation(for: date)
        if let subtitle = ann.subtitle, ann.badge != nil || isSolarHoliday(subtitle) {
            return subtitle
        }
        if showSolarTerms, let term = SolarTermSupport.name(for: date) {
            return term
        }
        if let festival = solarFestivalName(for: date) {
            return festival
        }
        return lunarDayLabel(for: date)
    }

    static func solarTermName(for date: Date) -> String? {
        SolarTermSupport.name(for: date)
    }

    static func hasAnnotation(for date: Date) -> Bool {
        let ann = annotation(for: date)
        if ann.badge != nil { return true }
        if let subtitle = ann.subtitle, isSolarHoliday(subtitle) { return true }
        if SolarTermSupport.hasTerm(on: date) { return true }
        if solarFestivalName(for: date) != nil { return true }
        return false
    }

    static func badge(for date: Date) -> DayBadge? {
        annotation(for: date).badge
    }

    static func lunarMonthDayLabel(for date: Date) -> String {
        let month = chinese.component(.month, from: date)
        let day = chinese.component(.day, from: date)
        let monthName = lunarMonthNames[safe: month - 1] ?? "\(month)月"
        return monthName + lunarDayName(day)
    }

    static func lunarYearLabel(for date: Date) -> String {
        let year = gregorian.component(.year, from: date)
        let stem = heavenlyStems[(year - 4) % 10]
        let branch = earthlyBranches[(year - 4) % 12]
        let animal = zodiacAnimals[(year - 4) % 12]
        return "\(stem)\(branch)\(animal)年"
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
        let start = gregorian.startOfDay(for: date)
        let year = gregorian.component(.year, from: date)

        var candidates: [(Date, String)] = []
        for festival in upcomingFestivals {
            var comps = DateComponents(year: year, month: festival.month, day: festival.day)
            guard var festivalDate = gregorian.date(from: comps) else { continue }
            if festivalDate < start {
                comps.year = year + 1
                festivalDate = gregorian.date(from: comps) ?? festivalDate
            }
            let name = festival.name
            candidates.append((festivalDate, name))
        }

        for (key, ann) in annotations {
            guard ann.badge == .rest, let subtitle = ann.subtitle else { continue }
            let parts = key.split(separator: "-")
            guard parts.count == 3,
                  let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]),
                  var festivalDate = gregorian.date(from: DateComponents(year: y, month: m, day: d))
            else { continue }
            if festivalDate < start {
                festivalDate = gregorian.date(from: DateComponents(year: y + 1, month: m, day: d)) ?? festivalDate
            }
            let display = festivalDisplayName(subtitle)
            if !candidates.contains(where: { $0.1 == display && gregorian.isDate($0.0, inSameDayAs: festivalDate) }) {
                candidates.append((festivalDate, display))
            }
        }

        guard let nearest = candidates.min(by: { $0.0 < $1.0 }) else { return nil }
        let days = gregorian.dateComponents([.day], from: start, to: nearest.0).day ?? 0
        guard days >= 0 else { return nil }
        return (nearest.1, days)
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

    private static func solarFestivalName(for date: Date) -> String? {
        let month = gregorian.component(.month, from: date)
        let day = gregorian.component(.day, from: date)
        switch (month, day) {
        case (3, 8): return "妇女节"
        case (5, 4): return "青年节"
        case (8, 1): return "建军节"
        case (9, 10): return "教师节"
        case (12, 24): return "平安夜"
        case (12, 25): return "圣诞节"
        default: return nil
        }
    }

    private static func isSolarHoliday(_ name: String) -> Bool {
        ["元旦", "劳动节", "国庆", "清明", "端午", "中秋", "春节", "除夕"].contains(where: name.contains)
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

    private static func dateKey(_ date: Date) -> String {
        let y = gregorian.component(.year, from: date)
        let m = gregorian.component(.month, from: date)
        let d = gregorian.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
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
