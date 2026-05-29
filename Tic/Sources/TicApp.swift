import SwiftUI

@main
struct TicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            CalendarPopoverView()
                .frame(width: 397)
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
            }
        }
    }
}
