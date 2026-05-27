import SwiftUI

enum SettingsTheme {
    static let windowWidth: CGFloat = 700
    static let windowHeight: CGFloat = 480
    static let contentMaxWidth: CGFloat = 460

    /// 侧栏最长项为四字（如「快捷键」），配合系统图标留白
    static let sidebarWidth: CGFloat = 168
    static let sidebarMinWidth: CGFloat = 152
    static let sidebarMaxWidth: CGFloat = 188

    /// 侧栏选中项圆角（大于系统默认 ~6pt）
    static let sidebarSelectionCornerRadius: CGFloat = 12
    static let sidebarRowInsets = EdgeInsets(top: 3, leading: 12, bottom: 3, trailing: 12)
    static let sidebarRowSpacing: CGFloat = 4

    static let destructive = Color(red: 1.0, green: 0.27, blue: 0.23)
}

// MARK: - Detail layout（与系统设置一致：大标题 + 原生分组表单）

struct SettingsPaneScaffold<Content: View, Footer: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    init(
        title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer = { EmptyView() }
    ) {
        self.title = title
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))

                content

                footer
            }
            .frame(maxWidth: SettingsTheme.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SettingsQuitButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(SettingsTheme.destructive, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.top, 8)
    }
}

struct SettingsFootnote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
