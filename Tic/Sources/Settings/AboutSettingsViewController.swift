import AppKit

@MainActor
final class AboutSettingsViewController: SettingsPaneViewController {
    init() { super.init(title: "关于") }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    override func makeContent() -> [NSView] {
        [
            SettingsGroup(row: makeHeaderRow()),
            SettingsGroup(rows: [
                SettingsActionRow(
                    title: "检查更新",
                    subtitle: "查询 GitHub 最新版本",
                    action: { UpdateChecker.shared.checkManually() }
                ),
                SettingsLinkRow(
                    title: "反馈与问题",
                    subtitle: "GitHub Issues",
                    urlString: "https://github.com/NicCraver/tic/issues"
                ),
                SettingsLinkRow(
                    title: "开源仓库",
                    subtitle: "github.com/NicCraver/tic",
                    urlString: "https://github.com/NicCraver/tic"
                ),
            ]),
        ]
    }

    private func makeHeaderRow() -> NSView {
        let icon = NSImageView()
        let config = NSImage.SymbolConfiguration(pointSize: 44, weight: .regular)
            .applying(NSImage.SymbolConfiguration(hierarchicalColor: .systemBlue))
        icon.image = NSImage(systemSymbolName: "calendar.circle.fill", accessibilityDescription: "Tic")
        icon.symbolConfiguration = config
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.setContentHuggingPriority(.required, for: .horizontal)

        let name = NSTextField(labelWithString: "Tic")
        name.font = .systemFont(ofSize: 20, weight: .bold)

        let desc = NSTextField(labelWithString: "菜单栏日历工具")
        desc.font = .systemFont(ofSize: 13)
        desc.textColor = .secondaryLabelColor

        let version = NSTextField(labelWithString: "版本 \(appVersion)")
        version.font = .systemFont(ofSize: 11)
        version.textColor = .secondaryLabelColor

        let text = NSStackView(views: [name, desc, version])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 4
        text.translatesAutoresizingMaskIntoConstraints = false

        let row = NSView()
        row.addSubview(icon)
        row.addSubview(text)

        let insets = SettingsControlMetrics.rowInsets
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: insets.left),
            icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 48),
            icon.heightAnchor.constraint(equalToConstant: 48),
            text.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
            text.trailingAnchor.constraint(lessThanOrEqualTo: row.trailingAnchor, constant: -insets.right),
            text.topAnchor.constraint(equalTo: row.topAnchor, constant: insets.top + 4),
            text.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -(insets.bottom + 4)),
        ])
        return row
    }
}

/// 关于页可点击操作行：整行点击触发操作，悬停显示手型光标。
@MainActor
final class SettingsActionRow: NSView {
    private let action: () -> Void

    init(title: String, subtitle: String, action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13)

        let subtitleLabel = NSTextField(labelWithString: subtitle)
        subtitleLabel.font = .systemFont(ofSize: 11)
        subtitleLabel.textColor = .secondaryLabelColor

        let text = NSStackView(views: [titleLabel, subtitleLabel])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 2

        let chevron = NSImageView()
        chevron.image = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: nil)
        chevron.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        chevron.contentTintColor = .tertiaryLabelColor

        let content = makeSettingsRow(leading: text, trailing: chevron, tallLeading: true)
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    override var intrinsicContentSize: NSSize {
        layoutSubtreeIfNeeded()
        return subviews.first?.intrinsicContentSize ?? super.intrinsicContentSize
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func mouseDown(with event: NSEvent) {
        action()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

/// 关于页可点击链接行：整行点击打开 URL，悬停显示手型光标。
@MainActor
final class SettingsLinkRow: NSView {
    private let url: URL?

    init(title: String, subtitle: String, urlString: String) {
        url = URL(string: urlString)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13)

        let subtitleLabel = NSTextField(labelWithString: subtitle)
        subtitleLabel.font = .systemFont(ofSize: 11)
        subtitleLabel.textColor = .secondaryLabelColor

        let text = NSStackView(views: [titleLabel, subtitleLabel])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 2

        let chevron = NSImageView()
        chevron.image = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: nil)
        chevron.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        chevron.contentTintColor = .tertiaryLabelColor

        let content = makeSettingsRow(leading: text, trailing: chevron)
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    override var intrinsicContentSize: NSSize {
        layoutSubtreeIfNeeded()
        return subviews.first?.intrinsicContentSize ?? super.intrinsicContentSize
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func mouseDown(with event: NSEvent) {
        if let url { NSWorkspace.shared.open(url) }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}
