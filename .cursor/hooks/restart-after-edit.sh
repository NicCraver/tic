#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

NEEDS_RESTART="$ROOT/.cursor/.needs-restart"

if [[ ! -f "$NEEDS_RESTART" ]]; then
  exit 0
fi

rm -f "$NEEDS_RESTART"

if scripts/restart-dev.sh; then
  printf '%s\n' '{"followup_message":"已自动重新编译并启动 Tic。"}'
else
  printf '%s\n' '{"followup_message":"自动重启失败，请检查编译错误并手动运行 scripts/restart-dev.sh。"}'
  exit 1
fi
