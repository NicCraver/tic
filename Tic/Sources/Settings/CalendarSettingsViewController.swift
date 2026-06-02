import AppKit

@MainActor
final class CalendarSettingsViewController: SettingsPaneViewController {
    private let dotsSwitch = NSSwitch()
    private let termsSwitch = NSSwitch()
    private let holidaysSwitch = NSSwitch()

    init() { super.init(title: "日历") }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func makeContent() -> [NSView] {
        dotsSwitch.state = AppSettings.bool(forKey: AppSettings.showAnnotationDotsKey, default: true) ? .on : .off
        dotsSwitch.target = self
        dotsSwitch.action = #selector(dotsChanged)

        termsSwitch.state = AppSettings.bool(forKey: AppSettings.showSolarTermsKey, default: true) ? .on : .off
        termsSwitch.target = self
        termsSwitch.action = #selector(termsChanged)

        holidaysSwitch.state = AppSettings.bool(forKey: AppSettings.autoUpdateHolidaysKey, default: true) ? .on : .off
        holidaysSwitch.target = self
        holidaysSwitch.action = #selector(holidaysChanged)

        let dotsRow = makeSettingsRow(
            title: "显示标注圆点",
            subtitle: "节假日、节气等有标注的日期在月历格底部显示圆点",
            control: dotsSwitch
        )
        let termsRow = makeSettingsRow(
            title: "显示节气",
            subtitle: "月历副标题与详情中显示节气名称（如立夏）",
            control: termsSwitch
        )
        let holidaysRow = makeSettingsRow(
            title: "自动更新节假日数据",
            subtitle: "联网获取国务院公布的放假/调休（开源项目 holiday-cn），仅下载公开文件、不上传任何信息；关闭则只用内置数据",
            control: holidaysSwitch
        )
        return [makeSettingsGroupedCard([dotsRow, termsRow, holidaysRow])]
    }

    @objc private func dotsChanged() {
        AppSettings.setBool(dotsSwitch.state == .on, forKey: AppSettings.showAnnotationDotsKey)
    }

    @objc private func termsChanged() {
        AppSettings.setBool(termsSwitch.state == .on, forKey: AppSettings.showSolarTermsKey)
    }

    @objc private func holidaysChanged() {
        let enabled = holidaysSwitch.state == .on
        AppSettings.setBool(enabled, forKey: AppSettings.autoUpdateHolidaysKey)
        if enabled {
            HolidayStore.shared.refreshIfNeeded()
        }
    }
}
