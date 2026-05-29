import Foundation

/// 二十四节气（2025–2027 公历日期，用于月历副标题与标注圆点）
enum SolarTermSupport {
    private static let gregorian = Calendar(identifier: .gregorian)
    private static let table: [String: String] = buildTable()
    private static let termDates: [String: Date] = buildTermDates()
    private static let termsByYear: [Int: [(date: Date, name: String)]] = buildTermsByYear()

    static func name(for date: Date) -> String? {
        table[dateKey(date)]
    }

    static func hasTerm(on date: Date) -> Bool {
        name(for: date) != nil
    }

    static func date(of term: String, in year: Int) -> Date? {
        termDates["\(year)-\(term)"]
    }

    static func terms(in year: Int) -> [(date: Date, name: String)] {
        termsByYear[year] ?? []
    }

    private static func dateKey(_ date: Date) -> String {
        let y = gregorian.component(.year, from: date)
        let m = gregorian.component(.month, from: date)
        let d = gregorian.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
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

    private static func buildTermDates() -> [String: Date] {
        table.reduce(into: [:]) { result, entry in
            guard let date = date(fromKey: entry.key) else { return }
            let year = gregorian.component(.year, from: date)
            result["\(year)-\(entry.value)"] = date
        }
    }

    private static func buildTermsByYear() -> [Int: [(date: Date, name: String)]] {
        let grouped = table.reduce(into: [Int: [(date: Date, name: String)]]()) { result, entry in
            guard let date = date(fromKey: entry.key) else { return }
            let year = gregorian.component(.year, from: date)
            result[year, default: []].append((date: date, name: entry.value))
        }

        return grouped.mapValues { terms in
            terms.sorted { $0.date < $1.date }
        }
    }

    private static func buildTable() -> [String: String] {
        var result: [String: String] = [:]
        for year in 2025...2027 {
            merge(year: year, month: 1, day: 5, term: "小寒", into: &result)
            merge(year: year, month: 1, day: 20, term: "大寒", into: &result)
            merge(year: year, month: 2, day: 4, term: "立春", into: &result)
            merge(year: year, month: 2, day: 19, term: "雨水", into: &result)
            merge(year: year, month: 3, day: 5, term: "惊蛰", into: &result)
            merge(year: year, month: 3, day: 20, term: "春分", into: &result)
            merge(year: year, month: 4, day: 4, term: "清明", into: &result)
            merge(year: year, month: 4, day: 20, term: "谷雨", into: &result)
            merge(year: year, month: 5, day: 5, term: "立夏", into: &result)
            merge(year: year, month: 5, day: 21, term: "小满", into: &result)
            merge(year: year, month: 6, day: 5, term: "芒种", into: &result)
            merge(year: year, month: 6, day: 21, term: "夏至", into: &result)
            merge(year: year, month: 7, day: 7, term: "小暑", into: &result)
            merge(year: year, month: 7, day: 23, term: "大暑", into: &result)
            merge(year: year, month: 8, day: 7, term: "立秋", into: &result)
            merge(year: year, month: 8, day: 23, term: "处暑", into: &result)
            merge(year: year, month: 9, day: 7, term: "白露", into: &result)
            merge(year: year, month: 9, day: 23, term: "秋分", into: &result)
            merge(year: year, month: 10, day: 8, term: "寒露", into: &result)
            merge(year: year, month: 10, day: 23, term: "霜降", into: &result)
            merge(year: year, month: 11, day: 7, term: "立冬", into: &result)
            merge(year: year, month: 11, day: 22, term: "小雪", into: &result)
            merge(year: year, month: 12, day: 7, term: "大雪", into: &result)
            merge(year: year, month: 12, day: 21, term: "冬至", into: &result)
        }
        // 微调至常见历法（与国务院农历网大致一致）
        applyCorrections(&result)
        return result
    }

    private static func merge(year: Int, month: Int, day: Int, term: String, into result: inout [String: String]) {
        let key = String(format: "%04d-%02d-%02d", year, month, day)
        result[key] = term
    }

    private static func applyCorrections(_ result: inout [String: String]) {
        let patches: [String: String] = [
            "2025-01-05": "小寒", "2025-01-20": "大寒", "2025-02-03": "立春", "2025-02-18": "雨水",
            "2025-03-05": "惊蛰", "2025-03-20": "春分", "2025-04-04": "清明", "2025-04-20": "谷雨",
            "2025-05-05": "立夏", "2025-05-21": "小满", "2025-06-05": "芒种", "2025-06-21": "夏至",
            "2025-07-07": "小暑", "2025-07-22": "大暑", "2025-08-07": "立秋", "2025-08-23": "处暑",
            "2025-09-07": "白露", "2025-09-23": "秋分", "2025-10-08": "寒露", "2025-10-23": "霜降",
            "2025-11-07": "立冬", "2025-11-22": "小雪", "2025-12-07": "大雪", "2025-12-21": "冬至",
            "2026-01-05": "小寒", "2026-01-20": "大寒", "2026-02-04": "立春", "2026-02-18": "雨水",
            "2026-03-05": "惊蛰", "2026-03-20": "春分", "2026-04-05": "清明", "2026-04-20": "谷雨",
            "2026-05-05": "立夏", "2026-05-21": "小满", "2026-06-05": "芒种", "2026-06-21": "夏至",
            "2026-07-07": "小暑", "2026-07-23": "大暑", "2026-08-07": "立秋", "2026-08-23": "处暑",
            "2026-09-07": "白露", "2026-09-23": "秋分", "2026-10-08": "寒露", "2026-10-23": "霜降",
            "2026-11-07": "立冬", "2026-11-22": "小雪", "2026-12-07": "大雪", "2026-12-22": "冬至",
            "2027-01-05": "小寒", "2027-01-20": "大寒", "2027-02-04": "立春", "2027-02-19": "雨水",
            "2027-03-06": "惊蛰", "2027-03-21": "春分", "2027-04-05": "清明", "2027-04-20": "谷雨",
            "2027-05-06": "立夏", "2027-05-21": "小满", "2027-06-06": "芒种", "2027-06-21": "夏至",
            "2027-07-07": "小暑", "2027-07-23": "大暑", "2027-08-08": "立秋", "2027-08-23": "处暑",
            "2027-09-08": "白露", "2027-09-23": "秋分", "2027-10-08": "寒露", "2027-10-23": "霜降",
            "2027-11-07": "立冬", "2027-11-22": "小雪", "2027-12-07": "大雪", "2027-12-22": "冬至",
        ]
        for (key, value) in patches {
            let yearPrefix = String(key.prefix(4)) + "-"
            let staleKeys = result.keys.filter {
                $0.hasPrefix(yearPrefix) && result[$0] == value
            }
            for existingKey in staleKeys {
                result.removeValue(forKey: existingKey)
            }
            result[key] = value
        }
    }
}
