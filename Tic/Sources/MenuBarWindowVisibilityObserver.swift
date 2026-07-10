import AppKit
import SwiftUI

/// 观察 `MenuBarExtra` 宿主窗口的可见性：从隐藏到显示时回调。
/// 打开月份选择器不会隐藏主窗，因此不会误触发。
struct MenuBarWindowVisibilityObserver: NSViewRepresentable {
    var onBecomeVisible: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = ObserverView()
        context.coordinator.bind(view: view, onBecomeVisible: onBecomeVisible)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? ObserverView else { return }
        context.coordinator.bind(view: view, onBecomeVisible: onBecomeVisible)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.detach()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class ObserverView: NSView {
        var onWindowChanged: ((NSWindow?) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            onWindowChanged?(window)
        }
    }

    @MainActor
    final class Coordinator {
        var onBecomeVisible: (() -> Void)?
        private weak var observedWindow: NSWindow?
        private var wasVisible = false
        private var observations: [NSObjectProtocol] = []

        func bind(view: ObserverView, onBecomeVisible: @escaping () -> Void) {
            self.onBecomeVisible = onBecomeVisible
            view.onWindowChanged = { [weak self] window in
                Task { @MainActor in
                    guard let self else { return }
                    if let window {
                        self.observe(window)
                    } else {
                        self.detach()
                    }
                }
            }
            if let window = view.window {
                observe(window)
            }
        }

        func detach() {
            for observation in observations {
                NotificationCenter.default.removeObserver(observation)
            }
            observations.removeAll()
            observedWindow = nil
            wasVisible = false
        }

        private func observe(_ window: NSWindow) {
            if observedWindow === window { return }
            detach()
            observedWindow = window
            wasVisible = window.isVisible

            let center = NotificationCenter.default
            let names: [Notification.Name] = [
                NSWindow.didBecomeKeyNotification,
                NSWindow.didExposeNotification,
                NSWindow.didResignKeyNotification,
            ]
            for name in names {
                observations.append(center.addObserver(
                    forName: name,
                    object: window,
                    queue: .main
                ) { [weak self] _ in
                    Task { @MainActor in
                        self?.handleVisibilityChange()
                    }
                })
            }
            observations.append(center.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.wasVisible = false
                }
            })

            handleVisibilityChange()
        }

        private func handleVisibilityChange() {
            guard let window = observedWindow else { return }
            let visible = window.isVisible
            defer { wasVisible = visible }
            guard visible, !wasVisible else { return }
            onBecomeVisible?()
        }
    }
}
