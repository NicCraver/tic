import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case general
    case appearance
    case menuBar
    case calendar
    case shortcuts
    case about

    var id: String { rawValue }

    /// 侧栏短标题（控制列宽，详情页标题见各 Pane）
    var sidebarTitle: String {
        switch self {
        case .general: "通用"
        case .appearance: "外观"
        case .menuBar: "菜单栏"
        case .calendar: "日历"
        case .shortcuts: "快捷键"
        case .about: "关于"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintbrush"
        case .menuBar: "menubar.rectangle"
        case .calendar: "calendar"
        case .shortcuts: "command"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @State private var selection: SettingsSection? = .general
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var launchAtLogin = LaunchAtLoginManager.shared.isEnabled
    @AppStorage(AppSettings.appThemeKey) private var appThemeRaw = AppTheme.system.rawValue

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .modifier(SettingsWindowToolbarStyle())
        .frame(
            width: SettingsTheme.windowWidth,
            height: SettingsTheme.windowHeight
        )
        .preferredColorScheme(AppTheme(rawValue: appThemeRaw)?.colorScheme)
        .background(SettingsSplitViewConfigurator())
        .onAppear {
            AppSettings.migrateLegacyFormatIfNeeded()
            launchAtLogin = LaunchAtLoginManager.shared.isEnabled
        }
    }

    private var sidebar: some View {
        List(selection: $selection) {
            ForEach(SettingsSection.allCases) { section in
                Label(section.sidebarTitle, systemImage: section.icon)
                    .tag(section)
                    .listRowInsets(SettingsTheme.sidebarRowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(sidebarSelectionBackground(for: section))
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(
            min: SettingsTheme.sidebarMinWidth,
            ideal: SettingsTheme.sidebarWidth,
            max: SettingsTheme.sidebarMaxWidth
        )
        .toolbar(removing: .sidebarToggle)
        .background(SettingsSidebarListConfigurator())
    }

    @ViewBuilder
    private func sidebarSelectionBackground(for section: SettingsSection) -> some View {
        if selection == section {
            RoundedRectangle(
                cornerRadius: SettingsTheme.sidebarSelectionCornerRadius,
                style: .continuous
            )
            .fill(Color(nsColor: .selectedContentBackgroundColor))
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        if let selection {
            switch selection {
            case .general:
                GeneralSettingsPane(launchAtLogin: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        LaunchAtLoginManager.shared.setEnabled(enabled)
                    }
            case .appearance:
                AppearanceSettingsPane()
            case .menuBar:
                MenuBarSettingsPane()
            case .calendar:
                CalendarSettingsPane()
            case .shortcuts:
                ShortcutsSettingsPane()
            case .about:
                AboutSettingsPane()
            }
        } else {
            ContentUnavailableView(
                "选择设置项",
                systemImage: "gearshape",
                description: Text("从左侧列表选择要查看的设置。")
            )
        }
    }
}

private struct SettingsSplitViewConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.isHidden = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            SettingsWindowChrome.configureFullHeightSplitItems(in: window)
        }
    }
}

/// 隐藏窗口 toolbar 背景，侧栏材质延伸至交通灯区域（macOS 15+）。
private struct SettingsWindowToolbarStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 15, *) {
            content
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .toolbar(removing: .title)
        } else {
            content
                .toolbarBackground(.hidden, for: .windowToolbar)
        }
    }
}

