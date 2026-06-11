# Changelog

本文件格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### Added

- （下一版本变更写在这里）

## [1.2.6] - 2026-06-11

### Fixed

- 修复应用内更新下载失败：允许 GitHub CDN（`release-assets.githubusercontent.com`）重定向，并修正 DMG 文件大小编读

## [1.2.5] - 2026-06-10

### Added

- 更新下载安全策略：DMG URL 域名白名单、文件名与版本校验、重定向拦截、落盘路径与体积限制
- 节假日联网数据 pin 固定 commit，响应大小与年份校验
- 文档 [`docs/app-update.md`](docs/app-update.md) 记录应用内更新方案与安全策略

### Changed

- 启动时菜单栏弹窗窗口配置去重，减少重复处理
- 日志由 `print` 改为 `os.Logger`

## [1.2.4] - 2026-06-10

### Changed

- 测试版本：用于验证 v1.2.3 应用内下载更新能否发现新版本并完成安装

## [1.2.3] - 2026-06-10

### Added

- 应用内下载更新：发现新版本后自动下载 DMG 并显示进度，完成后自动打开安装镜像（不再跳转浏览器）
- 检查更新时显示加载浮层；更新说明 Markdown 格式化展示

### Changed

- 关于页使用真实应用图标
- 新用户默认开启「登录时启动」

## [1.2.2] - 2026-06-10

### Changed

- 日历弹窗头部移除颜色模式快捷切换，避免月份标题被挤压；外观请在设置中调整

## [1.2.1] - 2026-06-10

### Changed

- 测试版本：用于验证 1.2.0 应用内「检查更新」能否发现新版本

## [1.2.0] - 2026-06-10

### Added

- 设置「关于」与应用菜单「检查更新…」：通过 GitHub Releases API 检测新版本并下载 DMG
- 启动后每 24 小时自动静默检查更新（有新版本时提示）
- Agent 开发流程：`restart-dev.sh` 与 Cursor hooks 支持改代码后自动编译重启

### Changed

- 日历弹窗高度随月历行数自适应，切换月份时保持菜单栏顶边锚定

## [1.1.1] - 2026-06-04

### Changed

- GitHub Release 改为 DMG 分发，镜像内含「应用程序」快捷方式便于拖放安装
- Release 构建增加 ad-hoc 整包签名；README 补充 Gatekeeper「已损坏」说明
- 应用图标资源更新（不透明 1024 母版）

## [1.1.0] - 2026-06-02

### Added

- 日历弹出层 UI 重构（月历网格、节假日/节气/休班标注）
- 法定节假日联网刷新（holiday-cn）与农历/公历节日推算
- 设置窗口改为 AppKit 侧栏（`NSSplitViewController` + source list）
- 弹层头部月份导航：上个月 / 今天 / 下个月
- 非「今天」视图时显示距下一法定休首日的倒计时胶囊

### Changed

- 应用图标更新为玻璃拟态日历风格
- 设置详情页标题置顶，分组采用圆角卡片样式

### Fixed

- 统一东八区时区处理，修复日柱库算与日历数据层若干缺陷

## [1.0.0] - 2026-05-28

### Added

- 菜单栏模块化日期/农历/时间显示
- 农历日历弹窗（节假日、节气、休班）
- 设置页：通用、外观、菜单栏、日历、快捷键、关于
- 登录时自动启动
- macOS 应用图标

[Unreleased]: https://github.com/NicCraver/tic/compare/v1.2.6...HEAD
[1.2.6]: https://github.com/NicCraver/tic/compare/v1.2.5...v1.2.6
[1.2.5]: https://github.com/NicCraver/tic/compare/v1.2.4...v1.2.5
[1.2.4]: https://github.com/NicCraver/tic/compare/v1.2.3...v1.2.4
[1.2.3]: https://github.com/NicCraver/tic/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/NicCraver/tic/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/NicCraver/tic/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/NicCraver/tic/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/NicCraver/tic/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/NicCraver/tic/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/NicCraver/tic/releases/tag/v1.0.0
