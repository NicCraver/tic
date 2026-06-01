import AppKit

@MainActor
final class MenuBarSettingsViewController: SettingsPaneViewController {
    private var blockOrder: [MenuBarBlock]
    private var enabledBlocks: Set<MenuBarBlock>

    private let previewHolder = GroupHolder()
    private let blocksHolder = GroupHolder()
    private let previewIcon = NSImageView()
    private let previewLabel = NSTextField(labelWithString: "")

    init() {
        blockOrder = Self.normalizedOrder(AppSettings.loadBlockOrder())
        enabledBlocks = AppSettings.loadEnabledBlocks()
        super.init(title: "菜单栏")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var showSeconds: Bool { AppSettings.bool(forKey: AppSettings.showSecondsKey, default: true) }
    private var use24Hour: Bool { AppSettings.bool(forKey: AppSettings.use24HourKey, default: true) }

    override func makeContent() -> [NSView] {
        previewIcon.image = NSImage(systemSymbolName: "calendar.circle.fill", accessibilityDescription: nil)
        previewIcon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        previewIcon.setContentHuggingPriority(.required, for: .horizontal)
        previewLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        rebuildPreview()
        rebuildBlocks()
        updatePreview()
        return [previewHolder, blocksHolder]
    }

    // MARK: - 重建

    private func rebuildPreview() {
        let previewStack = NSStackView(views: [previewIcon, previewLabel, flexibleSpacer()])
        previewStack.orientation = .horizontal
        previewStack.alignment = .centerY
        previewStack.spacing = 6

        let hint = NSTextField(labelWithString: "使用右侧按钮调整顺序")
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        let reset = makeLinkButton(title: "重置顺序", action: #selector(resetOrder))

        previewHolder.setGroup(SettingsGroup(rows: [
            wrapRow(previewStack),
            makeSettingsRow(leading: hint, trailing: reset),
        ]))
    }

    private func rebuildBlocks() {
        blocksHolder.setGroup(SettingsGroup(rows: blockOrder.map(makeBlockRow)))
    }

    private func updatePreview() {
        previewIcon.isHidden = !MenuBarDisplayComposer.showsIcon(order: blockOrder, enabled: enabledBlocks)
        previewLabel.stringValue = MenuBarDisplayComposer.compose(
            date: .now,
            order: blockOrder,
            enabled: enabledBlocks,
            showSeconds: showSeconds,
            use24Hour: use24Hour
        )
    }

    private func makeBlockRow(_ block: MenuBarBlock) -> NSView {
        let checkbox = NSButton(checkboxWithTitle: block.title, target: self, action: #selector(toggleBlock(_:)))
        checkbox.tag = Self.tag(for: block)
        checkbox.state = enabledBlocks.contains(block) ? .on : .off

        let sample = NSTextField(labelWithString: block.previewSample)
        sample.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        sample.textColor = .secondaryLabelColor

        var views: [NSView] = [makeReorderButtons(for: block), checkbox, flexibleSpacer(), sample]
        if block == .time {
            views.append(makeLinkButton(title: "选项…", action: #selector(showTimeOptions)))
        }

        let stack = NSStackView(views: views)
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8
        return wrapRow(stack)
    }

    private func makeReorderButtons(for block: MenuBarBlock) -> NSView {
        let up = makeChevronButton(symbol: "chevron.up", action: #selector(moveBlockUp(_:)))
        up.tag = Self.tag(for: block)
        up.isEnabled = blockOrder.first != block

        let down = makeChevronButton(symbol: "chevron.down", action: #selector(moveBlockDown(_:)))
        down.tag = Self.tag(for: block)
        down.isEnabled = blockOrder.last != block

        let stack = NSStackView(views: [up, down])
        stack.orientation = .vertical
        stack.spacing = 2
        stack.widthAnchor.constraint(equalToConstant: 16).isActive = true
        return stack
    }

    // MARK: - Actions

    @objc private func toggleBlock(_ sender: NSButton) {
        guard let block = Self.block(forTag: sender.tag) else { return }
        if sender.state == .on {
            enabledBlocks.insert(block)
            if !blockOrder.contains(block) {
                blockOrder.append(block)
                AppSettings.saveBlockOrder(blockOrder)
            }
        } else {
            enabledBlocks.remove(block)
        }
        AppSettings.saveEnabledBlocks(enabledBlocks)
        updatePreview()
        notifyMenuBarChanged()
    }

    @objc private func moveBlockUp(_ sender: NSButton) {
        guard let block = Self.block(forTag: sender.tag),
              let index = blockOrder.firstIndex(of: block), index > 0 else { return }
        blockOrder.swapAt(index, index - 1)
        commitOrderChange()
    }

    @objc private func moveBlockDown(_ sender: NSButton) {
        guard let block = Self.block(forTag: sender.tag),
              let index = blockOrder.firstIndex(of: block), index < blockOrder.count - 1 else { return }
        blockOrder.swapAt(index, index + 1)
        commitOrderChange()
    }

    @objc private func resetOrder() {
        AppSettings.resetMenuBarLayout()
        blockOrder = Self.normalizedOrder(AppSettings.loadBlockOrder())
        enabledBlocks = AppSettings.loadEnabledBlocks()
        rebuildBlocks()
        updatePreview()
        notifyMenuBarChanged()
    }

    @objc private func showTimeOptions() {
        let options = TimeOptionsViewController()
        options.onChange = { [weak self] in
            self?.updatePreview()
            self?.notifyMenuBarChanged()
        }
        presentAsSheet(options)
    }

    private func commitOrderChange() {
        AppSettings.saveBlockOrder(blockOrder)
        rebuildBlocks()
        updatePreview()
        notifyMenuBarChanged()
    }

    private func notifyMenuBarChanged() {
        NotificationCenter.default.post(name: .menuBarSettingsDidChange, object: nil)
    }

    // MARK: - Helpers

    private func wrapRow(_ content: NSView) -> NSView {
        let row = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(content)
        let insets = SettingsControlMetrics.rowInsets
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: insets.left),
            content.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -insets.right),
            content.topAnchor.constraint(equalTo: row.topAnchor, constant: insets.top),
            content.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -insets.bottom),
            row.heightAnchor.constraint(
                greaterThanOrEqualToConstant: SettingsControlMetrics.rowMinHeight + insets.top + insets.bottom
            ),
        ])
        return row
    }

    private func flexibleSpacer() -> NSView {
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return spacer
    }

    private func makeChevronButton(symbol: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.isBordered = false
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        button.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 9, weight: .semibold)
        button.contentTintColor = .secondaryLabelColor
        button.imagePosition = .imageOnly
        button.target = self
        button.action = action
        return button
    }

    private func makeLinkButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.isBordered = false
        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: NSColor.controlAccentColor,
                .font: NSFont.systemFont(ofSize: 13),
            ]
        )
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }

    private static func normalizedOrder(_ order: [MenuBarBlock]) -> [MenuBarBlock] {
        var result = order
        for block in MenuBarBlock.allCases where !result.contains(block) {
            result.append(block)
        }
        return result
    }

    private static func tag(for block: MenuBarBlock) -> Int {
        MenuBarBlock.allCases.firstIndex(of: block) ?? 0
    }

    private static func block(forTag tag: Int) -> MenuBarBlock? {
        MenuBarBlock.allCases.indices.contains(tag) ? MenuBarBlock.allCases[tag] : nil
    }
}

