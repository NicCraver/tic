import XCTest
@testable import Tic

final class TicTests: XCTestCase {
    func testMenuBarBlocksAreUnique() {
        let blocks = MenuBarBlock.allCases.map(\.rawValue)
        XCTAssertEqual(Set(blocks).count, blocks.count)
    }

    func testSolarTermOnLixia2026() {
        let components = DateComponents(year: 2026, month: 5, day: 5)
        let date = Calendar(identifier: .gregorian).date(from: components)!
        XCTAssertEqual(SolarTermSupport.name(for: date), "立夏")
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
        let components = DateComponents(year: 2026, month: 5, day: 27)
        let date = Calendar(identifier: .gregorian).date(from: components)!
        XCTAssertEqual(ChineseCalendarSupport.weekOfYear(for: date), 21)
    }

    // MARK: - 农历节日（本地推算）

    private func gregorianDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: day))!
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
}
