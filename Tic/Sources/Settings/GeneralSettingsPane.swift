import SwiftUI

struct GeneralSettingsPane: View {
    @Binding var launchAtLogin: Bool

    var body: some View {
        SettingsPaneScaffold(title: "通用") {
            Form {
                Section {
                    Toggle("登录时启动", isOn: $launchAtLogin)
                }
            }
            .formStyle(.grouped)
        } footer: {
            SettingsQuitButton(title: "退出 Tic") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
