#!/usr/bin/env bash
# Regenerate integrations/{catalog.json,core.yaml,shards/*.jsonl,INDEX.md}
# from the local Cursor / Claude installation.
#
#   bash scripts/build-integrations-catalog.sh            # write
#   bash scripts/build-integrations-catalog.sh --check    # dry-run, fail on drift
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="${PYTHON:-python3}"

command -v "$PY" >/dev/null 2>&1 || { echo "ERR:  $PY not found"; exit 2; }

if [[ "${1:-}" == "--check" ]]; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  [[ -d "$ROOT/integrations" ]] && cp -R "$ROOT/integrations" "$TMP/before"
  "$PY" "$ROOT/scripts/lib/build_catalog.py" >/dev/null
  if [[ -d "$TMP/before" ]] && diff -rq \
      --exclude=catalog.json --exclude=core.yaml --exclude=INDEX.md \
      "$TMP/before" "$ROOT/integrations" >/dev/null 2>&1; then
    echo "OK:   catalog shards up to date"
    exit 0
  fi
  echo "WARN: catalog drifted from disk — commit the regenerated files"
  exit 1
fi

echo "==> Scanning local Cursor / Claude integrations..."
"$PY" "$ROOT/scripts/lib/build_catalog.py"
echo "==> Wrote $ROOT/integrations"
