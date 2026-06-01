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
}
