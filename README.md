# Tic

macOS 菜单栏日历工具：状态栏显示日期时间，点击弹出日历。

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)

## 功能

- 状态栏模块化显示：日期、星期、周数、农历、时间、图标可开关与排序
- 点击弹出农历日历：节假日、节气、休/班、节日倒计时
- 设置页：通用 / 外观 / 菜单栏 / 日历 / 快捷键 / 关于
- 主题跟随系统或浅色/深色
- 登录时自动启动
- 无 Dock 图标（纯菜单栏应用）

## 构建与运行

```bash
brew install xcodegen
cd /Users/nic/NicProjects/tic
xcodegen generate
open Tic.xcodeproj
# Cmd+R 运行
```

## 技术栈

- Swift 6 + SwiftUI
- MenuBarExtra（`.window` 弹出样式）
- XcodeGen

## License

MIT
