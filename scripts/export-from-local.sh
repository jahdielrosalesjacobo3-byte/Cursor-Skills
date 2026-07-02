#!/usr/bin/env bash
# Re-export local skills/configs into this repo (run from repo root after clone)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Exporting from local machine to $ROOT ..."

rsync -a --delete --exclude='.sync-manifest.json' --exclude='canvas/sdk/*.d.ts' \
  "$HOME/.cursor/skills-cursor/" "$ROOT/cursor/skills/"

cp "$HOME/.cursor/mcp.json" "$ROOT/cursor/mcp.json"
cp "$HOME/.cursor/hooks.json" "$ROOT/cursor/hooks.json"

rsync -a --exclude='.git' "$HOME/.cursor/plugins/cache/" "$ROOT/cursor/plugins/cache/"
rsync -a --exclude='.git' "$HOME/.cursor/plugins/marketplaces/" "$ROOT/cursor/plugins/marketplaces/" 2>/dev/null || true

cp "$HOME/.claude/profiles/"*.json "$ROOT/claude/profiles/" 2>/dev/null || true
rsync -aL --delete --exclude='.git' "$HOME/.claude/skills/" "$ROOT/claude/skills/"

cp "$HOME/.claude/plugins/installed_plugins.json" "$ROOT/claude/plugins/" 2>/dev/null || true
cp "$HOME/.claude/plugins/known_marketplaces.json" "$ROOT/claude/plugins/" 2>/dev/null || true
rsync -a --exclude='.git' "$HOME/.claude/plugins/cache/" "$ROOT/claude/plugins/cache/"
rsync -a --exclude='.git' "$HOME/.claude/plugins/marketplaces/" "$ROOT/claude/plugins/marketplaces/" 2>/dev/null || true

if [ -d "$HOME/.codex/skills" ]; then
  rsync -aL --delete --exclude='.git' "$HOME/.codex/skills/" "$ROOT/codex/skills/"
fi

echo "==> Export complete. Review with: git status"
