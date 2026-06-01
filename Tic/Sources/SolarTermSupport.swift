import Foundation
import LunarSwift

/// 二十四节气：由 LunarSwift 按天文算法计算，任意年份有效（替代旧的硬编码查表）。
/// 对外 API 与旧实现保持一致，`ChineseCalendarSupport` 无需改动。
enum SolarTermSupport {
    private static let gregorian = Calendar(identifier: .gregorian)

    private static let standardNames: Set<String> = [
        "小寒", "大寒", "立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
        "立夏", "小满", "芒种", "夏至", "小暑", "大暑", "立秋", "处暑",
        "白露", "秋分", "寒露", "霜降", "立冬", "小雪", "大雪", "冬至",
    ]

    /// LunarSwift `jieQiTable` 用英文别名 key 表示相邻周期的交节（如年末「冬至」存于 "DONG_ZHI"）。
    /// 归一回标准中文名后，才能按公历年完整收齐 24 项。
    private static let jieQiAliases: [String: String] = [
        "DA_XUE": "大雪", "DONG_ZHI": "冬至", "XIAO_HAN": "小寒",
        "DA_HAN": "大寒", "LI_CHUN": "立春", "YU_SHUI": "雨水", "JING_ZHE": "惊蛰",
    ]

    private struct YearTerms {
        let byDate: [Date: String]
        let byName: [String: Date]
        let sorted: [(date: Date, name: String)]
    }

    /// 按公历年缓存计算结果（节气计算较重，避免月历每格重复计算）。
    private nonisolated(unsafe) static var cache: [Int: YearTerms] = [:]

    static func name(for date: Date) -> String? {
        terms(forYear: gregorian.component(.year, from: date))
            .byDate[gregorian.startOfDay(for: date)]
    }

    static func hasTerm(on date: Date) -> Bool {
        name(for: date) != nil
    }

    static func date(of term: String, in year: Int) -> Date? {
        terms(forYear: year).byName[term]
    }

    static func terms(in year: Int) -> [(date: Date, name: String)] {
        terms(forYear: year).sorted
    }

    private static func terms(forYear year: Int) -> YearTerms {
        if let cached = cache[year] { return cached }
        let computed = compute(year: year)
        cache[year] = computed
        return computed
    }

    private static func compute(year: Int) -> YearTerms {
        var byDate: [Date: String] = [:]
        var byName: [String: Date] = [:]

        // 年初、年末两个农历实例的节气表合起来覆盖整个公历年；将英文别名 key 归一为标准中文名，
        // 再按目标公历年过滤——否则年末「冬至」只存在于 "DONG_ZHI" 别名下会被漏掉。
        let samples = [
            Solar.fromYmdHms(year: year, month: 1, day: 1).lunar,
            Solar.fromYmdHms(year: year, month: 12, day: 31).lunar,
        ]
        for lunar in samples {
            for (key, solar) in lunar.jieQiTable {
                let name = jieQiAliases[key] ?? key
                guard standardNames.contains(name), solar.year == year else { continue }
                guard let date = gregorian.date(
                    from: DateComponents(year: solar.year, month: solar.month, day: solar.day)
                ) else { continue }
                let day = gregorian.startOfDay(for: date)
                byDate[day] = name
                byName[name] = day
            }
        }

        let sorted = byName
            .map { (date: $0.value, name: $0.key) }
            .sorted { $0.date < $1.date }
        return YearTerms(byDate: byDate, byName: byName, sorted: sorted)
    }
}