/// 可替换内容的分组容器：排序 / 启用变更后重建 `SettingsGroup`。
@MainActor
final class GroupHolder: NSView {
    func setGroup(_ group: NSView) {
        subviews.forEach { $0.removeFromSuperview() }
        group.translatesAutoresizingMaskIntoConstraints = false
        addSubview(group)
        NSLayoutConstraint.activate([
            group.topAnchor.constraint(equalTo: topAnchor),
            group.bottomAnchor.constraint(equalTo: bottomAnchor),
            group.leadingAnchor.constraint(equalTo: leadingAnchor),
            group.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: NSSize {
        layoutSubtreeIfNeeded()
        guard let group = subviews.first else {
            return NSSize(width: NSView.noIntrinsicMetric, height: 0)
        }
        return group.intrinsicContentSize
    }

    override func layout() {
        super.layout()
        invalidateIntrinsicContentSize()
    }
}

@MainActor
final class TimeOptionsViewController: NSViewController {
    var onChange: (() -> Void)?

    private let use24Switch = NSSwitch()
    private let secondsSwitch = NSSwitch()

    override func loadView() {
        let title = NSTextField(labelWithString: "时间选项")
        title.font = .systemFont(ofSize: 13, weight: .semibold)

        use24Switch.state = AppSettings.bool(forKey: AppSettings.use24HourKey, default: true) ? .on : .off
        use24Switch.target = self
        use24Switch.action = #selector(use24Changed)

        secondsSwitch.state = AppSettings.bool(forKey: AppSettings.showSecondsKey, default: true) ? .on : .off
        secondsSwitch.target = self
        secondsSwitch.action = #selector(secondsChanged)

        let group = SettingsGroup(rows: [
            makeSettingsRow(title: "24 小时制", control: use24Switch),
            makeSettingsRow(title: "显示秒", control: secondsSwitch),
        ])

        let done = NSButton(title: "完成", target: self, action: #selector(close))
        done.keyEquivalent = "\r"

        let buttonRow = NSStackView(views: [NSView(), done])
        buttonRow.orientation = .horizontal
        buttonRow.distribution = .fill
        buttonRow.views.first?.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let stack = NSStackView(views: [title, group, buttonRow])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 300),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            buttonRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            group.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
        view = container
    }

    @objc private func use24Changed() {
        AppSettings.setBool(use24Switch.state == .on, forKey: AppSettings.use24HourKey)
        onChange?()
    }

    @objc private func secondsChanged() {
        AppSettings.setBool(secondsSwitch.state == .on, forKey: AppSettings.showSecondsKey)
        onChange?()
    }

    @objc private func close() {
        dismiss(self)
    }
}
