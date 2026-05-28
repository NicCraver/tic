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

- Swift 6.0, SwiftUI, macOS 14.0+
- XcodeGen (`project.yml`)
- Menu Bar only（`LSUIElement: true`）

## Architecture

- 入口：`Tic/Sources/TicApp.swift`
- 状态栏标签：`Tic/Sources/MenuBarDateLabel.swift`（`ImageRenderer` 定宽位图；`MenuBarDisplayComposer.swift` 拼文案）
- 日历弹出层：`Tic/Sources/CalendarPopoverView.swift`
- 设置：`Tic/Sources/SettingsView.swift`（窗口见 `SettingsWindowManager.swift`，侧栏实现与踩坑见 [`docs/settings-sidebar.md`](docs/settings-sidebar.md)）
- 登录启动：`Tic/Sources/LaunchAtLoginManager.swift`

## 踩坑文档（改相关功能前先读）

| 主题 | 文档 | 何时查阅 |
|------|------|----------|
| 设置窗口、全高侧栏、毛玻璃 | [`docs/settings-sidebar.md`](docs/settings-sidebar.md) | `SettingsWindow*`、`NavigationSplitView` 侧栏、⌘, 设置崩溃 |
| 菜单栏标签定宽、抖动、颜色、字重 | [`docs/menu-bar-label.md`](docs/menu-bar-label.md) | `MenuBarExtra` label、`MenuBarDateLabel`、`ImageRenderer`、状态栏空白/黑字/随壁纸变色 |

**菜单栏标签**：不要再用 label 内纯 `Text` + `.frame` 或自建 `NSStatusItem` 自绘；以 [`docs/menu-bar-label.md`](docs/menu-bar-label.md) 中的 **ImageRenderer + 模板图** 方案为准。

## Versioning

- `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION` 在 `project.yml` 中维护
