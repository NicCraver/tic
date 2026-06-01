import AppKit

@MainActor
enum SettingsWindowManager {
    private static var window: NSWindow?

    static func show() {
        NSApp.activate(ignoringOtherApps: true)

        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: SettingsTheme.windowWidth, height: SettingsTheme.windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.contentViewController = SettingsSplitViewController()
        newWindow.title = "Tic 设置"
        newWindow.isReleasedWhenClosed = false

        SettingsWindowChrome.apply(to: newWindow)
        newWindow.center()
        newWindow.makeKeyAndOrderFront(nil)

        window = newWindow
    }
}
