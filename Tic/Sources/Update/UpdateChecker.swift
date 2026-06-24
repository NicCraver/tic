import AppKit
import Foundation

extension Notification.Name {
    static let checkForUpdates = Notification.Name("me.nic.tic.checkForUpdates")
}

/// 检查更新：每天固定时刻静默比对版本并提醒；也可从菜单 / 设置手动检查。
@MainActor
final class UpdateChecker {
    static let shared = UpdateChecker()

    private let service = UpdateService()
    private var isChecking = false
    private var dailyCheckTimer: Timer?
    private var timezoneObserver: NSObjectProtocol?

    private let lastCheckKey = "me.nic.tic.lastUpdateCheckTime"
    private let dismissedVersionKey = "me.nic.tic.dismissedUpdateVersion"
    /// 启动补检：距上次查询超过该间隔则尽快检查（覆盖关机跨天、首次安装等）。
    private let launchCatchUpInterval: TimeInterval = 24 * 60 * 60
    private let launchCheckDelay: TimeInterval = 2
    /// 每天自动检查时刻（按 macOS 系统时区解释，非固定 UTC/东八区）。
    private let dailyCheckHour = 10
    private let dailyCheckMinute = 0

    private var localCalendar: Calendar { .autoupdatingCurrent }

    private init() {}

    /// 注册菜单入口，并调度每天固定时刻的自动检查（常驻应用不重启也会到点触发）。
    func beginAutomaticUpdateChecks() {
        registerForMenuCommands()
        observeTimezoneChanges()
        scheduleNextDailyCheck()

        Task {
            try? await Task.sleep(for: .seconds(launchCheckDelay))
            if needsLaunchCatchUpCheck() {
                runAutomaticCheck()
            }
        }
    }

    private func registerForMenuCommands() {
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

    private func scheduleNextDailyCheck() {
        dailyCheckTimer?.invalidate()
        guard let fireDate = nextDailyCheckDate(after: Date()) else { return }

        let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.performScheduledDailyCheck()
            }
        }
        timer.tolerance = 60 * 5
        RunLoop.main.add(timer, forMode: .common)
        dailyCheckTimer = timer
    }

    private func performScheduledDailyCheck() async {
        runAutomaticCheck()
        await waitUntilIdle()
        scheduleNextDailyCheck()
    }

    private func waitUntilIdle() async {
        while isChecking {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private func observeTimezoneChanges() {
        if let timezoneObserver {
            NotificationCenter.default.removeObserver(timezoneObserver)
        }
        timezoneObserver = NotificationCenter.default.addObserver(
            forName: .NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.scheduleNextDailyCheck()
            }
        }
    }

    private func nextDailyCheckDate(after date: Date) -> Date? {
        let calendar = localCalendar
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = dailyCheckHour
        components.minute = dailyCheckMinute
        components.second = 0
        guard var target = calendar.date(from: components) else { return nil }
        if target <= date {
            target = calendar.date(byAdding: .day, value: 1, to: target) ?? target
        }
        return target
    }

    private func todayDailyCheckDate() -> Date? {
        let calendar = localCalendar
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = dailyCheckHour
        components.minute = dailyCheckMinute
        components.second = 0
        return calendar.date(from: components)
    }

    /// 启动补检：今日 10:00 已过且尚未检查过今日场次，或距上次查询超过 24 小时。
    private func needsLaunchCatchUpCheck() -> Bool {
        let lastCheck = UserDefaults.standard.double(forKey: lastCheckKey)
        if lastCheck == 0 { return true }

        let lastDate = Date(timeIntervalSince1970: lastCheck)
        let now = Date()

        if let todaySlot = todayDailyCheckDate(), now >= todaySlot, lastDate < todaySlot {
            return true
        }

        return now.timeIntervalSince(lastDate) >= launchCatchUpInterval
    }

    private func runAutomaticCheck() {
        guard !isChecking else { return }
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
                let version = service.stripVersionPrefix(release.tagName)
                if automatic, shouldSkipAutomaticReminder(for: version) {
                    recordCheckTime()
                    return
                }

                if !automatic {
                    UpdateCheckingIndicator.shared.dismiss()
                }

                recordCheckTime()
                UpdateAvailablePanel.show(
                    release: release,
                    currentVersion: UpdateService.currentVersion,
                    version: version,
                    onDismiss: { [self] completed in
                        guard automatic else { return }
                        if completed {
                            UserDefaults.standard.removeObject(forKey: dismissedVersionKey)
                        } else {
                            UserDefaults.standard.set(version, forKey: dismissedVersionKey)
                        }
                    }
                )
            } else {
                recordCheckTime()
                if !automatic {
                    UpdateCheckingIndicator.shared.dismiss()
                    UpdatePrompt.showUpToDate(currentVersion: UpdateService.currentVersion)
                }
            }
        } catch {
            if !automatic {
                UpdateCheckingIndicator.shared.dismiss()
                UpdatePrompt.showError(error)
            }
        }
    }

    private func shouldSkipAutomaticReminder(for version: String) -> Bool {
        UserDefaults.standard.string(forKey: dismissedVersionKey) == version
    }

    private func recordCheckTime() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastCheckKey)
    }
}
