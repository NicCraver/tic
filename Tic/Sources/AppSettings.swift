import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "跟随系统"
        case .light: "浅色"
        case .dark: "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum MenuBarBlock: String, CaseIterable, Identifiable, Codable {
    case icon
    case date
    case weekday
    case weekNumber
    case lunar
    case time

    var id: String { rawValue }

    var title: String {
        switch self {
        case .icon: "图标"
        case .date: "日期"
        case .weekday: "星期"
        case .weekNumber: "周数"
        case .lunar: "农历"
        case .time: "时间"
        }
    }

    var previewSample: String {
        switch self {
        case .icon: "📅"
        case .date: "5月27日"
        case .weekday: "周三"
        case .weekNumber: "(21)"
        case .lunar: "四月十一"
        case .time: "11:09:40"
        }
    }

    static let defaultOrder: [MenuBarBlock] = [.icon, .date, .weekday, .weekNumber, .lunar, .time]
    static let defaultEnabled: Set<MenuBarBlock> = [.date, .time]
}

enum AppSettings {
    static let appThemeKey = "appTheme"
    static let showSecondsKey = "showSeconds"
    static let use24HourKey = "use24Hour"
    static let menuBarBlockOrderKey = "menuBarBlockOrder"
    static let menuBarEnabledBlocksKey = "menuBarEnabledBlocks"
    static let showAnnotationDotsKey = "showAnnotationDots"
    static let showSolarTermsKey = "showSolarTerms"
    static let launchAtLoginKey = "launchAtLogin"
    static let legacyDateFormatStyleKey = "dateFormatStyle"

    static func migrateLegacyFormatIfNeeded() {
        guard UserDefaults.standard.string(forKey: menuBarBlockOrderKey) == nil else { return }

        let legacy = UserDefaults.standard.string(forKey: legacyDateFormatStyleKey) ?? "compact"
        let enabled: Set<MenuBarBlock>
        let order: [MenuBarBlock]

        switch legacy {
        case "timeOnly":
            enabled = [.time]
            order = [.time]
        case "dateOnly":
            enabled = [.date]
            order = [.date]
        default:
            enabled = [.date, .time]
            order = [.date, .time]
        }

        saveBlockOrder(order)
        saveEnabledBlocks(enabled)
    }

    static func loadBlockOrder() -> [MenuBarBlock] {
        guard let raw = UserDefaults.standard.string(forKey: menuBarBlockOrderKey) else {
            return MenuBarBlock.defaultOrder
        }
        let blocks = raw.split(separator: ",").compactMap { MenuBarBlock(rawValue: String($0)) }
        return blocks.isEmpty ? MenuBarBlock.defaultOrder : blocks
    }

    static func saveBlockOrder(_ blocks: [MenuBarBlock]) {
        UserDefaults.standard.set(blocks.map(\.rawValue).joined(separator: ","), forKey: menuBarBlockOrderKey)
    }

    static func loadEnabledBlocks() -> Set<MenuBarBlock> {
        guard let raw = UserDefaults.standard.string(forKey: menuBarEnabledBlocksKey) else {
            return MenuBarBlock.defaultEnabled
        }
        let blocks = Set(raw.split(separator: ",").compactMap { MenuBarBlock(rawValue: String($0)) })
        return blocks.isEmpty ? MenuBarBlock.defaultEnabled : blocks
    }

    static func saveEnabledBlocks(_ blocks: Set<MenuBarBlock>) {
        UserDefaults.standard.set(blocks.map(\.rawValue).sorted().joined(separator: ","), forKey: menuBarEnabledBlocksKey)
    }

    static func resetMenuBarLayout() {
        saveBlockOrder(MenuBarBlock.defaultOrder)
        saveEnabledBlocks(MenuBarBlock.defaultEnabled)
    }

    /// 读取布尔设置；键不存在时返回 `defaultValue`（对齐 `@AppStorage` 的默认值语义）。
    static func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        UserDefaults.standard.object(forKey: key) == nil
            ? defaultValue
            : UserDefaults.standard.bool(forKey: key)
    }

    static func setBool(_ value: Bool, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
