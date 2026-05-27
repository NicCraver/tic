import XCTest
@testable import Tic

final class TicTests: XCTestCase {
    func testMenuBarBlocksAreUnique() {
        let blocks = MenuBarBlock.allCases.map(\.rawValue)
        XCTAssertEqual(Set(blocks).count, blocks.count)
    }

    func testSolarTermOnLixia2026() {
        var components = DateComponents(year: 2026, month: 5, day: 5)
        let date = Calendar(identifier: .gregorian).date(from: components)!
        XCTAssertEqual(SolarTermSupport.name(for: date), "立夏")
    }

    func testWeekOfYearUsesChineseLocale() {
        var components = DateComponents(year: 2026, month: 5, day: 27)
        let date = Calendar(identifier: .gregorian).date(from: components)!
        XCTAssertEqual(ChineseCalendarSupport.weekOfYear(for: date), 21)
    }
}
