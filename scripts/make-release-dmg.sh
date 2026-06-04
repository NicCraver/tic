#!/usr/bin/env bash
# 将 Tic.app 与「应用程序」快捷方式打入 UDZO 压缩 DMG，供 Release 分发。
set -euo pipefail

APP_PATH="${1:?用法: $0 <Tic.app> <输出.dmg> [卷标名]}"
OUTPUT_DMG="${2:?用法: $0 <Tic.app> <输出.dmg> [卷标名]}"
VOL_NAME="${3:-Tic}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "错误: 找不到应用包: $APP_PATH" >&2
  exit 1
fi

APP_NAME="$(basename "$APP_PATH")"
STAGING="$(mktemp -d)"
cleanup() { rm -rf "$STAGING"; }
trap cleanup EXIT

ditto "$APP_PATH" "$STAGING/$APP_NAME"
ln -s /Applications "$STAGING/Applications"

rm -f "$OUTPUT_DMG"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$OUTPUT_DMG"

echo "已生成 DMG: $OUTPUT_DMG"
