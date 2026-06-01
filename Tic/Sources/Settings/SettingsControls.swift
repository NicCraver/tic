import AppKit

/// 翻转坐标系容器：子视图自顶向下排布（用于 NSScrollView 文档视图、分组盒内部）。
final class FlippedView: NSView {
    override var isFlipped: Bool { true }

    override var intrinsicContentSize: NSSize {
        layoutSubtreeIfNeeded()
        let height = subviews.map(\.frame.maxY).max() ?? 0
        return NSSize(width: NSView.noIntrinsicMetric, height: height)
    }

    override func layout() {
        super.layout()
        invalidateIntrinsicContentSize()
    }
}

@MainActor
enum SettingsControlMetrics {
    static let groupCornerRadius: CGFloat = 10
    static let rowInsets = NSEdgeInsets(top: 11, left: 16, bottom: 11, right: 16)
    static let rowMinHeight: CGFloat = 22
    static let rowWithSubtitleMinHeight: CGFloat = 44
    static let rowContentSpacing: CGFloat = 12
}

@MainActor
enum SettingsPalette {
    static let destructive = NSColor(srgbRed: 1.0, green: 0.27, blue: 0.23, alpha: 1)
}

/// 圆角分组盒：垂直堆叠行，行间以系统分隔线分隔（近似 SwiftUI `Form(.grouped)` 的分组卡片）。
@MainActor
final class SettingsGroup: NSBox {
    init(rows: [NSView]) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        boxType = .custom
        borderWidth = 0
        cornerRadius = SettingsControlMetrics.groupCornerRadius
        fillColor = .controlBackgroundColor
        contentViewMargins = .zero
        titlePosition = .noTitle

        let container = FlippedView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView = container

        var previous: NSView?
        for row in rows {
            row.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(row)
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            ])

            if let previous {
                let separator = Self.makeSeparator()
                container.addSubview(separator)
                NSLayoutConstraint.activate([
                    separator.topAnchor.constraint(equalTo: previous.bottomAnchor),
                    separator.leadingAnchor.constraint(
                        equalTo: container.leadingAnchor,
                        constant: SettingsControlMetrics.rowInsets.left
                    ),
                    separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    separator.heightAnchor.constraint(equalToConstant: 1),
                    row.topAnchor.constraint(equalTo: separator.bottomAnchor),
                ])
            } else {
                row.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
            }
            previous = row
        }

        previous?.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        container.invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: NSSize {
        guard let container = contentView else { return super.intrinsicContentSize }
        container.layoutSubtreeIfNeeded()
        let height = container.intrinsicContentSize.height
        return NSSize(width: NSView.noIntrinsicMetric, height: height)
    }

    override func layout() {
        super.layout()
        invalidateIntrinsicContentSize()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 单张圆角卡片包裹一行设置（左文右控件）。
    convenience init(row: NSView) {
        self.init(rows: [row])
    }

    private static func makeSeparator() -> NSBox {
        let line = NSBox()
        line.boxType = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        return line
    }
}

/// 每项独立一张圆角卡片（参考系统设置 / xCal 分组间距）。
@MainActor
func makeSettingsCards(_ rows: [NSView]) -> [SettingsGroup] {
    rows.map { SettingsGroup(row: $0) }
}

/// 多项合并为一张卡片，行间分隔线（逻辑相关的设置）。
@MainActor
func makeSettingsGroupedCard(_ rows: [NSView]) -> SettingsGroup {
    SettingsGroup(rows: rows)
}

/// 标准设置行：左侧标题（可带副标题），右侧控件，垂直居中。
@MainActor
func makeSettingsRow(
    title: String,
    subtitle: String? = nil,
    control: NSView,
    spacing: CGFloat = SettingsControlMetrics.rowContentSpacing
) -> NSView {
    let titleLabel = NSTextField(labelWithString: title)
    titleLabel.font = .systemFont(ofSize: 13)

    let textStack = NSStackView()
    textStack.orientation = .vertical
    textStack.alignment = .leading
    textStack.spacing = 2
    textStack.translatesAutoresizingMaskIntoConstraints = false
    textStack.addArrangedSubview(titleLabel)
    if let subtitle {
        let subtitleLabel = NSTextField(wrappingLabelWithString: subtitle)
        subtitleLabel.font = .systemFont(ofSize: 11)
        subtitleLabel.textColor = .secondaryLabelColor
        textStack.addArrangedSubview(subtitleLabel)
    }

    return makeSettingsRow(leading: textStack, trailing: control, spacing: spacing, tallLeading: subtitle != nil)
}

/// 通用设置行：自定义左右两侧视图。
@MainActor
func makeSettingsRow(
    leading: NSView,
    trailing: NSView,
    spacing: CGFloat = SettingsControlMetrics.rowContentSpacing,
    tallLeading: Bool = false
) -> NSView {
    let row = NSView()
    row.translatesAutoresizingMaskIntoConstraints = false

    leading.translatesAutoresizingMaskIntoConstraints = false
    leading.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    trailing.translatesAutoresizingMaskIntoConstraints = false
    trailing.setContentHuggingPriority(.required, for: .horizontal)
    trailing.setContentCompressionResistancePriority(.required, for: .horizontal)

    row.addSubview(leading)
    row.addSubview(trailing)

    let insets = SettingsControlMetrics.rowInsets
    var constraints: [NSLayoutConstraint] = [
        leading.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: insets.left),
        trailing.leadingAnchor.constraint(greaterThanOrEqualTo: leading.trailingAnchor, constant: spacing),
        trailing.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -insets.right),
        trailing.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        row.heightAnchor.constraint(
            greaterThanOrEqualToConstant: (tallLeading
                ? SettingsControlMetrics.rowWithSubtitleMinHeight
                : SettingsControlMetrics.rowMinHeight) + insets.top + insets.bottom
        ),
    ]
    if tallLeading {
        constraints += [
            leading.topAnchor.constraint(equalTo: row.topAnchor, constant: insets.top),
            leading.bottomAnchor.constraint(lessThanOrEqualTo: row.bottomAnchor, constant: -insets.bottom),
        ]
    } else {
        constraints += [
            leading.topAnchor.constraint(greaterThanOrEqualTo: row.topAnchor, constant: insets.top),
            leading.bottomAnchor.constraint(lessThanOrEqualTo: row.bottomAnchor, constant: -insets.bottom),
            leading.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ]
    }
    NSLayoutConstraint.activate(constraints)
    return row
}

/// 整宽红色危险按钮（如「退出 Tic」）。
@MainActor
final class SettingsDestructiveButton: NSButton {
    init(title: String, target: AnyObject?, action: Selector) {
        super.init(frame: .zero)
        self.target = target
        self.action = action
        translatesAutoresizingMaskIntoConstraints = false
        isBordered = false
        wantsLayer = true
        layer?.backgroundColor = SettingsPalette.destructive.cgColor
        layer?.cornerRadius = 10
        attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: NSColor.white,
                .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            ]
        )
        heightAnchor.constraint(equalToConstant: 36).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

@MainActor
func makeSettingsFootnote(_ text: String) -> NSTextField {
    let label = NSTextField(wrappingLabelWithString: text)
    label.font = .systemFont(ofSize: 11)
    label.textColor = .secondaryLabelColor
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
}
