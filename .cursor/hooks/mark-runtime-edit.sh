#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
input="$(cat)"

file_path="$(printf '%s' "$input" | python3 -c "import sys, json; print(json.load(sys.stdin).get('file_path', ''))")"

if [[ -z "$file_path" ]]; then
  exit 0
fi

if [[ "$file_path" == Tic/Sources/* ]] \
  || [[ "$file_path" == Tic/Resources/* ]] \
  || [[ "$file_path" == TicTests/* ]] \
  || [[ "$file_path" == "project.yml" ]]; then
  mkdir -p "$ROOT/.cursor"
  touch "$ROOT/.cursor/.needs-restart"
fi

exit 0
