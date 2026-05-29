import SwiftUI

struct CalendarSettingsPane: View {
    @AppStorage(AppSettings.showAnnotationDotsKey) private var showAnnotationDots = true
    @AppStorage(AppSettings.showSolarTermsKey) private var showSolarTerms = true

    var body: some View {
        SettingsPaneScaffold(title: "日历") {
            Form {
                Section {
                    Toggle(isOn: $showAnnotationDots) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("显示标注圆点")
                            Text("节假日、节气等有标注的日期在月历格底部显示圆点")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $showSolarTerms) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("显示节气")
                            Text("月历副标题与详情中显示节气名称（如立夏）")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
}
