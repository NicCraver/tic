import SwiftUI

struct AppearanceSettingsPane: View {
    @AppStorage(AppSettings.appThemeKey) private var appTheme = AppTheme.system.rawValue

    var body: some View {
        SettingsPaneScaffold(title: "外观") {
            Form {
                Section {
                    Picker("主题", selection: $appTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.title).tag(theme.rawValue)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
}
