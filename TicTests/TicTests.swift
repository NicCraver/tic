import XCTest
@testable import Tic

final class TicTests: XCTestCase {
    func testMenuBarBlocksAreUnique() {
        let blocks = MenuBarBlock.allCases.map(\.rawValue)
        XCTAssertEqual(Set(blocks).count, blocks.count)
    }

    func testSolarTermOnLixia2026() {
        XCTAssertEqual(SolarTermSupport.name(for: gregorianDate(2026, 5, 5)), "立夏")
    }

    func testSexagenaryDayFromLunarSwift() {
        // 日柱改由 LunarSwift 计算（原锚点 2026-05-29 = 癸卯）
        let meta = ChineseCalendarSupport.lunarDetailMeta(for: gregorianDate(2026, 5, 29))
        XCTAssertTrue(meta.contains("癸卯日"), "日柱应为癸卯，实际：\(meta)")
    }

    func testSolarTermsCanBeReadByYear() {
        for year in 2025...2027 {
            let terms = SolarTermSupport.terms(in: year)
            XCTAssertEqual(terms.count, 24)
            XCTAssertEqual(terms.first?.name, "小寒")
            XCTAssertEqual(terms.last?.name, "冬至")
        }
    }

    func testWeekOfYearUsesChineseLocale() {
        XCTAssertEqual(ChineseCalendarSupport.weekOfYear(for: gregorianDate(2026, 5, 27)), 21)
    }

    // MARK: - 农历节日（本地推算）

    private func gregorianDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func testLunarFestivalLanternFestival2026() {
        // 正月十五（元宵）= 2026-03-03，非法定假日，应由农历推算得到
        XCTAssertEqual(ChineseCalendarSupport.cellSubtitle(for: gregorianDate(2026, 3, 3)), "元宵")
    }

    func testLunarNewYearEve2026() {
        // 除夕 = 2026-02-16（次日为正月初一），应优先于法定「春节」名显示
        XCTAssertEqual(ChineseCalendarSupport.cellSubtitle(for: gregorianDate(2026, 2, 16)), "除夕")
    }

    // MARK: - 法定节假日（HolidayStore 打包数据）

    func testBundledHolidayRestDay() {
        XCTAssertEqual(ChineseCalendarSupport.badge(for: gregorianDate(2026, 10, 1)), .rest)
    }

    func testBundledHolidayWorkDay() {
        XCTAssertEqual(ChineseCalendarSupport.badge(for: gregorianDate(2026, 2, 28)), .work)
    }

    func testNextRestDayCountdownFromWorkDay() {
        let result = ChineseCalendarSupport.nextRestDayCountdown(from: gregorianDate(2026, 6, 2))
        XCTAssertEqual(result?.name, "端午节")
        XCTAssertEqual(result?.days, 17)
        XCTAssertEqual(
            ChineseCalendarSupport.nextRestDayCountdownLabel(from: gregorianDate(2026, 6, 2)),
            "端午节 17天后"
        )
    }

    func testNextRestDayCountdownEve() {
        XCTAssertEqual(ChineseCalendarSupport.nextRestDayCountdown(from: gregorianDate(2026, 6, 18))?.days, 1)
    }

    func testNextRestDayCountdownSkipsCurrentRestPeriod() {
        XCTAssertNil(ChineseCalendarSupport.nextRestDayCountdown(from: gregorianDate(2026, 10, 3)))
    }

    // MARK: - 边界与一致性

    func testLeapMonthPrefixInLunarLabel() {
        // 2023 闰二月初一 ≈ 公历 2023-03-22
        XCTAssertTrue(
            ChineseCalendarSupport.lunarMonthDayLabel(for: gregorianDate(2023, 3, 22)).hasPrefix("闰")
        )
    }

    func testSolarTermsInDistantYear() {
        XCTAssertEqual(SolarTermSupport.terms(in: 2030).count, 24)
    }

    func testLunarFestivalWorksInDistantYear() {
        // 2030 年正月初一由农历推算，不依赖调休 JSON
        XCTAssertEqual(ChineseCalendarSupport.cellSubtitle(for: gregorianDate(2030, 2, 3)), "春节")
    }

