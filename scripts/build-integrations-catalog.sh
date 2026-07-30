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
  # Build into a scratch dir and diff the shards; catalog.json/core.yaml/INDEX.md
  # carry a generation timestamp, so only the shard contents are comparable.
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  CATALOG_OUT="$TMP/fresh" "$PY" "$ROOT/scripts/lib/build_catalog.py" >/dev/null
  if diff -rq "$ROOT/integrations/shards" "$TMP/fresh/shards" >/dev/null 2>&1; then
    echo "OK:   catalog shards up to date"
    exit 0
  fi
  echo "WARN: catalog drifted from disk — run without --check and commit the result"
  diff -rq "$ROOT/integrations/shards" "$TMP/fresh/shards" 2>&1 | head -10
  exit 1
fi

echo "==> Scanning local Cursor / Claude integrations..."
"$PY" "$ROOT/scripts/lib/build_catalog.py"
echo "==> Wrote $ROOT/integrations"
