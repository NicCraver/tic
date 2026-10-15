import AppKit
import XCTest
@testable import Tic

@MainActor
final class MenuBarPopoverWindowAnchorTests: XCTestCase {
    private func makeWindow(_ frame: NSRect) -> NSWindow {
        let window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        return window
    }

    /// 取一个落在主屏幕内的基准 frame；无屏幕（无头 CI）时跳过。
    private func onScreenFrame(height: CGFloat) throws -> NSRect {
        let screen = try XCTUnwrap(NSScreen.screens.first, "无可用屏幕")
        let visible = screen.frame
        return NSRect(x: visible.midX - 200, y: visible.midY - height / 2, width: 397, height: height).integral
    }

    func testZeroFrameWindowDoesNotRecordAnchor() {
        let window = makeWindow(.zero)
        let anchor = MenuBarPopoverWindowAnchor.shared
        anchor.beginObserving(window)
        anchor.refreshAnchor(for: window)
        XCTAssertNil(anchor.anchoredTop(for: window))
        window.close()
    }

    func testAnchorIsRecordedOnFirstSystemPlacementAndTopIsPreserved() throws {
        let window = makeWindow(.zero)
        let anchor = MenuBarPopoverWindowAnchor.shared
        anchor.beginObserving(window)
        anchor.refreshAnchor(for: window)

        // 系统先设尺寸再摆位置（真实 MenuBarExtra 的顺序）。
        let placed = try onScreenFrame(height: 752)
        window.setFrame(NSRect(x: 0, y: 0, width: placed.width, height: placed.height), display: false)
        // 随后系统摆放到真实位置（纯移动、尺寸不变）→ 锚点以真实位置为准。
        window.setFrame(placed, display: false)
        XCTAssertEqual(anchor.anchoredTop(for: window), placed.maxY)

        // 以底边为基准缩小高度 → 应被纠正为顶边不变。
        var shrunk = placed
        shrunk.size.height = 735
        window.setFrame(shrunk, display: false)
        XCTAssertEqual(window.frame.maxY, placed.maxY, accuracy: 0.5)
        XCTAssertEqual(window.frame.height, 735, accuracy: 0.5)

        // 恢复高度，顶边依旧不变。
        var restored = window.frame
        restored.size.height = 752
        window.setFrame(restored, display: false)
        XCTAssertEqual(window.frame.maxY, placed.maxY, accuracy: 0.5)
        window.close()
    }

    func testNeverMovesWindowOffAllScreens() throws {
        let window = makeWindow(.zero)
        let anchor = MenuBarPopoverWindowAnchor.shared
        anchor.beginObserving(window)
        let placed = try onScreenFrame(height: 752)
        window.setFrame(placed, display: false)
        XCTAssertEqual(anchor.anchoredTop(for: window), placed.maxY)

        // 高到任何屏幕都放不下，顶边对齐会把窗口推出屏幕外 → 保持原样不动。
        let huge = NSRect(x: placed.minX, y: placed.minY, width: placed.width, height: 100_000)
        window.setFrame(huge, display: false)
        XCTAssertTrue(MenuBarPopoverWindowAnchor.hasUsableFrame(window.frame))
        window.close()
    }
}
