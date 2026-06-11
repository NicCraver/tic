# 发版说明（维护者）

应用内检查更新、DMG 下载与用户侧流程见 [`app-update.md`](app-update.md)。

版本号**仅**在 `project.yml` 中维护：

- `MARKETING_VERSION`：用户可见版本（SemVer，如 `1.0.1`）
- `CURRENT_PROJECT_VERSION`：构建号（每次发版递增整数）

## 发版步骤

1. 将 `[Unreleased]` 下的变更写入 `CHANGELOG.md` 新版本节，并更新底部链接。
2. 修改 `project.yml` 中的 `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`。
3. 提交并合并到 `main`。
4. 打 tag 并推送（tag 须以 `v` 开头，与 MARKETING_VERSION 一致）：

   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

5. GitHub Actions `Release` 工作流会自动构建 `Tic.app`、打成含「应用程序」快捷方式的 DMG 并创建 GitHub Release。
6. 在 Release 页面检查附件与说明；必要时编辑 Release 正文（可从 CHANGELOG 复制）。

## 本地验证（推送 tag 前）

```bash
brew install xcodegen
xcodegen generate
xcodebuild test \
  -scheme Tic \
  -destination 'platform=macOS' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=-
```

本地试打 DMG（需先 Release 构建出 `Tic.app`）：

```bash
APP=build/DerivedData/Build/Products/Release/Tic.app
codesign --sign - --force --deep --timestamp=none "$APP"
chmod +x scripts/make-release-dmg.sh
./scripts/make-release-dmg.sh "$APP" /tmp/Tic-test.dmg
open /tmp/Tic-test.dmg
```

## 说明

当前 Release 为**未公证**构建（CI 会做 ad-hoc 整包签名）。用户从浏览器下载后可能看到 **「已损坏」** 或无法验证开发者，需按 [README](../README.md) 用「右键打开」或 `xattr -cr` 处理隔离属性；非 Apple 开发者账号公证前无法完全避免。
