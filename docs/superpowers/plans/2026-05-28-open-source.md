# Tic 开源发布 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Tic 发布为可协作的 GitHub 开源项目：文档齐全、CI 验证构建、tag 触发未签名 Release 包，且不依赖 Apple 付费开发者账号。

**Architecture:** 版本号仅维护于 `project.yml`；CI 在 macOS runner 上 `xcodegen generate` 后 `xcodebuild`（关闭签名）；Release 工作流在 `v*` tag 时打包 `Tic.app` 为 zip 并上传 GitHub Release。用户通过 README 处理 Gatekeeper。

**Tech Stack:** XcodeGen, GitHub Actions (`macos-14`/`macos-latest`), `xcodebuild`, 可选 `gh` CLI。

**Design spec:** `docs/superpowers/specs/2026-05-28-open-source-design.md`

**Constants（实施前替换）：**

- `GITHUB_OWNER` = `NicCraver`
- `GITHUB_REPO` = `tic`
- `COPYRIGHT_HOLDER` = `NicCraver`
- `REPO_URL` = `https://github.com/NicCraver/tic`

---

## Phase P0 — 仓库可公开

### Task 1: 修正 LICENSE 版权

**Files:**
- Modify: `LICENSE` line 3

- [ ] **Step 1:** 将 `Copyright (c) 2026 Tic` 改为 `Copyright (c) 2026 COPYRIGHT_HOLDER`

- [ ] **Step 2:** Commit

```bash
git add LICENSE
git commit -m "chore(license): 更新 MIT 版权持有人"
```

---

### Task 2: 重写 README（面向公众）

**Files:**
- Modify: `README.md`

- [ ] **Step 1:** 替换构建段为通用克隆路径（去掉 `/Users/nic/...`）：

```markdown
## 要求

- macOS 14+
- Xcode 16+（含 Swift 6）

## 从源码构建

```bash
git clone https://github.com/GITHUB_OWNER/GITHUB_REPO.git
cd GITHUB_REPO
brew install xcodegen
xcodegen generate
open Tic.xcodeproj
# 在 Xcode 中 Cmd+R 运行
```

## 下载预编译版

见 [Releases](https://github.com/GITHUB_OWNER/GITHUB_REPO/releases)。

> **首次打开：** 若系统提示无法验证开发者，请 **右键应用 → 打开**，或在终端执行：
>
> ```bash
> xattr -cr /Applications/Tic.app
> ```
>
> （路径改为你实际安装位置。）

## 反馈

[提交 Issue](https://github.com/GITHUB_OWNER/GITHUB_REPO/issues)

## 参与贡献

欢迎 PR。发版与版本号约定见 [docs/releasing.md](docs/releasing.md)。
```

- [ ] **Step 2:** 在「功能」下增加截图占位：`<!-- TODO: docs/images/menu-bar.png -->`（P3 再补图）

- [ ] **Step 3:** 增加 CI 徽章（P1 合并后生效）：

```markdown
[![CI](https://github.com/GITHUB_OWNER/GITHUB_REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/GITHUB_OWNER/GITHUB_REPO/actions/workflows/ci.yml)
```

- [ ] **Step 4:** Commit

```bash
git add README.md
git commit -m "docs: 面向开源重写 README"
```

---

### Task 3: 关于页链接改为 GitHub

**Files:**
- Modify: `Tic/Sources/Settings/AboutSettingsPane.swift`

- [ ] **Step 1:** 将反馈区改为 Issues + 仓库（删除虚假 ticapp.com 与 App Store 项）：

```swift
                Section {
                    feedbackLink(
                        title: "反馈与问题",
                        subtitle: "GitHub Issues",
                        url: URL(string: "https://github.com/GITHUB_OWNER/GITHUB_REPO/issues")
                    )
                    feedbackLink(
                        title: "开源仓库",
                        subtitle: "github.com/GITHUB_OWNER/GITHUB_REPO",
                        url: URL(string: "https://github.com/GITHUB_OWNER/GITHUB_REPO")
                    )
                }
```

- [ ] **Step 2:** 本地 `xcodegen generate` 后 Cmd+B 确认编译

- [ ] **Step 3:** Commit

```bash
git add Tic/Sources/Settings/AboutSettingsPane.swift
git commit -m "fix(about): 关于页链接指向 GitHub 仓库"
```

---

### Task 4: CHANGELOG 与发版文档

**Files:**
- Create: `CHANGELOG.md`
- Create: `docs/releasing.md`

- [ ] **Step 1:** 创建 `CHANGELOG.md`：

```markdown
# Changelog

本文件格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### Added

- （下一版本变更写在这里）

## [1.0.0] - 2026-05-28

### Added

- 菜单栏模块化日期/农历/时间显示
- 农历日历弹窗（节假日、节气、休班）
- 设置页：通用、外观、菜单栏、日历、快捷键、关于
- 登录时自动启动
- macOS 应用图标

[Unreleased]: https://github.com/GITHUB_OWNER/GITHUB_REPO/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/GITHUB_OWNER/GITHUB_REPO/releases/tag/v1.0.0
```

- [ ] **Step 2:** 创建 `docs/releasing.md`（维护者 checklist：改 `project.yml` 版本 → 更新 CHANGELOG → tag → push tag → 等 CI Release）

- [ ] **Step 3:** Commit

