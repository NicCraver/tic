import AppKit

@MainActor
protocol SettingsSidebarDelegate: AnyObject {
    func settingsSidebar(_ sidebar: SettingsSidebarViewController, didSelect section: SettingsSection)
}

/// 设置侧栏：`NSTableView(.sourceList)`，系统原生强调色选中。
@MainActor
final class SettingsSidebarViewController: NSViewController {
    weak var delegate: SettingsSidebarDelegate?

    private let sections = SettingsSection.allCases
    private let tableView = NSTableView()
    private static let cellIdentifier = NSUserInterfaceItemIdentifier("SettingsSidebarCell")

    override func loadView() {
        tableView.style = .sourceList
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.allowsEmptySelection = false
        tableView.allowsMultipleSelection = false
        tableView.dataSource = self
        tableView.delegate = self

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("section"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false

        view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()
        select(.general)
    }

    func select(_ section: SettingsSection) {
        guard let index = sections.firstIndex(of: section) else { return }
        tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
    }

    private static func makeCell() -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = cellIdentifier

        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyDown

        let textField = NSTextField(labelWithString: "")
        textField.font = .systemFont(ofSize: 13)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byTruncatingTail

        cell.addSubview(imageView)
        cell.addSubview(textField)
        cell.imageView = imageView
        cell.textField = textField

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
            imageView.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 18),
            textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 6),
            textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
            textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }
}

extension SettingsSidebarViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int { sections.count }
}

extension SettingsSidebarViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let section = sections[row]
        let cell = (tableView.makeView(withIdentifier: Self.cellIdentifier, owner: self) as? NSTableCellView)
            ?? Self.makeCell()
        cell.textField?.stringValue = section.sidebarTitle
        cell.imageView?.image = NSImage(
            systemSymbolName: section.icon,
            accessibilityDescription: section.sidebarTitle
        )
        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat { 28 }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard sections.indices.contains(row) else { return }
        delegate?.settingsSidebar(self, didSelect: sections[row])
    }
}
