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

## 已完成（TODO）

实现与数据层改造见 [`docs/date-holiday-logic.html`](docs/date-holiday-logic.html)。

- [x] **法定调休联网**：`HolidayStore` 打包 JSON + holiday-cn 刷新，去除硬编码年份上限
- [x] **农历节日本地推算**：春节/元宵/端午/中秋等 + 除夕，任意年份有效
- [x] **二十四节气算法化**：LunarSwift 天文计算，修复漏「冬至」，按年缓存且线程安全
- [x] **日柱改库计算**：干支日由 LunarSwift `dayInGanZhi` 输出，去除魔法锚点
- [x] **时区统一**：农历 / 节气 / 调休均以 `Asia/Shanghai` 为日界
- [x] **月历与周数一致**：周一首列网格、`firstWeekday = 2`，删除 `monthGrid` 死代码
- [x] **菜单栏定宽**：闰月占位「闰十一月三十」，避免极端裁切
- [x] **连休节日名去重**：连休仅首日显示法定节日名，向前查找抗数据缺口
- [x] **单元测试**：节气、农历节日、休/班、日柱、闰月、远年、网格周首等（13 项）

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

见 [Releases](https://github.com/NicCraver/tic/releases)（`.dmg`）。打开镜像后，将 **Tic** 拖到 **Applications** 即可安装。

> **首次打开（未签名构建）：** 从浏览器下载后，macOS 可能提示 **「已损坏，无法打开」** 或 **无法验证开发者**——应用并未真的损坏，是 Gatekeeper 拦截未公证应用。任选其一：
>
> 1. 打开 DMG 后 **右键 `Tic.app` → 打开**（首次需确认），再拖入 **Applications**；或
> 2. 若已拖入 **Applications**，在终端清除隔离属性并打开：
>
>    ```bash
>    xattr -cr /Applications/Tic.app
>    open /Applications/Tic.app
>    ```
>
> 若隔离在 DMG 上，可对挂载卷内的应用执行 `xattr -cr`，或对下载的 `.dmg` 执行后再打开。
>
> 预编译包为 **Apple Silicon（arm64）**，需 macOS 14+。Intel Mac 请 [从源码构建](#从源码构建)。

## 技术栈

- Swift 6 + SwiftUI（菜单栏 / 弹层）+ AppKit（设置窗口）
- MenuBarExtra（`.window` 弹出样式）
- [LunarSwift](https://github.com/6tail/lunar-swift)（二十四节气、日干支）
- XcodeGen

## 反馈

[提交 Issue](https://github.com/NicCraver/tic/issues)

## 参与贡献

欢迎 PR。发版与版本号约定见 [docs/releasing.md](docs/releasing.md)。

## License

MIT — 见 [LICENSE](LICENSE)。
