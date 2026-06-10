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
        if !automatic {
            UpdateCheckingIndicator.shared.show()
        }
        defer { isChecking = false }

        do {
            if let release = try await service.checkForUpdates() {
                recordCheckTime()
                dismissManualIndicator(ifManual: !automatic)
                let version = service.stripVersionPrefix(release.tagName)
                UpdateAvailablePanel.show(
                    release: release,
                    currentVersion: UpdateService.currentVersion,
                    version: version
                )
            } else {
                recordCheckTime()
                dismissManualIndicator(ifManual: !automatic)
                if !automatic {
                    UpdatePrompt.showUpToDate(currentVersion: UpdateService.currentVersion)
                }
            }
        } catch {
            dismissManualIndicator(ifManual: !automatic)
            if !automatic {
                UpdatePrompt.showError(error)
            }
        }
    }

    private func dismissManualIndicator(ifManual: Bool) {
        guard ifManual else { return }
        UpdateCheckingIndicator.shared.dismiss()
    }

    private func recordCheckTime() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastCheckKey)
    }
}
