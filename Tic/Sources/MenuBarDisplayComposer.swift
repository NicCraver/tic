import AppKit
import Foundation

enum MenuBarDisplayComposer {
    static let menuBarIconWidth: CGFloat = 16
    static let iconTextSpacing: CGFloat = 4
    /// 菜单栏标签左右内边距（仅计入 `NSStatusItem.length`）。
    static let labelHorizontalInset: CGFloat = 0
    /// 菜单栏标签字重（系统菜单栏默认为 Regular，此处略加重便于阅读）。
    static let labelFontWeight: NSFont.Weight = .medium

    static var menuBarLabelPointSize: CGFloat {
        NSFont.menuBarFont(ofSize: 0).pointSize
    }

    static func labelFont() -> NSFont {
        NSFont.systemFont(ofSize: menuBarLabelPointSize, weight: labelFontWeight)
    }

    static func labelDigitFont() -> NSFont {
        NSFont.monospacedDigitSystemFont(ofSize: menuBarLabelPointSize, weight: labelFontWeight)
    }

    /// 与 SwiftUI `menuBarLabel` + `monospacedDigit()` 对齐的占位宽度。
    static func reservedTextWidth(for text: String) -> CGFloat {
        let labelFont = labelFont()
        let digitFont = labelDigitFont()
        let textWidth = (text as NSString).size(withAttributes: [.font: labelFont]).width
        let digitWidth = (text as NSString).size(withAttributes: [.font: digitFont]).width
        return ceil(max(textWidth, digitWidth))
    }

    /// 将数字替换为 `8`，占位最宽数字字形（配合等宽数字体测量）。
    static func wideningDigits(in text: String) -> String {
        String(text.map { $0.isNumber ? "8" : $0 })
    }

    /// 全 `8` 占位串，供定宽位图量宽。
    static func sizingText(
        order: [MenuBarBlock],
        enabled: Set<MenuBarBlock>,
        showSeconds: Bool,
        use24Hour: Bool
    ) -> String {
        let text = widestCompose(
            order: order,
            enabled: enabled,
            showSeconds: showSeconds,
            use24Hour: use24Hour
        )
        let base = text.isEmpty ? "Tic" : text
        return wideningDigits(in: base)
    }

    private static let widestReferenceDate: Date = {
        var components = DateComponents()
        components.year = 2023
        components.month = 12
        components.day = 31
        components.hour = 23
        components.minute = 59
        components.second = 59
        return Calendar.current.date(from: components)!
    }()

    private static let twelveHourWideDate: Date = {
        var components = DateComponents()
        components.year = 2023
        components.month = 12
        components.day = 31
        components.hour = 12
        components.minute = 59
        components.second = 59
        return Calendar.current.date(from: components)!
    }()
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

    /// 占位最宽文案，避免菜单栏标签随秒数等变化产生宽度抖动。
    static func widestCompose(
        order: [MenuBarBlock],
        enabled: Set<MenuBarBlock>,
        showSeconds: Bool,
        use24Hour: Bool
    ) -> String {
        order
            .filter { enabled.contains($0) && $0 != .icon }
            .compactMap { widestSegment(for: $0, showSeconds: showSeconds, use24Hour: use24Hour) }
            .joined(separator: " ")
    }

    private static func widestSegment(
        for block: MenuBarBlock,
        showSeconds: Bool,
        use24Hour: Bool
    ) -> String? {
        switch block {
        case .icon:
            return nil
        case .date:
            return "12月31日"
        case .weekday:
            return "周三"
        case .weekNumber:
            return "(53)"
        case .lunar:
            return "十一月三十"
        case .time:
            let pattern: String
            if use24Hour {
                pattern = showSeconds ? "HH:mm:ss" : "HH:mm"
            } else {
                pattern = showSeconds ? "h:mm:ss a" : "h:mm a"
            }
            let candidates = use24Hour
                ? [widestReferenceDate]
                : [widestReferenceDate, twelveHourWideDate]
            return candidates
                .map { format($0, pattern: pattern) }
                .max(by: { reservedTextWidth(for: $0) < reservedTextWidth(for: $1) })!
        }
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
