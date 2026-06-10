import AppKit

/// 菜单栏弹窗高度随内容变化时，保持窗口顶边（靠近菜单栏一侧）位置不变。
@MainActor
final class MenuBarPopoverWindowAnchor: NSObject {
    static let shared = MenuBarPopoverWindowAnchor()

    private var anchoredTopByWindow: [ObjectIdentifier: CGFloat] = [:]
    private var observedWindows: Set<ObjectIdentifier> = []

    func beginObserving(_ window: NSWindow) {
        let id = ObjectIdentifier(window)
        guard !observedWindows.contains(id) else { return }
        observedWindows.insert(id)
        anchoredTopByWindow[id] = windowTop(for: window)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize(_:)),
            name: NSWindow.didResizeNotification,
            object: window
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: window
        )
    }

    func refreshAnchor(for window: NSWindow) {
        let id = ObjectIdentifier(window)
        anchoredTopByWindow[id] = windowTop(for: window)
        preserveTopAnchor(for: window)
    }

    @objc private func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        preserveTopAnchor(for: window)
    }

    @objc private func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        let id = ObjectIdentifier(window)
        anchoredTopByWindow.removeValue(forKey: id)
        observedWindows.remove(id)
        NotificationCenter.default.removeObserver(self, name: nil, object: window)
    }

    private func preserveTopAnchor(for window: NSWindow) {
        let id = ObjectIdentifier(window)
        guard let anchoredTop = anchoredTopByWindow[id] else { return }

        var frame = window.frame
        let targetOriginY = anchoredTop - frame.height
        guard abs(frame.origin.y - targetOriginY) > 0.5 else { return }

        frame.origin.y = targetOriginY
        window.setFrame(frame, display: true, animate: false)
    }

    private func windowTop(for window: NSWindow) -> CGFloat {
        window.frame.origin.y + window.frame.height
    }
}
