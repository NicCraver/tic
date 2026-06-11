目录

[概览](#overview)
[数据来源与依赖](#sources)
[数据流：一个日期 → 一格](#flow)

模块分解

[A. 菜单栏日期/时间](#m-display)
[B. 农历与干支](#m-lunar)
[C. 二十四节气](#m-term)
[D. 节日与倒计时](#m-festival)
[E. 月历网格与缓存](#m-grid)

缺陷

[已修复（①②③④⑤）](#fixed)
[中等（已清空）](#d-major)
[轻微（已修复⑥–⑩）](#d-minor)
[做得好的地方](#good)
[改进建议](#roadmap)

# Tic · 日期与节假日逻辑实现说明

当前实现如何计算公历 / 农历 / 干支 / 二十四节气 / 法定节假日与调休，以及存在哪些缺陷。

生成 2026-06-01 · 缺陷清单已全部处理
核心 ChineseCalendarSupport · SolarTermSupport · Holiday/HolidayStore
依赖 LunarSwift (SPM)
面向：维护者 / Agent

## 概览

日期相关能力由四类数据拼装而成，**能算的都本地算，不能算的（法定调休）才联网获取**：

| 能力 | 来源 | 覆盖年份 | 说明 |
| --- | --- | --- | --- |
| 公历日期 / 星期 / 周数 | 系统 `Calendar(.gregorian)`（zh\_CN） | 任意 | 格式化、网格排布、周数 |
| 农历 年/月/日 + 闰月 | 系统 `Calendar(.chinese)` | 任意 | 苹果内置算法 |
| 干支（年/月/日）+ 生肖 | 年/月自实现 + 日柱 **LunarSwift** | 任意 | 日柱已改库计算 |
| 二十四节气 | **LunarSwift** 天文算法 | 任意 | 已替换硬编码；并修复漏「冬至」别名 bug |
| 公历固定/动态节日 | 自实现表 + 第 n 个周几 | 任意 | 元旦、劳动节、国庆、儿童节、母亲节… |
| 农历传统节日（春节/端午/中秋…） | **由 `.chinese` 农历推算**（含除夕） | **任意** | 缺陷②已修复 |
| **法定节假日 / 调休（休/班）** | **`HolidayStore`**：打包 JSON + 联网 holiday-cn | **打包 2024–2026 + 联网当年/次年** | 缺陷①已修复 |

**更新（2026-06-01）：严重与中等缺陷均已修复。**农历传统节日改由 `.chinese` 本地推算；法定调休改由 Holiday/HolidayStore.swift；日柱改 LunarSwift；农历/节气统一 `Asia/Shanghai`；节气缓存加锁。详见 [已修复](#fixed)。

## 数据来源与依赖

### ① 系统日历

ChineseCalendarSupport.swift

`gregorian`（locale `zh_CN`，时区 `Asia/Shanghai`）负责公历换算；`chinese`（同东八区）负责农历年/月/日与 `isLeapMonth`。与 LunarSwift、`HolidayStore` 的「当天」边界一致。

### ② LunarSwift（SPM）

SolarTermSupport.swift · project.yml

`SolarTermSupport` 与 `ChineseCalendarSupport` 的日柱均使用。节气：`jieQiTable`；日干支：`lunar.dayInGanZhi`。交节与农历日界按东八区 `startOfDay`，按年缓存（`NSLock`）。

### ③ HolidayStore（调休）

Holiday/HolidayStore.swift

打包 `Resources/holidays/{2024,2025,2026}.json` 兜底 + 启动联网 holiday-cn（jsDelivr 主、GitHub raw 备）刷新当年/次年，缓存到 Application Support。归一为 `DayAnnotation`（休/班 + 节日名），`NSLock` 保护。

### ④ 公历节日表

ChineseCalendarSupport.swift:118–133, 579–590

固定日期节日（元旦、情人节、妇女节、青年节、儿童节、教师节、圣诞…）+ 动态节日（母亲节=5 月第 2 个周日、父亲节=6 月第 3 个周日），均可任意年份计算。

## 数据流：一个日期是怎么变成日历里一格的

月历每格内容由 `dayCellMetadata(for:showSolarTerms:)` 汇总 ChineseCalendarSupport.swift:185–220：

**输入日期**Date

→

**查调休**HolidayStore
休/班 + 节日名

→

**查节气**SolarTermSupport
LunarSwift

→

**公历节日**solarFestival()

→

**农历节日**lunarFestival()
含除夕

→

**兜底农历日**初一 / 廿三…

副标题优先级：**节气 → 公历节日 → 农历节日 → 调休节日名**，皆空时回退到农历日（除夕优先于法定「春节」名显示）。是否显示提示圆点由 `hasAnnotation` 决定（有 badge、法定/公历/农历节日或节气即为 true）。

```
// dayCellMetadata 摘要（已简化）
if let term = solarTerm { subtitles.append(term) }              // 节气
if let f = festival?.cellTitle { subtitles.append(f) }          // 公历节日
if let f = lunarFest?.cellTitle { subtitles.append(f) }         // 农历节日（含除夕）
if let s = ann?.subtitle { subtitles.append(s) }               // 调休（HolidayStore）
// 全空 → [lunarDayLabel(for: date)]（农历日）
```

## 模块 A · 菜单栏日期 / 时间

MenuBarDisplayComposer.swift · MenuBarLabelMetrics.swift

菜单栏文案为「模块化拼接」，块（`MenuBarBlock`）包括：日期 `M月d日`、星期 `EEE`、周数 `(n)`、农历（农历月日）、时间（12/24 小时、可选秒）。用 `DateFormatter`（locale `zh_CN`）格式化。

* **定宽防抖**：`widestCompose` 生成最宽占位串，配合 `ImageRenderer` 定宽位图，秒数跳动时菜单栏项宽度不变（详见 docs/menu-bar-label.md）。
* **刷新频率**：含秒 1 秒、否则 60 秒 MenuBarLabelMetrics.swift:38。
* 周数取自 `ChineseCalendarSupport.weekOfYear`（与月历网格同为周一为首日）。

## 模块 B · 农历与干支

ChineseCalendarSupport.swift:239–258, 413–492

* **农历日 / 月日**：直接取 `chinese` 日历的 `.day` / `.month` + `isLeapMonth`，映射到「初一…三十」「正月…腊月」，闰月加「闰」前缀。**苹果算法，任意年份。**
* **干支年** + 生肖：基于 `chinese.year` 在 60 甲子里取干支。
* **干支月**：以**立春**为年界、按节气定地支、由年干用「五虎遁」推月干，依赖 `SolarTermSupport` 的节气日期。
* **干支日**：由 LunarSwift `Solar.fromYmdHms(...).lunar.dayInGanZhi` 输出（东八区公历日），已去除硬编码锚点。
* **相对日期**：今天 / 明天 / 昨天 / N 天前后。

## 模块 C · 二十四节气

SolarTermSupport.swift:48–73

取「年初」「年末」两个农历实例的 `jieQiTable` 合并，过滤出 24 个标准中文名、且交节年份等于目标公历年的项，按 `startOfDay` 入两张表（按日期查名、按名查日期），并整年缓存。对外 API 与旧硬编码实现保持一致，故 `ChineseCalendarSupport` 无需改动。

```
for (key, solar) in lunar.jieQiTable {
    let name = jieQiAliases[key] ?? key   // DONG_ZHI → 冬至
    guard standardNames.contains(name), solar.year == year else { continue }
    byDate[day] = name; byName[name] = day
}
```

相对旧版的明显改进：**从「2025–2027 硬编码查表」升级为天文算法**，任意年份有效。
**已修复 bug：**`jieQiTable` 把年末「冬至」存在英文别名 key `"DONG_ZHI"` 下，旧代码只收中文名 key，导致每年漏掉冬至（24→23）；现按别名归一后再按公历年过滤，单元测试已覆盖。

## 模块 D · 节日与倒计时

ChineseCalendarSupport.swift

`upcomingEvents(from:limit:)` 在 **start … start+370 天**窗口内汇集候选并排序。**已改为全部本地推算**（不再依赖调休数据），任意年份都有倒计时：

| 来源 | priority | 取自 |
| --- | --- | --- |
| 公历节日（固定 + 动态） | 1 | `solarFestivalTemplates`（含元旦/劳动节/国庆）+ 母亲/父亲节 |
| 农历节日 | 1 | `appendLunarFestivalEvents`（春节/端午/中秋/元宵/七夕… 按农历日期） |
| 二十四节气 | 2 | `SolarTermSupport.terms(in:)` |

同名同日去重后取 `limit` 个；「下一个节日倒计时」即 `limit=1`。倒计时文案：今天 / 明天 / N 天后。

改动：原先「法定节日（放假首日）」候选来自硬编码字典、止于 2027；现倒计时锚定**节日规范日**（春节=正月初一、国庆=10/1 等），任意年份有效。休/班角标仍由 `HolidayStore` 提供。

## 模块 E · 月历网格与缓存

ChineseCalendarSupport.swift:341–411 · CalendarPopoverDataCache.swift

* **月历网格**：`monthSlots(for:showSolarTerms:)`，**周一为首列**（`mondayBasedLeadingBlankCount`），每格带 subtitles / badge / hasAnnotation。
* **周数**：`weekOfYear` 与网格共用同一 `gregorian` 日历（`firstWeekday = 2`）。
* **缓存**：`CalendarPopoverDataCache` 对 monthSlots（上限 18）与 upcomingEvents（上限 90）做 LRU；节气按年缓存。

## 缺陷清单

已修复 严重 + 中等（①–⑤）+ 节气冬至
已修复 轻微项（⑥–⑩）

### 已修复 原严重缺陷（2026-06-01）

#### ① 法定节假日 / 调休：不再硬编码、不再止于 2027 已修复

原问题
:   休/班与法定节日名来自内置字典，仅 2025–2027（2027 仅元旦），跨年自然失效、需逐年手工维护。

方案
:   新增 Holiday/HolidayStore.swift：打包 `Resources/holidays/{2024,2025,2026}.json` 兜底；启动联网 holiday-cn（jsDelivr 主 + GitHub raw 备）刷新当年/次年，节流 24h，缓存到 Application Support；归一为 `DayAnnotation`，`NSLock` 保护。设置「日历」分区可关。

效果
:   当年/次年自动获取（国务院一公布即更新），离线有打包兜底，去除年份上限。

#### ② 农历传统节日：改由 `.chinese` 农历本地推算（含除夕） 已修复

原问题
:   农历节日全靠硬编码字典；元宵/七夕/重阳/腊八/小年等根本不显示，春节/端午/中秋也止于 2027。

方案
:   `ChineseCalendarSupport.lunarFestival` 用 `.chinese` 农历推算春节/元宵/龙抬头/端午/七夕/中元/中秋/重阳/腊八/小年；除夕按「次日为正月初一」判定；闰月不计。圆点与倒计时同步接入；并把劳动节/国庆补进公历固定节日表。

效果
:   任意年份显示完整农历节日；除夕优先于法定「春节」名显示。

#### ＋ 顺带修复：二十四节气漏「冬至」 已修复

原问题
:   LunarSwift `jieQiTable` 把年末冬至存于英文别名 key `"DONG_ZHI"`，旧代码只收中文名 → 每年 24 个节气漏掉冬至（实测返回 23）。

方案
:   别名归一（`DONG_ZHI→冬至` 等）后按公历年过滤；新增单元测试覆盖 2025–2027 各 24 项。

#### ③ 干支「日柱」改由 LunarSwift 计算 已修复

原问题
:   日干支由单一锚点 `2026-05-29 = 序号 39` 按天数偏移推算，无测试、易错。

方案
:   `sexagenaryDayLabel` 改为 `Solar.fromYmdHms(...).lunar.dayInGanZhi`（东八区公历日）；单元测试断言 2026-05-29 为「癸卯日」。

#### ④ 农历 / 节气统一 Asia/Shanghai 时区 已修复

原问题
:   `ChineseCalendarSupport` / `SolarTermSupport` 用设备默认时区，与 LunarSwift、holiday-cn 的北京时间日界不一致。

方案
:   `gregorian` 与 `chinese` 日历均设 `timeZone = Asia/Shanghai`；`SolarTermSupport` 的公历日历同步。

效果
:   跨时区用户看到的农历日、节气、调休与国务院公布日对齐。

#### ⑤ 节气缓存线程安全 已修复

原问题
:   `nonisolated(unsafe) static var cache` 无锁，并发 `compute` 可能数据竞争。

方案
:   改为 `YearTermCache`（`NSLock` + 双重检查），移除 `nonisolated(unsafe)`，满足 Swift 6 并发检查。

### 中等 Major

原缺陷 ③④⑤ 已于 2026-06-01 修复，见 [已修复](#fixed)。当前无未解决的中等项。

### 轻微 Minor（2026-06-01 已处理）

#### ⑥ 删除 `monthGrid` / `CalendarGridDay` 死代码 已修复

方案
:   移除周日首列的未使用网格构建器，仅保留 `monthSlots`。

#### ⑦ 周数与网格周首统一 已修复

方案
:   `gregorian.firstWeekday = 2`（周一），与 `mondayBasedLeadingBlankCount` 网格对齐。

#### ⑧ 菜单栏农历占位含「闰」 已修复

方案
:   `widestSegment(.lunar)` 占位改为「闰十一月三十」。

#### ⑨ 补边界测试 已修复

方案
:   新增闰月前缀、2030 年 24 节气、周一首列槽位、国庆连休仅首日显示节日名等测试（共 13 项）。

#### ⑩ 连休节日名去重更抗数据缺口 已修复

方案
:   `isFirstAnnotatedHoliday` 向前最多 14 天查找同 subtitle 的休日，跳过中间缺失条目，避免缺前一天数据时重复显示「国庆节」等。

## 优点 实现得不错的地方

* **节气算法化**：LunarSwift 天文算法，东八区日界，按年缓存且线程安全。
* **日柱库算**：日干支由 LunarSwift 输出，与节气同源，有单元测试。
* **时区一致**：农历 / 节气 / 调休均以 `Asia/Shanghai` 为「当天」边界。
* **调休数据动态化**：`HolidayStore` 打包 + 联网 holiday-cn + 缓存兜底，去除年份上限、线程安全。
* **农历节日本地推算**：春节/元宵/端午/七夕/中秋…（含除夕）；倒计时锚定节日规范日，任意年份有效。
* **菜单栏定宽防抖**：ImageRenderer 定宽位图 + 模板图随壁纸/深浅色自动着色。
* **性能缓存**：月历 slots 与倒计时结果 LRU 缓存，节气整年缓存，避免重复计算。
* **关注点分离**：节气、农历节日、法定调休（HolidayStore）解耦，对外 API 稳定。

## 改进建议（按收益排序）

| # | 项目 | 对应缺陷 | 收益 |
| --- | --- | --- | --- |
| ✅ | 联网调休数据源 + 离线兜底（`HolidayStore`，主源 holiday-cn） | ①、10 | 已完成 · 去除年份上限；3 源冗余待加 |
| ✅ | 农历节日表（从 .chinese 推算，含除夕） | ② | 已完成 |
| ✅ | 统一固定 Asia/Shanghai 时区 | ④ | 已完成 |
| ✅ | 干支日改用 LunarSwift + 测试 | ③ | 已完成 |
| ✅ | 节气缓存线程安全（`YearTermCache`） | ⑤ | 已完成 |
| ✅ | Minor ⑥–⑩（死代码、周首、闰占位、测试、连休去重） | ⑥–⑩ | 已完成 |

联网数据源的完整设计（统一模型、3 源冗余、CDN 兜底、缓存与隐私开关）见 docs/holiday-data-source.md。

本文据 2026-06-01 工作区源码生成，文件行号以当时 Tic/Sources/ 为准；改动相关代码后请同步更新。