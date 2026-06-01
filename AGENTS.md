# Agent Guidelines for Tic

## Single Source of Truth

`project.yml` 是项目配置的唯一来源。不要直接编辑 `.pbxproj` 或 `Info.plist`，修改 `project.yml` 后运行 `xcodegen generate`。

## Build & Run

```bash
brew install xcodegen
xcodegen generate
open Tic.xcodeproj  # Cmd+R 运行
```

## Tech Stack

- Swift 6.0，SwiftUI（菜单栏 / 弹层）+ AppKit（设置窗口），macOS 14.0+
- XcodeGen (`project.yml`)
- Menu Bar only（`LSUIElement: true`）
- 依赖（SPM）：[LunarSwift](https://github.com/6tail/lunar-swift)——二十四节气天文算法，见 `SolarTermSupport.swift`

## Architecture

- 入口：`Tic/Sources/TicApp.swift`
- 状态栏标签：`Tic/Sources/MenuBarDateLabel.swift`（`ImageRenderer` 定宽位图；`MenuBarDisplayComposer.swift` 拼文案）
- 日历弹出层：`Tic/Sources/CalendarPopoverView.swift`
- 农历 / 节气：`Tic/Sources/ChineseCalendarSupport.swift`（农历换算、农历/公历节日推算）、`Tic/Sources/SolarTermSupport.swift`（二十四节气，LunarSwift 算法、按公历年缓存）
- 法定节假日 / 调休：`Tic/Sources/Holiday/HolidayStore.swift`（打包 `Resources/holidays/*.json` + 联网刷新 holiday-cn + 缓存兜底；见 [`docs/holiday-data-source.md`](docs/holiday-data-source.md)）
- 设置：AppKit 实现，入口 `SettingsWindowManager.show()` → `Settings/SettingsSplitViewController.swift`（侧栏 `SettingsSidebarViewController`、详情 `Settings/*SettingsViewController.swift`；实现与踩坑见 [`docs/settings-sidebar.md`](docs/settings-sidebar.md)）
- 登录启动：`Tic/Sources/LaunchAtLoginManager.swift`

## 踩坑文档（改相关功能前先读）

| 主题 | 文档 | 何时查阅 |
|------|------|----------|
| 设置窗口、全高侧栏、毛玻璃 | [`docs/settings-sidebar.md`](docs/settings-sidebar.md) | `SettingsWindow*`、`NSSplitViewController` 侧栏、⌘, 设置崩溃 |
| 菜单栏标签定宽、抖动、颜色、字重 | [`docs/menu-bar-label.md`](docs/menu-bar-label.md) | `MenuBarExtra` label、`MenuBarDateLabel`、`ImageRenderer`、状态栏空白/黑字/随壁纸变色 |

**菜单栏标签**：不要再用 label 内纯 `Text` + `.frame` 或自建 `NSStatusItem` 自绘；以 [`docs/menu-bar-label.md`](docs/menu-bar-label.md) 中的 **ImageRenderer + 模板图** 方案为准。

**设置窗口**：纯 AppKit（`NSSplitViewController` + 各 `NSViewController`），**不要**改回 SwiftUI `NavigationSplitView` 或 `Settings { }` 场景；侧栏为 `NSTableView(.sourceList)` 系统原生选中。详见 [`docs/settings-sidebar.md`](docs/settings-sidebar.md)。

## Versioning

- `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION` 在 `project.yml` 中维护
