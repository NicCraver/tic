import AppKit
import SwiftUI

@MainActor
enum SettingsWindowManager {
    private static var window: NSWindow?

    static func show() {
        NSApp.activate(ignoringOtherApps: true)

        if let window, let hosting = window.contentViewController as? NSHostingController<SettingsView> {
            SettingsWindowChrome.apply(to: window, hosting: hosting)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let rootView = SettingsView()

        let hosting = NSHostingController(rootView: rootView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: SettingsTheme.windowWidth, height: SettingsTheme.windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.contentViewController = hosting
        newWindow.title = "Tic 设置"
        newWindow.isReleasedWhenClosed = false

        SettingsWindowChrome.apply(to: newWindow, hosting: hosting)
        newWindow.center()
        newWindow.makeKeyAndOrderFront(nil)

        // NSSplitView 在首帧布局后才存在，延迟启用全高侧栏。
        DispatchQueue.main.async {
            SettingsWindowChrome.configureFullHeightSplitItems(in: newWindow)
        }

        window = newWindow
    }
}
