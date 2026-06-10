import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Tic 已启动")
        AppSettings.migrateLegacyFormatIfNeeded()
        LaunchAtLoginManager.shared.applyPreferredStateOnLaunch()
        HolidayStore.shared.refreshIfNeeded()
        UpdateChecker.shared.registerForMenuCommands()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            UpdateChecker.shared.checkAutomaticallyIfNeeded()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configurePopoverWindow(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
    }

    @MainActor
    @objc private func configurePopoverWindow(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        guard isMenuBarPopover(window) else { return }

        window.contentView?.focusRingType = .none
        if let contentView = window.contentView {
            disableFocusRing(in: contentView)
        }

        MenuBarPopoverWindowAnchor.shared.beginObserving(window)
        MenuBarPopoverWindowAnchor.shared.refreshAnchor(for: window)
    }

    @MainActor
    private func isMenuBarPopover(_ window: NSWindow) -> Bool {
        let name = String(describing: type(of: window))
        if name.contains("Popover") || name.contains("StatusBar") {
            return true
        }
        return window.level == .popUpMenu && !window.isSheet
    }

    @MainActor
    private func disableFocusRing(in view: NSView) {
        view.focusRingType = .none
        for subview in view.subviews {
            disableFocusRing(in: subview)
        }
    }
}
