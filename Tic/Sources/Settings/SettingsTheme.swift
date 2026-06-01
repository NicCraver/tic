import CoreGraphics

enum SettingsTheme {
    static let windowWidth: CGFloat = 700
    static let windowHeight: CGFloat = 480
    static let contentMaxWidth: CGFloat = 460

    /// 侧栏列宽（最长项为四字，如「快捷键」，配合系统图标留白）
    static let sidebarWidth: CGFloat = 168

    /// 详情区内边距（与系统设置相近）
    static let panePadding: CGFloat = 28
    /// 大标题与首张卡片间距
    static let titleToContentSpacing: CGFloat = 24
    /// 卡片与卡片间距
    static let cardSpacing: CGFloat = 12
    /// 页脚（如退出按钮）与上方内容间距
    static let footerTopSpacing: CGFloat = 32
}
