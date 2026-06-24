# 安全策略

## 受支持版本

仅 **最新 Release** 会收到安全修复。请从 [Releases](https://github.com/NicCraver/tic/releases) 安装最新版。

| 版本 | 支持 |
|------|------|
| 最新 tag | ✅ |
| 更早版本 | ❌ |

## 报告漏洞

请勿在公开 Issue 中披露可被利用的安全细节。

请通过以下方式之一私下报告：

1. **[GitHub Security Advisories](https://github.com/NicCraver/tic/security/advisories/new)**（推荐）
2. 在仓库新建 **Private vulnerability report**（若仓库已开启该功能）

报告请尽量包含：

- 影响版本与组件（如应用内更新下载、节假日联网拉取）
- 复现步骤或 PoC
- 影响评估（本地权限提升、任意下载、MITM 等）

我们会在确认后尽快回复，修复后发布新版本并在 CHANGELOG 中致谢（除非你希望匿名）。

## 安全相关设计（供审计参考）

- 应用内更新：DMG URL 域名白名单、版本与文件名校验、重定向拦截、落盘路径与体积限制（见 [`docs/app-update.md`](docs/app-update.md)）
- 节假日数据：固定 commit pin、响应大小与年份校验（见 [`docs/holiday-data-source.md`](docs/holiday-data-source.md)）
