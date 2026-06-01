import Foundation

extension Notification.Name {
    /// 联网刷新拿到新调休数据后广播，供月历 / 菜单栏刷新。
    static let holidayDataDidUpdate = Notification.Name("holidayDataDidUpdate")
}

/// 法定节假日 / 调休（休/班）数据源。
///
/// 节气、农历、公历/农历节日都能本地推算（见 `SolarTermSupport` / `ChineseCalendarSupport`），
/// 唯独「法定放假 / 调休」是国务院逐年公布、无规律可循，无法算法化。本类负责这一项：
/// - **打包兜底**：bundle 内 `holidays/{year}.json`（holiday-cn 格式）保证离线 / 首启可用；
/// - **联网刷新**：启动时从 holiday-cn 拉取当年 + 次年（jsDelivr，失败回退 GitHub raw），节流 24h；
/// - **本地缓存**：成功结果写入 Application Support，下次启动优先于打包数据。
///
/// 线程安全：所有可变状态由 `lock` 保护，读取可在任意线程（`ChineseCalendarSupport` 在主线程调用）。
final class HolidayStore: @unchecked Sendable {
    static let shared = HolidayStore()

    private let lock = NSLock()
    private var byKey: [String: DayAnnotation] = [:]
    private var loadedYears: Set<Int> = []

    private let session: URLSession
    private let beijing: Calendar
    private let lastFetchKey = "holidayLastFetchedAt"

    private init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        beijing = calendar

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.waitsForConnectivity = false
        session = URLSession(configuration: config)

        loadBundledSeed()
        loadCached()
    }

    // MARK: - 读取（线程安全）

    /// 查询某日的调休标注；键为 `"yyyy-MM-dd"`（东八区当地日）。
    func annotation(forKey key: String) -> DayAnnotation? {
        lock.lock(); defer { lock.unlock() }
        return byKey[key]
    }

    // MARK: - 刷新

    /// 启动时调用：开关开启且距上次拉取超过 24h 时，后台刷新当年 + 次年。
    func refreshIfNeeded() {
        guard AppSettings.bool(forKey: AppSettings.autoUpdateHolidaysKey, default: true) else { return }
        if let last = UserDefaults.standard.object(forKey: lastFetchKey) as? Date,
           Date().timeIntervalSince(last) < 24 * 3600 {
            return
        }
        let thisYear = beijing.component(.year, from: Date())
        Task.detached(priority: .utility) { [weak self] in
            await self?.refresh(years: [thisYear, thisYear + 1])
        }
    }

    private func refresh(years: [Int]) async {
        var didUpdate = false
        for year in years {
            guard let data = await fetch(year: year),
                  let parsed = HolidayStore.parse(data),
                  !parsed.days.isEmpty
            else { continue }
            apply(year: parsed.year, days: parsed.days)
            writeCache(year: parsed.year, data: data)
            didUpdate = true
        }
        UserDefaults.standard.set(Date(), forKey: lastFetchKey)
        if didUpdate {
            NotificationCenter.default.post(name: .holidayDataDidUpdate, object: nil)
        }
    }

    private func fetch(year: Int) async -> Data? {
        for url in HolidayStore.urls(forYear: year) {
            guard let (data, response) = try? await session.data(from: url),
                  let http = response as? HTTPURLResponse, http.statusCode == 200
            else { continue }
            return data
        }
        return nil
    }

    private static func urls(forYear year: Int) -> [URL] {
        [
            "https://cdn.jsdelivr.net/gh/NateScarlet/holiday-cn@master/\(year).json",
            "https://raw.githubusercontent.com/NateScarlet/holiday-cn/master/\(year).json",
        ].compactMap(URL.init(string:))
    }

    // MARK: - 解析（holiday-cn 格式）

    private struct HolidayFile: Decodable {
        let year: Int
        let days: [Day]
        struct Day: Decodable {
            let name: String
            let date: String
            let isOffDay: Bool
        }
    }

    private static func parse(_ data: Data) -> (year: Int, days: [HolidayFile.Day])? {
        guard let file = try? JSONDecoder().decode(HolidayFile.self, from: data) else { return nil }
        return (file.year, file.days)
    }

    private func apply(year: Int, days: [HolidayFile.Day]) {
        lock.lock(); defer { lock.unlock() }
        for day in days {
            // 放假：节日名 + 休；补班：无副标题 + 班（与历史内置数据语义一致）
            byKey[day.date] = DayAnnotation(
                subtitle: day.isOffDay ? day.name : nil,
                badge: day.isOffDay ? .rest : .work
            )
        }
        loadedYears.insert(year)
    }

    // MARK: - 兜底与缓存

    private func loadBundledSeed() {
        for year in 2024...2026 {
            guard let url = Bundle.main.url(forResource: "\(year)", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let parsed = HolidayStore.parse(data)
            else { continue }
            apply(year: parsed.year, days: parsed.days)
        }
    }

    private func loadCached() {
        guard let dir = cacheDirectory(),
              let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        else { return }
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let parsed = HolidayStore.parse(data)
            else { continue }
            apply(year: parsed.year, days: parsed.days)
        }
    }

    private func writeCache(year: Int, data: Data) {
        guard let dir = cacheDirectory() else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: dir.appendingPathComponent("\(year).json"))
    }

    private func cacheDirectory() -> URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Tic/holidays", isDirectory: true)
    }
}
