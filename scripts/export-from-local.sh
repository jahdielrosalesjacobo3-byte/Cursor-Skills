#!/usr/bin/env bash
# Re-export local skills/agents/configs/plugins into this repo (run from repo root)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Exporting from local machine to $ROOT ..."

# --- Cursor skills (agents & subagents entrypoints) ---
rsync -a --delete \
  --exclude='.sync-manifest.json' \
  --exclude='canvas/sdk/*.d.ts' \
  "$HOME/.cursor/skills-cursor/" "$ROOT/cursor/skills/"

# --- Cursor agents (Task/subagent definitions) ---
if [ -d "$HOME/.cursor/agents" ]; then
  mkdir -p "$ROOT/cursor/agents"
  rsync -a --delete "$HOME/.cursor/agents/" "$ROOT/cursor/agents/"
  echo "    Cursor agents: $(ls "$ROOT/cursor/agents" | wc -l | tr -d ' ')"
fi

# --- Cursor MCP + hooks ---
cp "$HOME/.cursor/mcp.json" "$ROOT/cursor/mcp.json"
cp "$HOME/.cursor/hooks.json" "$ROOT/cursor/hooks.json"

# --- Project template (from skillsClaude if present) ---
PROJECT_CURSOR="${SECURESKILLS_PROJECT_CURSOR:-$HOME/Documents/skillsClaude/.cursor}"
if [ -d "$PROJECT_CURSOR" ]; then
  mkdir -p "$ROOT/templates/project/.cursor"
  rsync -a "$PROJECT_CURSOR/" "$ROOT/templates/project/.cursor/"
  echo "    Project template .cursor synced from $PROJECT_CURSOR"
fi

# --- Claude profiles + skills ---
mkdir -p "$ROOT/claude/profiles" "$ROOT/claude/skills" "$ROOT/claude/plugins"
cp "$HOME/.claude/profiles/"*.json "$ROOT/claude/profiles/" 2>/dev/null || true
# -aL follows symlinks so cyber skills 01-19 land as real directories
rsync -aL --delete --exclude='.git' "$HOME/.claude/skills/" "$ROOT/claude/skills/"

# --- Claude plugins ---
cp "$HOME/.claude/plugins/installed_plugins.json" "$ROOT/claude/plugins/" 2>/dev/null || true
cp "$HOME/.claude/plugins/known_marketplaces.json" "$ROOT/claude/plugins/" 2>/dev/null || true
rsync -a --delete --exclude='.git' "$HOME/.claude/plugins/cache/" "$ROOT/claude/plugins/cache/"
rsync -a --delete --exclude='.git' "$HOME/.claude/plugins/marketplaces/" "$ROOT/claude/plugins/marketplaces/" 2>/dev/null || true

# --- Cursor plugins ---
mkdir -p "$ROOT/cursor/plugins"
rsync -a --delete --exclude='.git' "$HOME/.cursor/plugins/cache/" "$ROOT/cursor/plugins/cache/"
rsync -a --delete --exclude='.git' "$HOME/.cursor/plugins/marketplaces/" "$ROOT/cursor/plugins/marketplaces/" 2>/dev/null || true
if [ -d "$HOME/.cursor/plugins/local" ]; then
  rsync -a --delete "$HOME/.cursor/plugins/local/" "$ROOT/cursor/plugins/local/" 2>/dev/null || true
fi

# --- Codex skills ---
if [ -d "$HOME/.codex/skills" ]; then
  mkdir -p "$ROOT/codex/skills"
  rsync -aL --delete --exclude='.git' "$HOME/.codex/skills/" "$ROOT/codex/skills/"
fi

# --- Manifest ---
python3 - "$ROOT" <<'PY'
import json, sys
from pathlib import Path

repo = Path(sys.argv[1])
home = Path.home()
manifest = {
    "version": 2,
    "exportedAt": __import__("datetime").datetime.now().isoformat(timespec="seconds"),
    "claude": {},
    "cursor": {},
}

ip = home / ".claude/plugins/installed_plugins.json"
if ip.exists():
    data = json.loads(ip.read_text())
    manifest["claude"]["installed"] = sorted(data.get("plugins", {}).keys())
    manifest["claude"]["count"] = len(manifest["claude"]["installed"])
km = home / ".claude/plugins/known_marketplaces.json"
if km.exists():
    manifest["claude"]["marketplaces"] = sorted(json.loads(km.read_text()).keys())

skills_dir = repo / "claude" / "skills"
if skills_dir.exists():
    claude_skills = sorted([p.name for p in skills_dir.iterdir() if p.is_dir()])
    manifest["claude"]["skills"] = claude_skills
    manifest["claude"]["skillsCount"] = len(claude_skills)

cache = home / ".cursor/plugins/cache"
cursor_plugins = []
if cache.exists():
    for mp in sorted(cache.iterdir()):
        if not mp.is_dir():
            continue
        for plugin in sorted(mp.iterdir()):
            if not plugin.is_dir():
                continue
            for ver in sorted(plugin.iterdir()):
                if ver.is_dir():
                    cursor_plugins.append(f"{plugin.name}@{mp.name} ({ver.name})")
manifest["cursor"]["installed"] = cursor_plugins
manifest["cursor"]["count"] = len(cursor_plugins)

cursor_skills = sorted(
    [p.name for p in (repo / "cursor" / "skills").iterdir() if p.is_dir()]
) if (repo / "cursor" / "skills").exists() else []
manifest["cursor"]["skills"] = cursor_skills
manifest["cursor"]["skillsCount"] = len(cursor_skills)

agents_dir = repo / "cursor" / "agents"
agents = sorted([p.stem for p in agents_dir.glob("*.md")]) if agents_dir.exists() else []
manifest["cursor"]["agents"] = agents
manifest["cursor"]["agentsCount"] = len(agents)

mcp = repo / "cursor" / "mcp.json"
if mcp.exists():
    servers = sorted(json.loads(mcp.read_text()).get("mcpServers", {}).keys())
    manifest["cursor"]["mcpServers"] = servers

(repo / "plugins-manifest.json").write_text(
    json.dumps(manifest, indent=2, ensure_ascii=False) + "\n"
)
print(
    f"Wrote plugins-manifest.json — Claude plugins={manifest['claude'].get('count', 0)} "
    f"skills={manifest['claude'].get('skillsCount', 0)}; "
    f"Cursor plugins={manifest['cursor'].get('count', 0)} "
    f"skills={manifest['cursor'].get('skillsCount', 0)} "
    f"agents={manifest['cursor'].get('agentsCount', 0)}"
)
PY

echo "==> Export complete. Review with: git status"
