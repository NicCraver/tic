# Changelog

本文件格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### Added

- （下一版本变更写在这里）

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

[Unreleased]: https://github.com/NicCraver/tic/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/NicCraver/tic/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/NicCraver/tic/releases/tag/v1.0.0
