#!/usr/bin/env python3
"""Regenerate plugins-manifest.json from the repo + local plugin caches.

Called by scripts/export-from-local.sh, or standalone:
    python3 scripts/lib/build_manifest.py
"""

from __future__ import annotations

import json
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
HOME = Path.home()


def dir_names(path: Path) -> list[str]:
    return sorted(p.name for p in path.iterdir() if p.is_dir()) if path.is_dir() else []


def main() -> int:
    repo = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else REPO
    manifest: dict = {
        "version": 3,
        "exportedAt": datetime.now().isoformat(timespec="seconds"),
        "claude": {},
        "cursor": {},
    }

    installed = HOME / ".claude/plugins/installed_plugins.json"
    if installed.exists():
        plugins = sorted(json.loads(installed.read_text()).get("plugins", {}).keys())
        manifest["claude"]["installed"] = plugins
        manifest["claude"]["count"] = len(plugins)

    marketplaces = HOME / ".claude/plugins/known_marketplaces.json"
    if marketplaces.exists():
        manifest["claude"]["marketplaces"] = sorted(json.loads(marketplaces.read_text()).keys())

    claude_skills = dir_names(repo / "claude" / "skills")
    manifest["claude"]["skills"] = claude_skills
    manifest["claude"]["skillsCount"] = len(claude_skills)

    cursor_plugins = []
    cache = HOME / ".cursor/plugins/cache"
    if cache.is_dir():
        for marketplace in sorted(p for p in cache.iterdir() if p.is_dir()):
            for plugin in sorted(p for p in marketplace.iterdir() if p.is_dir()):
                for ref in sorted(p for p in plugin.iterdir() if p.is_dir()):
                    cursor_plugins.append(f"{plugin.name}@{marketplace.name} ({ref.name})")
    manifest["cursor"]["installed"] = cursor_plugins
    manifest["cursor"]["count"] = len(cursor_plugins)

    cursor_skills = dir_names(repo / "cursor" / "skills")
    manifest["cursor"]["skills"] = cursor_skills
    manifest["cursor"]["skillsCount"] = len(cursor_skills)

    agents_dir = repo / "cursor" / "agents"
    agents = sorted(p.stem for p in agents_dir.glob("*.md") if p.stem != "README") \
        if agents_dir.is_dir() else []
    manifest["cursor"]["agents"] = agents
    manifest["cursor"]["agentsCount"] = len(agents)

    rules_dir = repo / "cursor" / "rules"
    manifest["cursor"]["rules"] = sorted(p.name for p in rules_dir.glob("*.mdc")) \
        if rules_dir.is_dir() else []
    manifest["cursor"]["userSkills"] = dir_names(repo / "cursor" / "user-skills")

    mcp = repo / "cursor" / "mcp.json"
    if mcp.exists():
        manifest["cursor"]["mcpServers"] = sorted(
            json.loads(mcp.read_text()).get("mcpServers", {}).keys()
        )

    manifest["k3"] = {
        "registry": "expert-registry.yaml",
        "harness": "harness-profiles.yaml",
        "cognitive": True,
        "mode": "full-spectrum",
    }

    catalog_path = repo / "integrations" / "catalog.json"
    if catalog_path.exists():
        catalog = json.loads(catalog_path.read_text())
        manifest["integrations"] = {
            "catalog": "integrations/catalog.json",
            "core": "integrations/core.yaml",
            "generatedAt": catalog.get("generatedAt"),
            "counts": catalog.get("counts", {}),
            "domains": catalog.get("domains", {}),
            "shards": len(catalog.get("shards", [])),
        }
    else:
        manifest["integrations"] = {"catalog": None, "note": "run build-integrations-catalog.sh"}

    (repo / "plugins-manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(
        "Wrote plugins-manifest.json — "
        f"Claude plugins={manifest['claude'].get('count', 0)} "
        f"skills={manifest['claude'].get('skillsCount', 0)}; "
        f"Cursor plugins={manifest['cursor'].get('count', 0)} "
        f"skills={manifest['cursor'].get('skillsCount', 0)} "
        f"agents={manifest['cursor'].get('agentsCount', 0)}; "
        f"L2 catalog={manifest['integrations'].get('counts', {}).get('l2Total', 0)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
