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

cp "$HOME/.claude/profiles/"*.json "$ROOT/claude/profiles/" 2>/dev/null || true
rsync -aL --delete --exclude='.git' "$HOME/.claude/skills/" "$ROOT/claude/skills/"

cp "$HOME/.claude/plugins/installed_plugins.json" "$ROOT/claude/plugins/" 2>/dev/null || true
cp "$HOME/.claude/plugins/known_marketplaces.json" "$ROOT/claude/plugins/" 2>/dev/null || true
rsync -a --delete --exclude='.git' "$HOME/.claude/plugins/cache/" "$ROOT/claude/plugins/cache/"
rsync -a --delete --exclude='.git' "$HOME/.claude/plugins/marketplaces/" "$ROOT/claude/plugins/marketplaces/" 2>/dev/null || true

rsync -a --delete --exclude='.git' "$HOME/.cursor/plugins/cache/" "$ROOT/cursor/plugins/cache/"
rsync -a --delete --exclude='.git' "$HOME/.cursor/plugins/marketplaces/" "$ROOT/cursor/plugins/marketplaces/" 2>/dev/null || true
if [ -d "$HOME/.cursor/plugins/local" ]; then
  rsync -a --delete "$HOME/.cursor/plugins/local/" "$ROOT/cursor/plugins/local/" 2>/dev/null || true
fi

python3 - "$ROOT" <<'PY'
import json, sys
from pathlib import Path
repo = Path(sys.argv[1])
manifest = {"claude": {}, "cursor": {}}
ip = Path.home() / ".claude/plugins/installed_plugins.json"
if ip.exists():
    data = json.loads(ip.read_text())
    manifest["claude"]["installed"] = sorted(data.get("plugins", {}).keys())
    manifest["claude"]["count"] = len(manifest["claude"]["installed"])
km = Path.home() / ".claude/plugins/known_marketplaces.json"
if km.exists():
    manifest["claude"]["marketplaces"] = sorted(json.loads(km.read_text()).keys())
cache = Path.home() / ".cursor/plugins/cache"
if cache.exists():
    cursor_plugins = []
    for mp in sorted(cache.iterdir()):
        if mp.is_dir():
            for plugin in sorted(mp.iterdir()):
                if plugin.is_dir():
                    for ver in sorted(plugin.iterdir()):
                        if ver.is_dir():
                            cursor_plugins.append(f"{plugin.name}@{mp.name} ({ver.name})")
    manifest["cursor"]["installed"] = cursor_plugins
    manifest["cursor"]["count"] = len(cursor_plugins)
(repo / "plugins-manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False))
print(f"Wrote plugins-manifest.json ({manifest['claude'].get('count',0)} Claude, {manifest['cursor'].get('count',0)} Cursor)")
PY

if [ -d "$HOME/.codex/skills" ]; then
  rsync -aL --delete --exclude='.git' "$HOME/.codex/skills/" "$ROOT/codex/skills/"
fi

echo "==> Export complete. Review with: git status"
