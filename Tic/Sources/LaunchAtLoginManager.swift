import ServiceManagement

@MainActor
final class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    var isEnabled: Bool {
        AppSettings.bool(forKey: AppSettings.launchAtLoginKey, default: true)
    }

    /// 启动时按用户偏好同步登录项；新用户默认开启。
    func applyPreferredStateOnLaunch() {
        setEnabled(isEnabled)
    }

    func setEnabled(_ enabled: Bool) {
        AppSettings.setBool(enabled, forKey: AppSettings.launchAtLoginKey)
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("登录时启动设置失败: \(error.localizedDescription)")
        }
    }
}
