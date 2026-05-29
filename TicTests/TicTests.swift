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
}
