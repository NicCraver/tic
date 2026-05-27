import SwiftUI

struct SettingsView: View {
    @AppStorage("showSeconds") private var showSeconds = true
    @AppStorage("dateFormatStyle") private var dateFormatStyle = DateFormatStyle.compact.rawValue
    @State private var launchAtLogin = LaunchAtLoginManager.shared.isEnabled

    var body: some View {
        TabView {
            Form {
                Picker("状态栏显示", selection: $dateFormatStyle) {
                    ForEach(DateFormatStyle.allCases) { style in
                        Text(style.title).tag(style.rawValue)
                    }
                }

                Toggle("显示秒数", isOn: $showSeconds)

                Toggle("登录时启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        LaunchAtLoginManager.shared.setEnabled(enabled)
                    }
            }
            .formStyle(.grouped)
            .padding()
            .tabItem {
                Label("通用", systemImage: "gear")
            }
        }
        .frame(width: 420, height: 240)
    }
}
