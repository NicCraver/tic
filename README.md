# Tic

macOS 菜单栏日历工具：状态栏显示日期时间，点击弹出日历。

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)

## 功能

- 状态栏实时显示日期/时间
- 点击弹出图形日历
- 支持多种显示格式（月日+时间 / 仅时间 / 仅日期）
- 可选显示秒数
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
