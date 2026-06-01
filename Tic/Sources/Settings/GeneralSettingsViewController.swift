import AppKit

@MainActor
final class GeneralSettingsViewController: SettingsPaneViewController {
    private let launchSwitch = NSSwitch()

    init() { super.init(title: "通用") }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func makeContent() -> [NSView] {
        launchSwitch.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
        launchSwitch.target = self
        launchSwitch.action = #selector(toggleLaunchAtLogin)
        let row = makeSettingsRow(title: "登录时启动", control: launchSwitch)
        return [SettingsGroup(row: row)]
    }

    override func makeFooter() -> NSView? {
        SettingsDestructiveButton(title: "退出 Tic", target: self, action: #selector(quit))
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLoginManager.shared.setEnabled(launchSwitch.state == .on)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
