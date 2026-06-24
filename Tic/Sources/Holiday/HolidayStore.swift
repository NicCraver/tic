import Foundation

/// 法定节假日 / 调休（休/班）数据源。
///
/// 节气、农历、公历/农历节日都能本地推算；唯独「法定放假 / 调休」依赖国务院逐年公布，
/// 无法算法化。本类仅读取 App 内置 `holidays/{year}.json`（holiday-cn 格式），
/// 新年份数据随版本发版更新。
///
/// 线程安全：所有可变状态由 `lock` 保护。
final class HolidayStore: @unchecked Sendable {
    static let shared = HolidayStore()

    private let lock = NSLock()
    private var byKey: [String: DayAnnotation] = [:]
    private var coveredYearSet: Set<Int> = []

    private init() {
        loadBundled()
    }

    /// 查询某日的调休标注；键为 `"yyyy-MM-dd"`（东八区当地日）。
    func annotation(forKey key: String) -> DayAnnotation? {
        lock.lock(); defer { lock.unlock() }
        return byKey[key]
    }

    /// 内置数据覆盖的最大年份；无任何数据时为 0。
    var maxCoveredYear: Int {
        lock.lock(); defer { lock.unlock() }
        return coveredYearSet.max() ?? 0
    }

    /// 某年是否缺少内置调休数据（用于 UI 非阻断提示）；无任何数据时不提示，避免误报。
    func isYearUncovered(_ year: Int) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return !coveredYearSet.isEmpty && !coveredYearSet.contains(year)
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

    private func apply(days: [HolidayFile.Day]) {
        for day in days {
            // 放假：节日名 + 休；补班：无副标题 + 班（与历史内置数据语义一致）
            byKey[day.date] = DayAnnotation(
                subtitle: day.isOffDay ? day.name : nil,
                badge: day.isOffDay ? .rest : .work
            )
        }
    }

    private func loadBundled() {
        // XcodeGen 将 `Tic/Resources/holidays/*.json` 复制到 bundle 根目录（非 holidays/ 子目录）。
        let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []

        lock.lock(); defer { lock.unlock() }
        for url in urls {
            let name = url.deletingPathExtension().lastPathComponent
            guard let year = Int(name),
                  let data = try? Data(contentsOf: url),
                  data.count <= Self.maxJSONBytes,
                  let parsed = HolidayStore.parse(data),
                  parsed.year == year,
                  !parsed.days.isEmpty
            else { continue }
            apply(days: parsed.days)
            coveredYearSet.insert(year)
        }
    }

    private static let maxJSONBytes = 2 * 1024 * 1024
}
