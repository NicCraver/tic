import AppKit
import SwiftUI

extension Notification.Name {
    static let menuBarSettingsDidChange = Notification.Name("menuBarSettingsDidChange")
}

private extension Font {
    static var menuBarLabel: Font {
        Font(MenuBarDisplayComposer.labelFont())
    }
}

/// `MenuBarExtra` 只可靠地显示 `Image` / `Text`；用 `ImageRenderer` 生成固定宽度位图避免抖动。
struct MenuBarDateLabel: View {
    @AppStorage(AppSettings.showSecondsKey) private var showSeconds = true
    @AppStorage(AppSettings.use24HourKey) private var use24Hour = true
    @State private var now = Date.now
    @State private var settingsRevision = 0
    @State private var labelImage: NSImage?

    private var blockOrder: [MenuBarBlock] {
        _ = settingsRevision
        return AppSettings.loadBlockOrder()
    }

    private var enabledBlocks: Set<MenuBarBlock> {
        _ = settingsRevision
        return AppSettings.loadEnabledBlocks()
    }

    private var updateInterval: TimeInterval {
        enabledBlocks.contains(.time) && showSeconds ? 1 : 60
    }

    private var metrics: MenuBarLabelMetrics {
        _ = settingsRevision
        _ = showSeconds
        _ = use24Hour
        return MenuBarLabelMetrics.current(date: now)
    }

    var body: some View {
        Group {
            if let labelImage {
                Image(nsImage: labelImage)
                    .renderingMode(.template)
                    .accessibilityLabel(metrics.displayText)
            } else {
                Text(metrics.displayText)
                    .font(.menuBarLabel)
                    .monospacedDigit()
            }
        }
        .frame(width: metrics.labelWidth, height: 22)
        .fixedSize(horizontal: true, vertical: true)
        .onAppear { renderLabelImage() }
        .onChange(of: settingsRevision) { _, _ in renderLabelImage() }
        .task(id: updateInterval) {
            while !Task.isCancelled {
                now = .now
                renderLabelImage()
                try? await Task.sleep(for: .seconds(updateInterval))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .menuBarSettingsDidChange)) { _ in
            settingsRevision += 1
        }
        .onReceive(
            DistributedNotificationCenter.default().publisher(
                for: Notification.Name("AppleInterfaceThemeChangedNotification")
            )
        ) { _ in
            renderLabelImage()
        }
    }

    @MainActor
    private func renderLabelImage() {
        let snapshot = metrics
        let renderer = ImageRenderer(
            content: MenuBarRenderedLabel(metrics: snapshot)
        )
        renderer.proposedSize = ProposedViewSize(width: snapshot.labelWidth, height: 22)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        renderer.isOpaque = false

        guard let image = renderer.nsImage else { return }
        image.isTemplate = true
        labelImage = image
    }
}

/// 模板图须为黑字 + 透明底，由系统按菜单栏/壁纸着色。
private enum MenuBarTemplateStyle {
    static let foreground = Color.black
}

private struct MenuBarRenderedLabel: View {
    let metrics: MenuBarLabelMetrics

    var body: some View {
        HStack(spacing: MenuBarDisplayComposer.iconTextSpacing) {
            if metrics.showsIcon {
                Image(systemName: "calendar.circle.fill")
                    .font(.menuBarLabel)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(MenuBarTemplateStyle.foreground)
            }
            Text(metrics.displayText)
                .font(.menuBarLabel)
                .monospacedDigit()
                .foregroundStyle(MenuBarTemplateStyle.foreground)
                .lineLimit(1)
                .frame(width: metrics.textSlotWidth, alignment: .center)
        }
        .frame(width: metrics.labelWidth, height: 22)
    }
}
