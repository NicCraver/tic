# 参与贡献

感谢关注 Tic。本项目欢迎 Bug 报告、功能建议与 Pull Request。

## 开始之前

- 搜索 [已有 Issue](https://github.com/NicCraver/tic/issues)，避免重复
- Bug 请用 Issue 模板，附上 macOS 版本、Tic 版本与复现步骤
- 较大改动请先开 Issue 讨论，再动手写代码

## 开发环境

- macOS 14+
- Xcode 16+（Swift 6）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
xcodegen generate
open Tic.xcodeproj
```

`project.yml` 是工程配置的唯一来源，**不要**手改 `.xcodeproj` 或 `Info.plist`。

## 测试

提交 PR 前请确保本地测试通过：

```bash
xcodegen generate
xcodebuild test \
  -scheme Tic \
  -destination 'platform=macOS' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=-
```

CI 会在 push / PR 时自动跑相同流程。

## 代码约定

- 与周边文件保持一致：命名、缩进、抽象粒度
- 注释只写非显而易见的业务逻辑
- 用户可见文案与 commit message 使用中文；标识符保持英文
- 改动 `Tic/Sources/`、`Tic/Resources/` 等运行时代码后，本地编译确认无错误

维护者用 Agent 开发时见根目录 [AGENTS.md](AGENTS.md)。

## Pull Request

- 一个 PR 聚焦一类改动，说明「为什么」而不只列文件
- UI 变更请附截图（菜单栏 / 设置 / 弹窗）
- 修 Bug 时如有条件，补充或更新 `TicTests/` 中的用例

## 发版（维护者）

版本号、CHANGELOG、打 tag 流程见 [docs/releasing.md](docs/releasing.md)。

## 文档

- 用户向：README、CHANGELOG
- 实现向：`docs/` 下各专题文档；改菜单栏、设置、更新、节假日逻辑前先读对应文档
