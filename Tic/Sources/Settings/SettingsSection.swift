import Foundation

enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case general
    case appearance
    case menuBar
    case calendar
    case shortcuts
    case about

    var id: String { rawValue }

    /// 侧栏短标题（控制列宽，详情页标题见各 Pane）
    var sidebarTitle: String {
        switch self {
        case .general: "通用"
        case .appearance: "外观"
        case .menuBar: "菜单栏"
        case .calendar: "日历"
        case .shortcuts: "快捷键"
        case .about: "关于"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintbrush"
        case .menuBar: "menubar.rectangle"
        case .calendar: "calendar"
        case .shortcuts: "command"
        case .about: "info.circle"
        }
    }
}