    func testMonthSlotsUseMondayAsFirstColumn() {
        // 2026-01-01 周四 → 周一首列前应空 3 格
        let slots = ChineseCalendarSupport.monthSlots(for: gregorianDate(2026, 1, 1))
        let firstDayIndex = slots.firstIndex { $0.dayNumber == 1 }
        XCTAssertEqual(firstDayIndex, 3)
    }

    func testNationalDaySubtitleOnlyOnFirstRestDay() {
        let oct1 = ChineseCalendarSupport.cellSubtitles(for: gregorianDate(2026, 10, 1))
        let oct2 = ChineseCalendarSupport.cellSubtitles(for: gregorianDate(2026, 10, 2))
        XCTAssertTrue(oct1.contains("国庆节"))
        XCTAssertFalse(oct2.contains("国庆节"))
    }

    // MARK: - 版本比较（检查更新）

    func testUpdateServiceComparesSemVer() {
        let service = UpdateService()
        XCTAssertTrue(service.isNewer(latest: "1.3.0", current: "1.2.6"))
        XCTAssertFalse(service.isNewer(latest: "1.2.6", current: "1.2.6"))
        XCTAssertFalse(service.isNewer(latest: "1.2.5", current: "1.2.6"))
        XCTAssertTrue(service.isNewer(latest: "1.2.10", current: "1.2.9"))
    }

    func testUpdateServiceStripsVersionPrefix() {
        let service = UpdateService()
        XCTAssertEqual(service.stripVersionPrefix("v1.2.4"), "1.2.4")
        XCTAssertEqual(service.stripVersionPrefix("1.2.4"), "1.2.4")
    }

    func testUpdateServiceParsesFullRelease() throws {
        let json = Data("""
        {"tag_name":"v1.3.0","name":"Tic 1.3.0","body":"修复若干问题",\
        "html_url":"https://github.com/NicCraver/tic/releases/tag/v1.3.0",\
        "published_at":"2026-06-10T08:00:00Z"}
        """.utf8)
        let release = try UpdateService().parseRelease(data: json)
        XCTAssertEqual(release.tagName, "v1.3.0")
        XCTAssertEqual(release.name, "Tic 1.3.0")
        XCTAssertEqual(release.body, "修复若干问题")
        XCTAssertEqual(release.htmlURL.absoluteString, "https://github.com/NicCraver/tic/releases/tag/v1.3.0")
        XCTAssertNotNil(release.publishedAt)
    }

