# 节假日 / 调休数据源方案（多源冗余 + 统一格式）

> 背景：节气、农历节日、公历固定节日都能本地算法计算（永久有效，见 `SolarTermSupport` / `ChineseCalendarSupport`）。
> **唯一无法算法化的是「法定放假 / 调休」**——它是国务院每年行政公布的政策，无规律可推。本方案用**免费、无 key 的静态 JSON 源**联网获取这一项，并做多源冗余、统一格式、离线兜底。

## 实现状态（2026-06-01，已落地）

核心已实现于 [`Tic/Sources/Holiday/HolidayStore.swift`](../Tic/Sources/Holiday/HolidayStore.swift)：

- **打包兜底**：[`Tic/Resources/holidays/{2024,2025,2026}.json`](../Tic/Resources/holidays/)（holiday-cn 原格式裁剪），离线 / 首启即可用。
- **联网刷新**：启动时（`AppDelegate`）从 holiday-cn 拉取**当年 + 次年**（**固定 commit pin**，非 `@master`），jsDelivr 主、GitHub raw 备；响应 ≤ 2MB、解析后 `year` 须与请求一致；节流 24h；成功写入 `Application Support/Tic/holidays/{year}.json`，下次启动优先于打包数据。
- **统一格式**：解析为 `DayAnnotation`（`subtitle` = 放假节日名 / 补班为 nil，`badge` = 休/班），`ChineseCalendarSupport` 通过 `HolidayStore.shared.annotation(forKey:)` 查询，零摩擦替换原硬编码字典。
- **线程安全**：`HolidayStore` 用 `NSLock` 保护内部表，刷新在后台 Task，完成后主线程广播 `.holidayDataDidUpdate`，月历清缓存重建。
- **隐私开关**：设置「日历」分区新增「自动更新节假日数据」（默认开），关闭则只用打包数据。
- **农历节日已脱钩**：春节/元宵/端午/七夕/中秋/重阳/腊八/小年/除夕等改为 `ChineseCalendarSupport.lunarFestival` 由 `.chinese` 农历本地推算；节日**倒计时**也改为公历固定 + 农历 + 节气推算，不再依赖调休数据（任意年份有效）。

**与下文完整方案的差异**：当前仅接入**主源 holiday-cn**（含 jsDelivr + GitHub raw 两个节点）；备源 cg-zhou / lanceliao 暂未接入，留作后续冗余增强。下文为完整设计，按需扩展。

## 设计原则

1. **只联网拉「调休」一项**：节气 / 农历 / 固定节日仍本地算，联网面最小化；即使所有源失效，日历主体功能照常。
2. **免费、无 apikey、静态 JSON**：不用实时公益 API（`timor.tech` 已上 Cloudflare 人机验证，程序拉不动）。
3. **两层冗余**：
   - **数据源冗余**：3 个独立项目（主 + 2 备），任一停更/失效可切换。
   - **节点冗余**：每个源有多个 CDN 镜像（jsDelivr / GitHub raw / 大陆镜像）。
4. **统一格式**：3 个源字段各不相同，各写一个 adapter 归一到同一内部模型。
5. **离线兜底**：app bundle 打包一份当年 JSON；联网成功覆盖缓存，失败用缓存 / 打包版。
6. **不轮询**：调休一年才变几次，启动时节流到「每天最多一次」即可。
7. **隐私**：只拉静态文件，不上报任何用户数据；设置里提供开关并注明数据来源。

## 统一内部模型

```swift
/// 归一后的单日调休记录。
struct HolidayDay {
    let date: Date      // 东八区当地日（startOfDay）
    let name: String    // 节日名，如「国庆节」「春节」
    let isOffDay: Bool  // true = 放假(休)，false = 补班(班)
}
```

对接现有代码零摩擦：`HolidayDay` → `DayAnnotation(subtitle: name, badge: isOffDay ? .rest : .work)`，可直接替换 `ChineseCalendarSupport.annotations` 那张硬编码字典。

## 数据源清单（按优先级，均已实测可达）

| 优先级 | 项目 | 按年 URL（jsDelivr）| 格式特征 |
|--------|------|---------------------|----------|
| 主 | `NateScarlet/holiday-cn` | `…/gh/NateScarlet/holiday-cn@master/{year}.json` | `days[].isOffDay`（bool），逐天 |
| 备1 | `cg-zhou/holiday-calendar` | `…/gh/cg-zhou/holiday-calendar@main/data/CN/{year}.json` | `dates[].type`（枚举），逐天 |
| 备2 | `lanceliao/china-holiday-calender` | `…/gh/lanceliao/china-holiday-calender@master/holidayAPI.json` | `Years[year][]` 区间 + 补班 |

CDN 前缀：`https://cdn.jsdelivr.net`

### 各源原始格式（实测样例）

**主源 holiday-cn** —— 最简洁，逐天 + bool：
```json
{ "year": 2026,
  "papers": ["https://www.gov.cn/.../content_7047091.htm"],
  "days": [ { "name": "元旦", "date": "2026-01-01", "isOffDay": true } ] }
```

**备1 cg-zhou** —— 逐天 + 枚举 type：
```json
{ "year": 2026, "region": "CN",
  "dates": [
    { "date": "2026-01-01", "name": "元旦", "type": "public_holiday" },
    { "date": "2026-01-04", "name": "元旦补班", "type": "transfer_workday" } ] }
```

