import AppKit

/// 配置设置窗口为系统设置式全高侧栏（交通灯叠在侧栏材质上）。
/// 全高布局由 `SettingsSplitViewController` 的 sidebar item `allowsFullHeightLayout`
/// 配合此处的透明标题栏 + `sidebarTrackingSeparator` toolbar 共同实现。
@MainActor
enum SettingsWindowChrome {
    static func apply(to window: NSWindow) {
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = true
        window.toolbarStyle = .unified

        lockWindowSize(window)
        installTrackingSeparatorToolbar(on: window)
        disableAuxiliaryWindowButtons(in: window)

        DispatchQueue.main.async {
            disableAuxiliaryWindowButtons(in: window)
        }
    }

    /// 固定尺寸窗口：最小化 / 最大化按钮保留交通灯占位，但禁用交互（与系统设置一致）。
    static func disableAuxiliaryWindowButtons(in window: NSWindow) {
        window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
        window.standardWindowButton(.zoomButton)?.isEnabled = false
    }

    static func lockWindowSize(_ window: NSWindow) {
        let size = NSSize(width: SettingsTheme.windowWidth, height: SettingsTheme.windowHeight)
        window.minSize = size
        window.maxSize = size
        window.setContentSize(size)
    }

    private static func installTrackingSeparatorToolbar(on window: NSWindow) {
        let identifier = NSToolbar.Identifier("TicSettingsToolbar")
        if window.toolbar?.identifier == identifier { return }

        let toolbar = NSToolbar(identifier: identifier)
        toolbar.displayMode = .iconOnly
        toolbar.showsBaselineSeparator = false
        toolbar.allowsUserCustomization = false
        toolbar.delegate = SettingsToolbarDelegate.shared
        window.toolbar = toolbar
    }
}

@MainActor
private final class SettingsToolbarDelegate: NSObject, NSToolbarDelegate {
    static let shared = SettingsToolbarDelegate()

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.sidebarTrackingSeparator, .flexibleSpace]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        guard itemIdentifier == .sidebarTrackingSeparator else { return nil }
        return NSToolbarItem(itemIdentifier: .sidebarTrackingSeparator)
    }
}
