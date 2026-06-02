import AppKit

/// 设置详情 pane 基类：滚动容器 + 22pt 大标题 + 460 宽左对齐内容列。
/// 子类覆写 `makeContent()` / `makeFooter()` 提供分组内容与页脚。
@MainActor
class SettingsPaneViewController: NSViewController {
    let paneTitle: String

    init(title: String) {
        self.paneTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func makeContent() -> [NSView] { [] }

    func makeFooter() -> NSView? { nil }

    override func loadView() {
        let titleLabel = NSTextField(labelWithString: paneTitle)
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true

        let documentView = FlippedView()
        documentView.translatesAutoresizingMaskIntoConstraints = false

        let column = NSStackView()
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = SettingsTheme.cardSpacing
        column.translatesAutoresizingMaskIntoConstraints = false

        let contentViews = makeContent()
        for view in contentViews {
            view.setContentCompressionResistancePriority(.required, for: .vertical)
            column.addArrangedSubview(view)
            view.widthAnchor.constraint(equalTo: column.widthAnchor).isActive = true
        }
        if let footer = makeFooter() {
            if let lastContent = contentViews.last {
                column.setCustomSpacing(SettingsTheme.footerTopSpacing, after: lastContent)
            }
            footer.setContentCompressionResistancePriority(.required, for: .vertical)
            column.addArrangedSubview(footer)
            footer.widthAnchor.constraint(equalTo: column.widthAnchor).isActive = true
        }

        documentView.addSubview(column)
        scrollView.documentView = documentView

        let container = NSView()
        container.addSubview(titleLabel)
        container.addSubview(scrollView)

        let padding = SettingsTheme.panePadding
        let preferredWidth = column.widthAnchor.constraint(equalToConstant: SettingsTheme.contentMaxWidth)
        preferredWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -padding),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: SettingsTheme.titleToContentSpacing),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            documentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            documentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),

            column.topAnchor.constraint(equalTo: documentView.topAnchor),
            column.leadingAnchor.constraint(equalTo: documentView.leadingAnchor, constant: padding),
            column.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -padding),
            column.trailingAnchor.constraint(lessThanOrEqualTo: documentView.trailingAnchor, constant: -padding),
            preferredWidth,
        ])

        view = container
    }
}
