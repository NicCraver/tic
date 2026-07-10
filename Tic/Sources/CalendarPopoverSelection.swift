import Foundation

/// 日历弹窗的选中日 / 展示月。`MenuBarExtra` 的 window 会保留 `@State`，
/// 关闭后再打开时需显式重置为「今天」，否则会残留上次选中的日期。
struct CalendarPopoverSelection: Equatable {
    var selectedDate: Date
    var displayedMonth: Date

    static func today(now: Date = .now, calendar: Calendar = .gregorianChineseLocale) -> Self {
        let day = calendar.startOfDay(for: now)
        return Self(selectedDate: day, displayedMonth: day)
    }
}

extension Calendar {
    static var gregorianChineseLocale: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        return calendar
    }
}
