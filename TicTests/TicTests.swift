import XCTest
@testable import Tic

final class TicTests: XCTestCase {
    func testDateFormatStylesAreUnique() {
        let styles = DateFormatStyle.allCases.map(\.rawValue)
        XCTAssertEqual(Set(styles).count, styles.count)
    }
}
