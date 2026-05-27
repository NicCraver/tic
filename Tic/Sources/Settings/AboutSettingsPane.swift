import SwiftUI

struct AboutSettingsPane: View {
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        SettingsPaneScaffold(title: "关于") {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                            .symbolRenderingMode(.hierarchical)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tic")
                                .font(.system(size: 20, weight: .bold))
                            Text("菜单栏日历工具")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Text("版本 \(appVersion)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    feedbackLink(
                        title: "联系支持邮件",
                        subtitle: "support@ticapp.com",
                        url: URL(string: "mailto:support@ticapp.com")
                    )
                    feedbackLink(
                        title: "访问官方网站",
                        subtitle: "https://ticapp.com",
                        url: URL(string: "https://ticapp.com")
                    )
                    feedbackLink(
                        title: "去 App Store 评分",
                        subtitle: "撰写评论鼓励我们",
                        url: nil
                    )
                }
            }
            .formStyle(.grouped)
        }
    }

    private func feedbackLink(title: String, subtitle: String, url: URL?) -> some View {
        Button {
            if let url {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}
