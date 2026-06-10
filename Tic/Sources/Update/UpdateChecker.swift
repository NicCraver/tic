import AppKit
import Foundation

extension Notification.Name {
    static let checkForUpdates = Notification.Name("me.nic.tic.checkForUpdates")
}

@MainActor
final class UpdateChecker {
    static let shared = UpdateChecker()

    private let service = UpdateService()
    private var isChecking = false

    private let lastCheckKey = "me.nic.tic.lastUpdateCheckTime"
    private let autoCheckInterval: TimeInterval = 24 * 60 * 60

    private init() {}

    func registerForMenuCommands() {
        NotificationCenter.default.addObserver(
            forName: .checkForUpdates,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                UpdateChecker.shared.checkManually()
            }
        }
    }

    func checkAutomaticallyIfNeeded() {
        let lastCheck = UserDefaults.standard.double(forKey: lastCheckKey)
        let elapsed = Date().timeIntervalSince1970 - lastCheck
        guard lastCheck == 0 || elapsed >= autoCheckInterval else { return }
        Task { await performCheck(automatic: true) }
    }

    func checkManually() {
        guard !isChecking else { return }
        Task { await performCheck(automatic: false) }
    }

    private func performCheck(automatic: Bool) async {
        isChecking = true
        defer { isChecking = false }

        do {
            if let release = try await service.checkForUpdates() {
                recordCheckTime()
                showUpdateAvailable(release)
            } else {
                recordCheckTime()
                if !automatic {
                    showUpToDate()
                }
            }
        } catch {
            if !automatic {
                showError(error)
            }
        }
    }

    private func recordCheckTime() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastCheckKey)
    }

    private func showUpToDate() {
        let alert = NSAlert()
        alert.messageText = "已是最新版本"
        alert.informativeText = "当前版本：\(UpdateService.currentVersion)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    private func showUpdateAvailable(_ release: GitHubRelease) {
        let version = service.stripVersionPrefix(release.tagName)
        let notes = release.body.trimmingCharacters(in: .whitespacesAndNewlines)
        let preview = notes.isEmpty ? "请前往 GitHub 查看更新说明。" : String(notes.prefix(500))

        let alert = NSAlert()
        alert.messageText = "发现新版本 \(version)"
        alert.informativeText = "当前版本：\(UpdateService.currentVersion)\n\n\(preview)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "下载更新")
        alert.addButton(withTitle: "稍后")
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        openDownload(for: release)
    }

    private func openDownload(for release: GitHubRelease) {
        if let dmgURL = release.dmgDownloadURL {
            NSWorkspace.shared.open(dmgURL)
            return
        }
        NSWorkspace.shared.open(release.htmlURL)
    }

    private func showError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.messageText = "检查更新失败"
        alert.runModal()
    }
}
