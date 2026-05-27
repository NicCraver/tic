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
- 状态栏标签：`Tic/Sources/MenuBarDateLabel.swift`
- 日历弹出层：`Tic/Sources/CalendarPopoverView.swift`
- 设置：`Tic/Sources/SettingsView.swift`
- 登录启动：`Tic/Sources/LaunchAtLoginManager.swift`

## Versioning

- `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION` 在 `project.yml` 中维护