```bash
git add CHANGELOG.md docs/releasing.md
git commit -m "docs: 添加 CHANGELOG 与发版说明"
```

---

### Task 5: `.agents/` 处理（二选一）

**Files:**
- Modify: `.gitignore`（若选不入库）

- [ ] **Step 1a（推荐）：** 在 `.gitignore` 追加：

```
.agents/
skills-lock.json
```

若目录已 tracked：`git rm -r --cached .agents skills-lock.json`

- [ ] **Step 1b（备选）：** 在 README 增加「开发工具」小节说明 `.agents/` 仅 Cursor 用

- [ ] **Step 2:** Commit

---

### Task 6: 创建 GitHub 仓库并推送

**Files:** 无

- [ ] **Step 1:** 在 GitHub 创建空仓库 `GITHUB_OWNER/GITHUB_REPO`（Public，无 README）

- [ ] **Step 2:**

```bash
git remote add origin https://github.com/GITHUB_OWNER/GITHUB_REPO.git
git push -u origin main
```

Expected: 远程 `main` 与本地一致

---

## Phase P1 — CI（build + test）

### Task 7: 添加 `ci.yml`

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1:** 写入工作流：

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Install XcodeGen
        run: brew install xcodegen

      - name: Generate Xcode project
        run: xcodegen generate

      - name: Build
        run: |
          xcodebuild build \
            -scheme Tic \
            -destination 'platform=macOS' \
            -configuration Debug \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGN_IDENTITY=-

      - name: Test
        run: |
          xcodebuild test \
            -scheme Tic \
            -destination 'platform=macOS' \
            -configuration Debug \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGN_IDENTITY=-
```

- [ ] **Step 2:** Push 后在 Actions 页确认 workflow 绿

Run: 打开 `https://github.com/GITHUB_OWNER/GITHUB_REPO/actions`  
Expected: latest run **success**

- [ ] **Step 3:** Commit

```bash
git add .github/workflows/ci.yml
git commit -m "ci: 添加 macOS 构建与单元测试工作流"
git push
```

---

## Phase P2 — Release（未签名 zip）

### Task 8: 添加 `release.yml`

**Files:**
- Create: `.github/workflows/release.yml`

- [ ] **Step 1:** 创建 tag 触发 Release 的工作流（`permissions: contents: write`；`softprops/action-gh-release` 上传 zip）

核心步骤：
1. `xcodegen generate`
2. `xcodebuild build -scheme Tic -configuration Release CODE_SIGNING_ALLOWED=NO`
3. `ditto -c -k --keepParent build/Release/Tic.app Tic-${{ tag_name }}-macOS.zip`
4. `gh release create` 或 `softprops/action-gh-release` 附 zip + 从 `CHANGELOG.md` 摘录 body

（完整 YAML 在实施时按仓库 scheme 路径微调；`BUILT_PRODUCTS_DIR` 以 `xcodebuild -showBuildSettings` 为准。）

- [ ] **Step 2:** 确认 `project.yml` 中 `MARKETING_VERSION: "1.0.0"`、`CURRENT_PROJECT_VERSION: "1"`

- [ ] **Step 3:** 打 tag 并推送

```bash
git tag v1.0.0
git push origin v1.0.0
```

Expected: Actions `release` 成功；Release 页有 `Tic-v1.0.0-macOS.zip`

- [ ] **Step 4:** Commit workflow

```bash
git add .github/workflows/release.yml
git commit -m "ci: 添加 tag 触发的 Release 打包工作流"
```

---

## Phase P3 — 体验增强（不阻塞公开）

### Task 9: 截图

**Files:**
- Create: `docs/images/menu-bar.png`（及可选 `calendar-popover.png`）
- Modify: `README.md`

- [ ] **Step 1:** 截取菜单栏与日历弹窗，放入 `docs/images/`
- [ ] **Step 2:** README 用 `![菜单栏](docs/images/menu-bar.png)` 替换占位

---

### Task 10: Issue / PR 模板（可选）

**Files:**
- Create: `.github/ISSUE_TEMPLATE/bug_report.yml`
- Create: `.github/PULL_REQUEST_TEMPLATE.md`

- [ ] **Step 1:** Bug 模板字段：macOS 版本、Tic 版本、复现步骤、期望/实际
- [ ] **Step 2:** PR 模板：变更说明、是否跑过本地测试

---

## Phase P4 — 二期（Sparkle / Homebrew）

不在首期实施。见 `docs/plan.md` S2 与 design spec 方案 C。

---

## 验证清单（verification-before-completion）

- [ ] `xcodegen generate && xcodebuild test -scheme Tic -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO` 本地通过
- [ ] GitHub Actions CI 绿
- [ ] `v1.0.0` Release 资产可下载且 README Gatekeeper 说明已读
- [ ] 关于页链接在浏览器可打开
- [ ] 仓库无 `DEVELOPMENT_TEAM` 真值、无密钥、无 `.p12`

---

## 执行方式

Plan 已保存。可选：

1. **Subagent-Driven** — 每 Task 独立子代理 + 任务间审查（推荐）
2. **Inline Execution** — 本会话按 Task 顺序执行，Phase 边界停顿给你看

实施前请先在 design spec 中确认 **GITHUB_OWNER**、**COPYRIGHT_HOLDER**、**.agents/ 是否入库**。
