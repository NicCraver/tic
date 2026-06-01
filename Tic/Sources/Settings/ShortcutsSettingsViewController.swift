import AppKit

@MainActor
final class ShortcutsSettingsViewController: SettingsPaneViewController {
    init() { super.init(title: "快捷键") }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func makeContent() -> [NSView] {
        let rows = [
            shortcutRow("← →", "前一天 / 后一天"),
            shortcutRow("↑ ↓", "上一周 / 下一周"),
            shortcutRow("⌥ ← →", "上一月 / 下一月"),
            shortcutRow("⌘ ,", "打开设置"),
        ]
        return [makeSettingsGroupedCard(rows)]
    }

    override func makeFooter() -> NSView? {
        makeSettingsFootnote("全局打开日历快捷键将在后续版本提供。")
    }

    private func shortcutRow(_ keys: String, _ action: String) -> NSView {
        let keysLabel = NSTextField(labelWithString: keys)
        keysLabel.font = .monospacedSystemFont(ofSize: 13, weight: .medium)

        let actionLabel = NSTextField(labelWithString: action)
        actionLabel.font = .systemFont(ofSize: 13)
        actionLabel.textColor = .secondaryLabelColor

        return makeSettingsRow(leading: keysLabel, trailing: actionLabel)
    }
}
