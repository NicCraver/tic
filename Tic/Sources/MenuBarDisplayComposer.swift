import Foundation

enum MenuBarDisplayComposer {
    static func compose(
        date: Date,
        order: [MenuBarBlock],
        enabled: Set<MenuBarBlock>,
        showSeconds: Bool,
        use24Hour: Bool
    ) -> String {
        order
            .filter { enabled.contains($0) && $0 != .icon }
            .compactMap { segment(for: $0, date: date, showSeconds: showSeconds, use24Hour: use24Hour) }
            .joined(separator: " ")
    }

    static func showsIcon(order: [MenuBarBlock], enabled: Set<MenuBarBlock>) -> Bool {
        enabled.contains(.icon) && order.contains(.icon)
    }

    private static func segment(
        for block: MenuBarBlock,
        date: Date,
        showSeconds: Bool,
        use24Hour: Bool
    ) -> String? {
        switch block {
        case .icon:
            return nil
        case .date:
            return format(date, pattern: "M月d日")
        case .weekday:
            return format(date, pattern: "EEE")
        case .weekNumber:
            return "(\(ChineseCalendarSupport.weekOfYear(for: date)))"
        case .lunar:
            return ChineseCalendarSupport.lunarMonthDayLabel(for: date)
        case .time:
            let pattern: String
            if use24Hour {
                pattern = showSeconds ? "HH:mm:ss" : "HH:mm"
            } else {
                pattern = showSeconds ? "h:mm:ss a" : "h:mm a"
            }
            return format(date, pattern: pattern)
        }
    }

    private static func format(_ date: Date, pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}
