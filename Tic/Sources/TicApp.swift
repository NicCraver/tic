import SwiftUI

@main
struct TicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            CalendarPopoverView()
                .frame(width: CalendarPopoverLayout.width)
                .fixedSize(horizontal: false, vertical: true)
        } label: {
            MenuBarDateLabel()
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("设置…") {
                    SettingsWindowManager.show()
                }
                .keyboardShortcut(",", modifiers: .command)

                Button("检查更新…") {
                    NotificationCenter.default.post(name: .checkForUpdates, object: nil)
                }
            }
        }
    }
}
