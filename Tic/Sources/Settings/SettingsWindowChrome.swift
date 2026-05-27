import AppKit
import SwiftUI

/// 配置设置窗口为系统设置式全高侧栏（交通灯叠在侧栏材质上）。
@MainActor
enum SettingsWindowChrome {
    static func apply<Content: View>(to window: NSWindow, hosting: NSHostingController<Content>) {
        window.styleMask.insert(.fullSizeContentView)
        disableAuxiliaryWindowButtons(in: window)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = true
        window.toolbarStyle = .unified

        hosting.safeAreaRegions = []

        lockWindowSize(window)

        installTrackingSeparatorToolbar(on: window)
        configureFullHeightSplitItems(in: window)

        DispatchQueue.main.async {
            disableAuxiliaryWindowButtons(in: window)
        }
    }

    /// 固定设置窗口尺寸，禁止用户拖拽改变宽高。
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

    static func configureFullHeightSplitItems(in window: NSWindow) {
        guard let splitViewController = findSplitViewController(in: window.contentView) else { return }
        for item in splitViewController.splitViewItems {
            item.allowsFullHeightLayout = true
        }
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

    private static func findSplitViewController(in view: NSView?) -> NSSplitViewController? {
        guard let view else { return nil }
        if let controller = view.nextResponder as? NSSplitViewController {
            return controller
        }
        if let controller = view.window?.contentViewController as? NSSplitViewController {
            return controller
        }
        for subview in view.subviews {
            if let found = findSplitViewController(in: subview) {
                return found
            }
        }
        return nil
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
