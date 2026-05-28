# Tic

[![CI](https://github.com/NicCraver/tic/actions/workflows/ci.yml/badge.svg)](https://github.com/NicCraver/tic/actions/workflows/ci.yml)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)

macOS 菜单栏日历工具：状态栏显示日期时间，点击弹出日历。

<!-- TODO: docs/images/menu-bar.png -->

## 功能

- 状态栏模块化显示：日期、星期、周数、农历、时间、图标可开关与排序
- 点击弹出农历日历：节假日、节气、休/班、节日倒计时
- 设置页：通用 / 外观 / 菜单栏 / 日历 / 快捷键 / 关于
- 主题跟随系统或浅色/深色
- 登录时自动启动
- 无 Dock 图标（纯菜单栏应用）

## 要求

- macOS 14+
- Xcode 16+（含 Swift 6）

## 从源码构建

```bash
git clone https://github.com/NicCraver/tic.git
cd tic
brew install xcodegen
xcodegen generate
open Tic.xcodeproj
# 在 Xcode 中 Cmd+R 运行
```

## 下载预编译版

见 [Releases](https://github.com/NicCraver/tic/releases)。

> **首次打开：** 若系统提示无法验证开发者，请 **右键应用 → 打开**，或在终端执行：
>
> ```bash
> xattr -cr /Applications/Tic.app
> ```
>
> （路径改为你实际安装位置。）

## 技术栈

- Swift 6 + SwiftUI
- MenuBarExtra（`.window` 弹出样式）
- XcodeGen

## 反馈

[提交 Issue](https://github.com/NicCraver/tic/issues)

## 参与贡献

欢迎 PR。发版与版本号约定见 [docs/releasing.md](docs/releasing.md)。

## License

MIT — 见 [LICENSE](LICENSE)。
