# Tic 开源发布 — 设计说明

**日期：** 2026-05-28  
**状态：** 待你确认后进入实施计划  
**约束：** 不购买 Apple Developer Program（$99/年）；不上 Mac App Store。

---

## 目标

1. 在 GitHub 以 **MIT** 公开仓库，他人可克隆、构建、提 Issue/PR。
2. 提供 **预编译下载**（GitHub Releases，未签名/未公证），降低使用门槛。
3. **CI** 在 push/PR 上自动编译与跑测试，主分支可信。
4. **版本** 有单一来源、可打 tag、Release notes 可追踪。
5. **二期可选**：应用内检查更新（Sparkle 或 GitHub API），不依赖 Apple 公证。

## 非目标（本期不做）

- Mac App Store 上架、App Sandbox、付费开发者账号公证。
- Sparkle / Homebrew（列入 Phase 2，不在首次公开阻塞）。
- 重构业务代码；`.agents/` 技能目录是否入库单独决策（见下文）。

---

## 现状盘点

| 项 | 状态 |
|----|------|
| `LICENSE` (MIT) | 有；版权为 `2026 Tic`，建议改为持有人姓名/ GitHub 名 |
| `README.md` | 有；含本机路径 `/Users/nic/...`；无截图、无安装/Gatekeeper 说明 |
| `.gitignore` | 有；忽略 `*.xcodeproj`（CI 必须 `xcodegen generate`） |
| 版本号 | `project.yml` → `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` |
| 测试 | `TicTests` 3 个用例，可在 CI 跑 |
| CI / Release | 无 `.github/workflows` |
| `git remote` | 当前无 remote |
| 关于页链接 | `ticapp.com` / `support@ticapp.com` 占位；App Store 项 `url: nil` |

---

## 分发策略（三选一）

### 方案 A：仅源码

- 用户 `git clone` + Xcode 本地编译。
- **优点：** 零 CI、零 Release 维护。  
- **缺点：** 门槛高，难吸引非开发者。  
- **结论：** 不适合作为唯一渠道，可作为 README 补充。

### 方案 B：GitHub Releases（未签名 zip）— **推荐首期**

- CI 或本地在 tag 时打出 `Tic.app` → zip，附到 Release。
- README 说明：首次打开用 **右键 → 打开**，或  
  `xattr -cr /Applications/Tic.app`。
- **优点：** 不花 $99；与当前 `DEVELOPMENT_TEAM: ""` 一致；实现快。  
- **缺点：** Gatekeeper 体验差一档；每次下载可能需用户操作（Sparkle 更新同理）。

### 方案 C：方案 B + Sparkle（二期）

- EdDSA 密钥免费；`appcast.xml` 挂 Release 或 raw 分支。
- **优点：** 应用内一键更新。  
- **缺点：** 多密钥管理、CI 步骤、仍可能遇到 quarantine。  
- **结论：** 开源公开后再加，对应 `docs/plan.md` S2。

**推荐路径：** 首期 **B** → 稳定后 **C**；Homebrew 个人 tap 作为可选第三条线（面向习惯 `brew` 的用户）。

---

## 版本与发布约定

| 字段 | 位置 | 规则 |
|------|------|------|
| 用户可见版本 | `project.yml` → `MARKETING_VERSION` | SemVer：`1.0.0` |
| 构建号 | `CURRENT_PROJECT_VERSION` | 每次 Release 递增整数 |
| Git 标签 | `v1.0.0` | 与 `MARKETING_VERSION` 一致（带 `v` 前缀） |
| 变更记录 | `CHANGELOG.md` | Keep a Changelog 风格；Release 正文从对应版本节复制 |

**发布节奏（建议）：** 功能/修复合并到 `main` → 改版本号 + CHANGELOG → tag → CI 出包 → GitHub Release。

---

## CI 架构

```text
push/PR → macos runner
       → brew install xcodegen
       → xcodegen generate
       → xcodebuild build (CODE_SIGNING_ALLOWED=NO)
       → xcodebuild test -scheme Tic

tag v* → 同上 Release 配置
       → 打包 build/Release/Tic.app → Tic-{version}-macOS.zip
       → upload-artifact + gh release upload
```

- 不提交 `Tic.xcodeproj`：与现有 `.gitignore` 一致。
- 无 Apple 密钥：Release 构建关闭签名即可验证可编译性。

---

## 文档与社区

| 交付物 | 首期 | 说明 |
|--------|------|------|
| README 重写 | 是 | 克隆路径、徽章、截图占位、构建、下载、Gatekeeper、Contributing 简述 |
| `CHANGELOG.md` | 是 | 从 `1.0.0` 起 |
| `docs/releasing.md` | 是 | 维护者发版 checklist |
| `CONTRIBUTING.md` | 可选 | PR 前 `xcodegen` + 测试 |
| Issue 模板 | 可选 | Bug / Feature |
| 关于页 | 是 | Issues / 仓库链接；移除虚假域名与 App Store 项 |

---

## `.agents/` 与技能目录

- **选项 1（推荐）：** 加入 `.gitignore`，开源仓库只保留应用与 `docs/`、`AGENTS.md`。  
- **选项 2：** 保留在仓库，README 注明「仅 Cursor Agent 用，非运行时依赖」。

---

## 需要你拍板的常量（实施前填入）

在 `docs/superpowers/plans/2026-05-28-open-source.md` 顶部用占位符，确认后全局替换：

| 占位符 | 值 |
|--------|-----|
| `GITHUB_OWNER` | `NicCraver` |
| `GITHUB_REPO` | `tic` |
| `COPYRIGHT_HOLDER` | `NicCraver` |
| `SUPPORT_EMAIL` | 仅用 GitHub Issues |

---

## 成功标准

- [ ] 仓库 Public，`git remote` 指向 GitHub，无敏感信息。
- [ ] 陌生人按 README 能 `xcodegen` + 编译通过（或下载 zip 并按说明打开）。
- [ ] PR 上 CI 绿（build + test）。
- [ ] `v1.0.0` tag 对应 Release 资产可下载。
- [ ] 关于页链接有效（至少 GitHub Issues/仓库）。

---

## 分期

| 阶段 | 内容 | 阻塞公开？ |
|------|------|------------|
| **P0** | LICENSE/README/关于页/CHANGELOG/占位清理 | 是 |
| **P1** | `ci.yml` build+test | 是 |
| **P2** | `release.yml` + 首个 `v1.0.0` | 建议同期 |
| **P3** | 截图、Issue 模板、CONTRIBUTING | 否 |
| **P4** | Sparkle / Homebrew tap | 否 |

---

## 批准

请确认：

1. 首期采用 **方案 B**（Releases 未签名 zip），Sparkle 放 P4。  
2. `.agents/` **是否入库**（选项 1 或 2）。  
3. 上表四个常量（GitHub 仓库与版权名）。

确认后执行 `docs/superpowers/plans/2026-05-28-open-source.md`。