    func testUpdateServiceParseFallsBackWhenOptionalFieldsMissing() throws {
        // 缺 name / body / published_at：name 回退 tag_name，body 为空串，publishedAt 为 nil
        let json = Data(#"{"tag_name":"v1.2.7","html_url":"https://github.com/NicCraver/tic/releases/tag/v1.2.7"}"#.utf8)
        let release = try UpdateService().parseRelease(data: json)
        XCTAssertEqual(release.name, "v1.2.7")
        XCTAssertEqual(release.body, "")
        XCTAssertNil(release.publishedAt)
    }

    func testUpdateServiceParseThrowsWhenTagMissing() {
        let json = Data(#"{"html_url":"https://github.com/NicCraver/tic/releases"}"#.utf8)
        XCTAssertThrowsError(try UpdateService().parseRelease(data: json)) { error in
            guard case UpdateError.parseError = error else {
                return XCTFail("期望 parseError，实际：\(error)")
            }
        }
    }

    func testUpdateServiceResponseSizeLimit() {
        let service = UpdateService()
        let small = Data(count: 1024)
        let huge = Data(count: 600 * 1024)
        XCTAssertTrue(service.isWithinLimit(contentLength: 1024, data: small))
        XCTAssertTrue(service.isWithinLimit(contentLength: nil, data: small))
        XCTAssertFalse(service.isWithinLimit(contentLength: nil, data: huge))          // 实际体积超限
        XCTAssertFalse(service.isWithinLimit(contentLength: 600 * 1024, data: small))  // 声明长度超限
    }

    // MARK: - 更新下载安全策略

    func testTrustedReleaseAssetURLAcceptsOfficialDMG() {
        let url = URL(string: "https://github.com/NicCraver/tic/releases/download/v1.2.4/Tic-v1.2.4-macOS.dmg")!
        XCTAssertTrue(TrustedDownloadPolicy.isTrustedReleaseAssetURL(url, expectedVersion: "1.2.4"))
    }

    func testTrustedReleaseAssetURLRejectsWrongVersion() {
        let url = URL(string: "https://github.com/NicCraver/tic/releases/download/v1.2.4/Tic-v9.9.9-macOS.dmg")!
        XCTAssertFalse(TrustedDownloadPolicy.isTrustedReleaseAssetURL(url, expectedVersion: "1.2.4"))
    }

    func testTrustedReleaseAssetURLRejectsForeignHost() {
        let url = URL(string: "https://evil.example.com/NicCraver/tic/releases/download/v1.2.4/Tic-v1.2.4-macOS.dmg")!
        XCTAssertFalse(TrustedDownloadPolicy.isTrustedReleaseAssetURL(url, expectedVersion: "1.2.4"))
    }

    func testTrustedReleaseAssetURLAcceptsGitHubCDNRedirect() {
        let url = URL(string: "https://release-assets.githubusercontent.com/github-production-release-asset/1252199363/abc?response-content-disposition=attachment%3B%20filename%3DTic-v1.2.5-macOS.dmg")!
        XCTAssertTrue(TrustedDownloadPolicy.isTrustedReleaseAssetURL(url, expectedVersion: "1.2.5"))
    }

    func testSafeDestinationURLRejectsPathTraversal() {
        let downloads = FileManager.default.temporaryDirectory
        XCTAssertNil(TrustedDownloadPolicy.safeDestinationURL(filename: "../Tic-v1.0.0-macOS.dmg", in: downloads))
        XCTAssertNil(TrustedDownloadPolicy.safeDestinationURL(filename: "foo/bar.dmg", in: downloads))
    }

    // MARK: - 菜单栏文案拼装（MenuBarDisplayComposer）

    func testMenuBarWideningDigitsReplacesNumbersOnly() {
        // 阿拉伯数字替换为占位最宽字形 8；汉字（月 / 日）与字母原样保留
        XCTAssertEqual(MenuBarDisplayComposer.wideningDigits(in: "12:30"), "88:88")
        XCTAssertEqual(MenuBarDisplayComposer.wideningDigits(in: "5月27日"), "8月88日")
        XCTAssertEqual(MenuBarDisplayComposer.wideningDigits(in: "AM"), "AM")
    }

    func testMenuBarShowsIconRequiresOrderAndEnabled() {
        XCTAssertTrue(MenuBarDisplayComposer.showsIcon(order: [.icon, .time], enabled: [.icon, .time]))
        XCTAssertFalse(MenuBarDisplayComposer.showsIcon(order: [.icon, .time], enabled: [.time]))
        XCTAssertFalse(MenuBarDisplayComposer.showsIcon(order: [.time], enabled: [.icon, .time]))
    }

    func testMenuBarComposeJoinsEnabledBlocksInOrder() {
        let date = middayDate(2026, 5, 27)  // 周三
        XCTAssertEqual(
            MenuBarDisplayComposer.compose(
                date: date,
                order: [.date, .weekday, .time],
                enabled: [.date, .weekday],
                showSeconds: false,
                use24Hour: true
            ),
            "5月27日 周三"  // time 未启用，不出现
        )
        XCTAssertEqual(
            MenuBarDisplayComposer.compose(
                date: date,
                order: [.date, .time],
                enabled: [.date, .time],
                showSeconds: false,
                use24Hour: true
            ),
            "5月27日 12:00"
        )
    }

    func testMenuBarComposeExcludesIconBlock() {
        let date = middayDate(2026, 5, 27)
        XCTAssertEqual(
            MenuBarDisplayComposer.compose(
                date: date,
                order: [.icon, .date],
                enabled: [.icon, .date],
                showSeconds: false,
                use24Hour: true
            ),
            "5月27日"  // icon 不计入文本
        )
    }

    // MARK: - HolidayStore 覆盖年份

    func testHolidayStoreReportsBundledCoverage() {
        XCTAssertEqual(HolidayStore.shared.maxCoveredYear, 2026)
        XCTAssertFalse(HolidayStore.shared.isYearUncovered(2026))
        XCTAssertTrue(HolidayStore.shared.isYearUncovered(2027))
        XCTAssertTrue(HolidayStore.shared.isYearUncovered(2023))
    }

    /// 系统时区当地中午，避免 `DateFormatter`（默认系统时区）在 UTC CI 上跨日。
    private func middayDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
}
