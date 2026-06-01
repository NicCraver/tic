import AppKit

@MainActor
final class AppearanceSettingsViewController: SettingsPaneViewController {
    private let themePopup = NSPopUpButton()

    init() { super.init(title: "外观") }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func makeContent() -> [NSView] {
        for theme in AppTheme.allCases {
            themePopup.addItem(withTitle: theme.title)
        }
        let current = UserDefaults.standard.string(forKey: AppSettings.appThemeKey) ?? AppTheme.system.rawValue
        if let index = AppTheme.allCases.firstIndex(where: { $0.rawValue == current }) {
            themePopup.selectItem(at: index)
        }
        themePopup.target = self
        themePopup.action = #selector(themeChanged)
        return [SettingsGroup(row: makeSettingsRow(title: "主题", control: themePopup))]
    }

    @objc private func themeChanged() {
        let index = themePopup.indexOfSelectedItem
        guard AppTheme.allCases.indices.contains(index) else { return }
        UserDefaults.standard.set(AppTheme.allCases[index].rawValue, forKey: AppSettings.appThemeKey)
        NotificationCenter.default.post(name: .appThemeDidChange, object: nil)
    }
}
