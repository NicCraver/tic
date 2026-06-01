import AppKit

extension Notification.Name {
    /// 主题（appTheme）变更：AppKit 设置窗口据此同步 `NSAppearance`
    /// （SwiftUI 视图通过 `@AppStorage` 自动响应，无需此通知）。
    static let appThemeDidChange = Notification.Name("appThemeDidChange")
}

private extension AppTheme {
    var nsAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

/// 设置窗口内容控制器：全高 source-list 侧栏 + 详情容器。
@MainActor
final class SettingsSplitViewController: NSSplitViewController {
    private let sidebar = SettingsSidebarViewController()
    private let detailContainer = SettingsDetailContainerViewController()
    private var paneCache: [SettingsSection: NSViewController] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        sidebar.delegate = self

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebar)
        sidebarItem.canCollapse = false
        sidebarItem.minimumThickness = SettingsTheme.sidebarWidth
        sidebarItem.maximumThickness = SettingsTheme.sidebarWidth
        sidebarItem.allowsFullHeightLayout = true
        addSplitViewItem(sidebarItem)

        let detailItem = NSSplitViewItem(viewController: detailContainer)
        detailItem.minimumThickness = SettingsTheme.windowWidth - SettingsTheme.sidebarWidth
        detailItem.canCollapse = false
        addSplitViewItem(detailItem)

        NotificationCenter.default.addObserver(
            forName: .appThemeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.applyTheme() }
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        applyTheme()
    }

    private func applyTheme() {
        let raw = UserDefaults.standard.string(forKey: AppSettings.appThemeKey) ?? AppTheme.system.rawValue
        let theme = AppTheme(rawValue: raw) ?? .system
        view.window?.appearance = theme.nsAppearance
    }

    private func pane(for section: SettingsSection) -> NSViewController {
        if let cached = paneCache[section] { return cached }
        let pane = Self.makePane(for: section)
        paneCache[section] = pane
        return pane
    }

    private static func makePane(for section: SettingsSection) -> NSViewController {
        switch section {
        case .general: GeneralSettingsViewController()
        case .appearance: AppearanceSettingsViewController()
        case .menuBar: MenuBarSettingsViewController()
        case .calendar: CalendarSettingsViewController()
        case .shortcuts: ShortcutsSettingsViewController()
        case .about: AboutSettingsViewController()
        }
    }
}

extension SettingsSplitViewController: SettingsSidebarDelegate {
    func settingsSidebar(_ sidebar: SettingsSidebarViewController, didSelect section: SettingsSection) {
        detailContainer.show(pane(for: section))
    }
}

/// 详情区容器：承载当前 pane，提供窗口背景色。
@MainActor
final class SettingsDetailContainerViewController: NSViewController {
    private var current: NSViewController?

    override func loadView() {
        view = SettingsBackgroundView()
    }

    func show(_ viewController: NSViewController) {
        guard current !== viewController else { return }
        if let current {
            current.view.removeFromSuperview()
            current.removeFromParent()
        }
        addChild(viewController)
        let child = viewController.view
        child.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child)
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: view.topAnchor),
            child.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            child.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        current = viewController
    }
}

/// 随深浅色自动更新的窗口背景（`updateLayer` 在 effectiveAppearance 变化时重绘）。
final class SettingsBackgroundView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
}
