import AppKit

/// 菜单栏弹窗高度随内容变化时，保持窗口顶边（靠近菜单栏一侧）位置不变。
///
/// 注意：`MenuBarExtra` 窗口在 `didBecomeKey` 时 frame 可能仍是 `.zero`（尚未被系统摆放），
/// 此时不能记录锚点，否则顶边会被记成 0，之后一次高度变化就会把窗口挪到屏幕外。
/// 因此只在窗口拥有「落在某个屏幕上的非空 frame」时才记录 / 更新锚点，
/// 并在系统首次摆放窗口（纯移动、尺寸不变）时补记锚点。
@MainActor
final class MenuBarPopoverWindowAnchor: NSObject {
    static let shared = MenuBarPopoverWindowAnchor()

    private var anchoredTopByWindow: [ObjectIdentifier: CGFloat] = [:]
    private var lastKnownHeightByWindow: [ObjectIdentifier: CGFloat] = [:]
    private var observedWindows: Set<ObjectIdentifier> = []
    private var isAdjustingFrame = false

    func beginObserving(_ window: NSWindow) {
        let id = ObjectIdentifier(window)
        guard !observedWindows.contains(id) else { return }
        observedWindows.insert(id)
        lastKnownHeightByWindow[id] = window.frame.height
        rememberAnchorIfUsable(window)

        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(windowDidResize(_:)),
            name: NSWindow.didResizeNotification,
            object: window
        )
        center.addObserver(
            self,
            selector: #selector(windowDidMove(_:)),
            name: NSWindow.didMoveNotification,
            object: window
        )
        center.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: window
        )
    }

    func refreshAnchor(for window: NSWindow) {
        rememberAnchorIfUsable(window)
        preserveTopAnchor(for: window)
    }

    /// 当前记录的顶边锚点（测试用）。
    func anchoredTop(for window: NSWindow) -> CGFloat? {
        anchoredTopByWindow[ObjectIdentifier(window)]
    }

    @objc private func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        let id = ObjectIdentifier(window)
        if anchoredTopByWindow[id] == nil {
            // 尚无锚点（如一次 setFrame 同时改了尺寸和位置）：以当前 frame 补记。
            rememberAnchorIfUsable(window)
        } else {
            preserveTopAnchor(for: window)
        }
        lastKnownHeightByWindow[id] = window.frame.height
    }

    /// 系统（而非本类）移动窗口且尺寸未变时，视为重新摆放，更新锚点。
    /// 典型场景：首次显示时 frame 从 `.zero` 变为真实位置。
    @objc private func windowDidMove(_ notification: Notification) {
        guard !isAdjustingFrame, let window = notification.object as? NSWindow else { return }
        let id = ObjectIdentifier(window)
        guard lastKnownHeightByWindow[id] == window.frame.height else { return }
        rememberAnchorIfUsable(window)
    }

    @objc private func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        let id = ObjectIdentifier(window)
        anchoredTopByWindow.removeValue(forKey: id)
        lastKnownHeightByWindow.removeValue(forKey: id)
        observedWindows.remove(id)
        NotificationCenter.default.removeObserver(self, name: nil, object: window)
    }

    private func rememberAnchorIfUsable(_ window: NSWindow) {
        guard Self.hasUsableFrame(window.frame) else { return }
        anchoredTopByWindow[ObjectIdentifier(window)] = windowTop(for: window)
    }

    private func preserveTopAnchor(for window: NSWindow) {
        let id = ObjectIdentifier(window)
        guard let anchoredTop = anchoredTopByWindow[id] else { return }

        var frame = window.frame
        guard !frame.isEmpty else { return }
        let targetOriginY = anchoredTop - frame.height
        guard abs(frame.origin.y - targetOriginY) > 0.5 else { return }

        frame.origin.y = targetOriginY
        // 兜底：绝不把窗口挪到所有屏幕之外。
        guard Self.hasUsableFrame(frame) else { return }

        isAdjustingFrame = true
        defer { isAdjustingFrame = false }
        window.setFrame(frame, display: true, animate: false)
    }

    private func windowTop(for window: NSWindow) -> CGFloat {
        window.frame.origin.y + window.frame.height
    }

    /// 非空且与至少一个屏幕相交，才算是系统已经摆放好的 frame。
    static func hasUsableFrame(_ frame: NSRect) -> Bool {
        guard !frame.isEmpty else { return false }
        return NSScreen.screens.contains { $0.frame.intersects(frame) }
    }
}