**备2 lanceliao** —— 单文件，按年分组，**区间**需展开：
```json
{ "Years": { "2026": [
  { "Name": "元旦", "StartDate": "2026-01-01", "EndDate": "2026-01-03",
    "Duration": 3, "CompDays": ["2026-01-04"], "URL": "https://www.gov.cn/..." } ] } }
```

## 节点（CDN）冗余

同一份数据用多个 CDN 兜底，逐个尝试（应对单一 CDN 故障 / 大陆访问波动）：

1. jsDelivr：`https://cdn.jsdelivr.net/gh/{owner}/{repo}@{ref}/{path}`
2. GitHub raw：`https://raw.githubusercontent.com/{owner}/{repo}/{ref}/{path}`
3. 大陆镜像（可选，**接入前需自测可达性**）：如 ghproxy 类反代、或自托管到稳定对象存储 / 自有域名。

> ⚠️ jsDelivr 与 GitHub raw 在大陆**时好时坏**。目标用户是中国用户，务必实测；最稳妥是「打包兜底 + 自托管一份镜像」。

## 适配器（统一格式）

每个源一个 parser，输出 `[HolidayDay]`：

```swift
protocol HolidaySource {
    var id: String { get }
    func urls(forYear year: Int) -> [URL]      // 同源的多个 CDN 节点
    func parse(_ data: Data, year: Int) throws -> [HolidayDay]
}
```

归一规则：

| 源 | 放假(isOffDay=true) | 补班(isOffDay=false) | 备注 |
|----|---------------------|----------------------|------|
| holiday-cn | `days[].isOffDay == true` | `== false` | 直接映射 |
| cg-zhou | `type == "public_holiday"` | `type == "transfer_workday"` | 过滤 `region == "CN"` |
| lanceliao | `StartDate…EndDate` 每天 | `CompDays[]` 每天 | 区间需按天展开；先按 `year` 取段 |

## 拉取与容错流程

```
fetchHolidays(year) →
  for source in [holiday-cn, cg-zhou, lanceliao]:        // 数据源优先级
      for url in source.urls(forYear: year):             // 节点冗余
          data = GET url (超时 ~10s)
          if 网络失败 / 非200 → 下一个 url
          days = try source.parse(data, year)
          if 校验通过(days) → 写缓存(year, days) ; return days   // 命中即止
  // 所有源 × 所有节点都失败：
  return 本地缓存(year) ?? bundle 打包(year)
```

**校验**（防脏数据 / 格式悄悄变更）：
- `days` 非空（一年至少有元旦/国庆等若干放假日）。
- 全部 `date` 落在目标 `year`。
- 放假天数在合理区间（如 7~40 天）。

## 缓存、更新频率、兜底

- **缓存位置**：`Application Support/Tic/holidays/{year}.json`（归一后或原始均可，建议存归一后）。记录 `lastFetchedAt`。
- **更新时机**：app 启动 / 打开日历时检查；若 `now - lastFetchedAt > 24h` 才后台拉取**当年 + 次年**。**不轮询**。
- **bundle 兜底**：打包当前已知年份 JSON 进 `Resources`，首次启动 / 全失败时使用，保证离线与首启可用。

## 与现有代码对接（改造点）

- 新增 `Holiday/`：`HolidaySource` 协议 + 3 个 adapter + `HolidayStore`（拉取 / 缓存 / 兜底 / 归一）+ bundle 资源。
- `ChineseCalendarSupport`：把硬编码 `annotations` 字典换成「向 `HolidayStore` 查询某日 `DayAnnotation`」；`isFirstAnnotatedHoliday` 等逻辑不变（仍基于逐天数据）。
- `HolidayStore` 异步加载完成后发通知（复用 `.menuBarSettingsDidChange` 思路或新增 `.holidayDataDidUpdate`），让月历刷新。

## 隐私与设置开关

- 设置「日历」分区新增开关：**自动更新节假日数据**（建议默认开，可关）。
- 关闭后只用 bundle 打包数据；开启则按上述流程联网。
- 「关于」或开关副标题注明：数据来自国务院公告（开源项目 holiday-cn 等聚合），仅下载公开静态文件、不上传任何信息。

## 风险与对策

| 风险 | 对策 |
|------|------|
| CDN 大陆不可达 | 多节点 + 大陆镜像 / 自托管 + bundle 兜底 |
| 某源停止维护 | 3 源冗余，优先级降级 |
| 源格式变更 | 解析失败即跳下一源 + 数据校验 + 兜底 |
| 次年数据未发布 | 国务院一般年底公布；查不到次年时静默用当年，下次再试 |

## 附录：实测记录（2026-05）

| 端点 | 结果 |
|------|------|
| `cdn.jsdelivr.net/gh/NateScarlet/holiday-cn@master/2026.json` | ✅ 200，`days[].isOffDay` |
| `cdn.jsdelivr.net/gh/cg-zhou/holiday-calendar@main/data/CN/2026.json` | ✅ 200，`dates[].type` |
| `cdn.jsdelivr.net/gh/lanceliao/china-holiday-calender@master/holidayAPI.json` | ✅ 200，`Years[].区间` |
| `timor.tech/api/holiday/year/2026` | ❌ Cloudflare 人机验证，程序不可用 |
| `vsme/chinese-days` | ⛔ 无按年 JSON（数据在 TS 包），不作静态源 |
