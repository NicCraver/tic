#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DERIVED_DATA="$ROOT/build/DerivedData"
APP_PATH="$DERIVED_DATA/Build/Products/Debug/Tic.app"

if [[ ! -f Tic.xcodeproj/project.pbxproj ]] || [[ project.yml -nt Tic.xcodeproj/project.pbxproj ]]; then
  echo "正在重新生成 Xcode 工程..."
  xcodegen generate
fi

echo "正在结束已有 Tic 进程..."
pkill -x Tic 2>/dev/null || true
sleep 0.3

echo "正在编译 Debug..."
xcodebuild build \
  -scheme Tic \
  -destination 'platform=macOS' \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=- \
  -quiet

if [[ ! -d "$APP_PATH" ]]; then
  echo "错误：未找到 $APP_PATH" >&2
  exit 1
fi

echo "正在启动 Tic..."
open "$APP_PATH"
echo "完成。"
