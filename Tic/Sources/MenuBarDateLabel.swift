import SwiftUI

extension Notification.Name {
    static let menuBarSettingsDidChange = Notification.Name("menuBarSettingsDidChange")
}

struct MenuBarDateLabel: View {
    @AppStorage(AppSettings.showSecondsKey) private var showSeconds = true
    @AppStorage(AppSettings.use24HourKey) private var use24Hour = true
    @State private var now = Date.now
    @State private var settingsRevision = 0

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

    private var showsIcon: Bool {
        MenuBarDisplayComposer.showsIcon(order: blockOrder, enabled: enabledBlocks)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            if showsIcon {
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 12))
            }
            Text(displayText)
                .monospacedDigit()
                .font(.system(size: 12))
        }
        .frame(height: 22)
        .task(id: updateInterval) {
            while !Task.isCancelled {
                now = .now
                try? await Task.sleep(for: .seconds(updateInterval))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .menuBarSettingsDidChange)) { _ in
            settingsRevision += 1
        }
    }

    private var displayText: String {
        let text = MenuBarDisplayComposer.compose(
            date: now,
            order: blockOrder,
            enabled: enabledBlocks,
            showSeconds: showSeconds,
            use24Hour: use24Hour
        )
        return text.isEmpty ? "Tic" : text
    }
}
