import SwiftUI

struct ShortcutsSettingsPane: View {
    var body: some View {
        SettingsPaneScaffold(title: "快捷键") {
            Form {
                Section {
                    shortcutRow("← →", "前一天 / 后一天")
                    shortcutRow("↑ ↓", "上一周 / 下一周")
                    shortcutRow("⌥ ← →", "上一月 / 下一月")
                    shortcutRow("⌘ ,", "打开设置")
                }
            }
            .formStyle(.grouped)
        } footer: {
            SettingsFootnote(text: "全局打开日历快捷键将在后续版本提供。")
        }
    }

    private func shortcutRow(_ keys: String, _ action: String) -> some View {
        LabeledContent {
            Text(action)
                .foregroundStyle(.secondary)
        } label: {
            Text(keys)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
        }
    }
}
