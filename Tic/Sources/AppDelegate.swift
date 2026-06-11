import AppKit
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "me.nic.tic", category: "AppDelegate")
    private var configuredPopoverWindows = Set<ObjectIdentifier>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Tic 已启动")
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

        let windowID = ObjectIdentifier(window)
        guard !configuredPopoverWindows.contains(windowID) else { return }
        configuredPopoverWindows.insert(windowID)

        window.contentView?.focusRingType = .none
        if let contentView = window.contentView {
            disableFocusRing(in: contentView)
        }

        MenuBarPopoverWindowAnchor.shared.beginObserving(window)
        MenuBarPopoverWindowAnchor.shared.refreshAnchor(for: window)

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.configuredPopoverWindows.remove(windowID)
        }
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
