# Agent Guidelines for Tic

## 交流语言

与用户交流时**始终使用中文**（说明、提问、总结、commit message 等）。代码标识符、API 名称、文件路径保持英文原文。

## Single Source of Truth

`project.yml` 是项目配置的唯一来源。不要直接编辑 `.pbxproj` 或 `Info.plist`，修改 `project.yml` 后运行 `xcodegen generate`。

## Build & Run

```bash
brew install xcodegen
xcodegen generate
open Tic.xcodeproj  # Cmd+R 运行
```

## Agent 开发流程

修改会影响运行的代码后，**必须在结束任务前**重新编译并启动应用，确认无编译错误。

项目已配置 `.cursor/hooks/`：Agent 编辑运行时相关文件时会标记 `.cursor/.needs-restart`，在 Cursor **stop hook** 触发时自动执行 `scripts/restart-dev.sh`。若 hook 未生效（例如非 Cursor Agent 环境），Agent 仍应**手动**运行 `scripts/restart-dev.sh`。

### 何时需要重启

| 需要 | 不需要 |
|------|--------|
| `Tic/Sources/`、`Tic/Resources/`、`TicTests/` | 仅 `docs/`、`.md` 等文档 |
| `project.yml`（改后脚本会自动 `xcodegen generate`） | 仅 CI / GitHub Actions 配置 |

### 重启命令

Agent 完成代码修改后，**自动执行**（无需询问用户）：

```bash
scripts/restart-dev.sh
```

脚本流程：结束已有 Tic 进程 → Debug 编译（输出到 `build/DerivedData`）→ 启动 `Tic.app`。

编译失败时先修复错误，再重新运行脚本，不要带着编译错误结束任务。

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
- 检查更新 / 应用内下载：`Tic/Sources/Update/`（GitHub Releases API + DMG 下载；见 [`docs/app-update.md`](docs/app-update.md)）

## 踩坑文档（改相关功能前先读）

| 主题 | 文档 | 何时查阅 |
|------|------|----------|
| 设置窗口、全高侧栏、毛玻璃 | [`docs/settings-sidebar.md`](docs/settings-sidebar.md) | `SettingsWindow*`、`NSSplitViewController` 侧栏、⌘, 设置崩溃 |
| 菜单栏标签定宽、抖动、颜色、字重 | [`docs/menu-bar-label.md`](docs/menu-bar-label.md) | `MenuBarExtra` label、`MenuBarDateLabel`、`ImageRenderer`、状态栏空白/黑字/随壁纸变色 |
| 检查更新、应用内 DMG 下载 | [`docs/app-update.md`](docs/app-update.md) | `Update*`、`UpdateChecker`、发版与客户端更新联动 |

**菜单栏标签**：不要再用 label 内纯 `Text` + `.frame` 或自建 `NSStatusItem` 自绘；以 [`docs/menu-bar-label.md`](docs/menu-bar-label.md) 中的 **ImageRenderer + 模板图** 方案为准。

**设置窗口**：纯 AppKit（`NSSplitViewController` + 各 `NSViewController`），**不要**改回 SwiftUI `NavigationSplitView` 或 `Settings { }` 场景；侧栏为 `NSTableView(.sourceList)` 系统原生选中。详见 [`docs/settings-sidebar.md`](docs/settings-sidebar.md)。

## Versioning

- `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION` 在 `project.yml` 中维护
