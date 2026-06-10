import AppKit

@MainActor
final class UpdateCheckingIndicator {
    static let shared = UpdateCheckingIndicator()

    private var panel: NSPanel?

    private init() {}

    func show() {
        dismiss()

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 232, height: 92),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.backgroundColor = .windowBackgroundColor
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false

        let spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.controlSize = .regular
        spinner.isDisplayedWhenStopped = false
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimation(nil)

        let label = NSTextField(labelWithString: "正在检查更新…")
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .labelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let detail = NSTextField(labelWithString: "正在查询 GitHub Releases")
        detail.font = .systemFont(ofSize: 11)
        detail.textColor = .secondaryLabelColor
        detail.alignment = .center
        detail.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(spinner)
        content.addSubview(label)
        content.addSubview(detail)

        NSLayoutConstraint.activate([
            spinner.topAnchor.constraint(equalTo: content.topAnchor, constant: 4),
            spinner.centerXAnchor.constraint(equalTo: content.centerXAnchor),

            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),

            detail.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 2),
            detail.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            detail.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            detail.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -4),
        ])

        let padded = NSView(frame: NSRect(x: 0, y: 0, width: 232, height: 92))
        padded.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: padded.topAnchor, constant: 16),
            content.bottomAnchor.constraint(equalTo: padded.bottomAnchor, constant: -16),
            content.leadingAnchor.constraint(equalTo: padded.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: padded.trailingAnchor),
        ])
        panel.contentView = padded

        if let anchor = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) {
            panel.layoutIfNeeded()
            let anchorFrame = anchor.frame
            let panelSize = panel.frame.size
            let origin = NSPoint(
                x: anchorFrame.midX - panelSize.width / 2,
                y: anchorFrame.midY - panelSize.height / 2
            )
            panel.setFrameOrigin(origin)
        } else {
            panel.center()
        }

        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
    }
}

@MainActor
enum UpdatePrompt {
    static func showUpToDate(currentVersion: String) {
        let alert = NSAlert()
        alert.messageText = "已是最新版本"
        alert.informativeText = "当前版本：\(currentVersion)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    static func showError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.messageText = "检查更新失败"
        alert.runModal()
    }
}
