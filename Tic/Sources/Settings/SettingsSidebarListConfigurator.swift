import AppKit
import SwiftUI

/// 侧栏 `List` 的 AppKit 层：关闭系统选区高亮，配合 SwiftUI 大圆角 `listRowBackground`。
struct SettingsSidebarListConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.isHidden = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let tableView = findSidebarTableView(startingAt: nsView) else { return }
            tableView.style = .sourceList
            tableView.selectionHighlightStyle = .none
            tableView.backgroundColor = .clear
            tableView.intercellSpacing = NSSize(width: 0, height: SettingsTheme.sidebarRowSpacing)
        }
    }

    private func findSidebarTableView(startingAt anchor: NSView) -> NSTableView? {
        var node: NSView? = anchor
        while let current = node {
            if let tableView = current as? NSTableView { return tableView }
            if let tableView = findTableView(in: current) { return tableView }
            node = current.superview
        }
        guard let root = anchor.window?.contentView else { return nil }
        var tableViews: [NSTableView] = []
        collectTableViews(in: root, into: &tableViews)
        let targetWidth = SettingsTheme.sidebarWidth
        return tableViews.min { lhs, rhs in
            abs(lhs.bounds.width - targetWidth) < abs(rhs.bounds.width - targetWidth)
        }
    }

    private func findTableView(in view: NSView?) -> NSTableView? {
        guard let view else { return nil }
        if let tableView = view as? NSTableView { return tableView }
        for subview in view.subviews {
            if let found = findTableView(in: subview) { return found }
        }
        return nil
    }

    private func collectTableViews(in view: NSView, into result: inout [NSTableView]) {
        if let tableView = view as? NSTableView {
            result.append(tableView)
        }
        for subview in view.subviews {
            collectTableViews(in: subview, into: &result)
        }
    }
}
