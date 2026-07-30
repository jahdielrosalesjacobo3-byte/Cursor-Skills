#!/usr/bin/env python3
"""Scan local Cursor/Claude installs and emit the SecureSkills integrations catalog.

Emits under <repo>/integrations/:
  catalog.json          root manifest (counts + shard pointers)
  core.yaml             L1 core: MCP, hooks, rules, agents, canonical skills, profiles
  shards/*.jsonl        L2 on-demand index, one JSON object per line, per marketplace
  INDEX.md              human-facing doc

No third-party dependencies: frontmatter is parsed with a minimal reader that
covers the subset of YAML used by SKILL.md files (scalars + folded strings).
"""

from __future__ import annotations

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

HOME = Path.home()
REPO = Path(__file__).resolve().parents[2]
# CATALOG_OUT lets --check build into a scratch dir instead of dirtying the repo.
OUT = Path(os.environ.get("CATALOG_OUT") or REPO / "integrations")
SHARDS = OUT / "shards"

DESC_MAX = 400

# --- K3 domain heuristics -------------------------------------------------
# Order matters: first matching domain wins. Keywords match as word prefixes,
# so "vuln" catches "vulnerability" while "ui" does not catch "build".
DOMAIN_RULES: list[tuple[str, tuple[str, ...]]] = [
    ("security", ("security", "secure", "vuln", "exploit", "pentest", "malware",
                  "threat", "forensic", "owasp", "cve", "hacking", "redteam",
                  "red-team", "blueteam", "blue-team", "incident", "compliance",
                  "grc", "semgrep", "snyk", "sast", "dast", "cryptograph",
                  "authentication", "authorization", "phishing", "ransomware",
                  "siem", "soc", "csoc", "osint", "recon")),
    ("trading", ("trading", "trader", "backtest", "portfolio", "quant",
                 "candlestick", "alpha-vantage", "hedge", "brokerage", "ticker")),
    ("infra", ("deploy", "terraform", "kubernetes", "k8s", "docker", "aws", "azure",
               "gcp", "vercel", "cicd", "ci-cd", "pipeline", "infra", "devops",
               "serverless", "cloudflare", "observability", "monitoring",
               "provisioning", "helm", "ansible", "sre")),
    ("design", ("design", "ui", "ux", "figma", "css", "tailwind", "shadcn",
                "animation", "gsap", "branding", "typography", "accessibility",
                "wireframe", "prototyp", "layout", "iconograph")),
    ("agentic", ("agent", "swarm", "orchestrat", "mcp", "workflow", "autopilot",
                 "memory", "rag", "prompt", "llm", "skill-creator", "subagent",
                 "tool-builder", "multi-agent", "autonomous")),
    ("research", ("research", "citation", "scrap", "crawl", "intelligence",
                  "dossier", "benchmark", "literature", "survey")),
    ("coding", ("code", "coding", "refactor", "test", "debug", "lint", "typescript",
                "python", "rust", "golang", "java", "react", "nextjs", "api",
                "database", "sql", "migration", "backend", "frontend", "git",
                "compiler", "runtime", "framework")),
]

DOMAIN_PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    (domain, re.compile(r"(?<![a-z0-9])(?:" + "|".join(re.escape(k) for k in keywords) + r")"))
    for domain, keywords in DOMAIN_RULES
]


def classify(*texts: str) -> str:
    blob = " ".join(t for t in texts if t).lower()
    for domain, pattern in DOMAIN_PATTERNS:
        if pattern.search(blob):
            return domain
    return "general"


# --- frontmatter ----------------------------------------------------------
_KEY_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$")


def read_frontmatter(path: Path) -> dict[str, str]:
    """Parse the leading `---` YAML block. Values are flattened to strings."""
    try:
        with path.open("r", encoding="utf-8", errors="replace") as fh:
            first = fh.readline()
            if first.strip() != "---":
                return {}
            lines: list[str] = []
            for line in fh:
                if line.strip() in ("---", "..."):
                    break
                lines.append(line.rstrip("\n"))
                if len(lines) > 200:  # malformed / missing terminator
                    return {}
    except OSError:
        return {}

    data: dict[str, str] = {}
    key: str | None = None
    for line in lines:
        m = _KEY_RE.match(line)
        if m and not line.startswith((" ", "\t", "-")):
            key = m.group(1)
            data[key] = m.group(2).strip().strip("'\"")
        elif key and line.strip():
            # continuation of a folded/indented scalar
            data[key] = f"{data[key]} {line.strip()}".strip()
    return data


def clean(text: str, limit: int = DESC_MAX) -> str:
    text = re.sub(r"\s+", " ", text or "").strip()
    return text[: limit - 1] + "\u2026" if len(text) > limit else text


def rel_home(path: Path) -> str:
    try:
        return "~/" + str(path.relative_to(HOME))
    except ValueError:
        return str(path)


# --- scanners -------------------------------------------------------------
def scan_plugin_skills(root: Path, runtime: str) -> list[dict]:
    """Index every SKILL.md under a plugin cache tree.

    Layout: <root>/<marketplace>/<plugin>/<ref>/skills/<name>/SKILL.md
    Skills repeated across bundles of one marketplace collapse into a single
    entry that lists every plugin providing it.
    """
    if not root.is_dir():
        return []

    by_key: dict[tuple[str, str], dict] = {}
    for skill_file in sorted(root.rglob("SKILL.md")):
        parts = skill_file.relative_to(root).parts
        if len(parts) < 4:
            continue
        marketplace, plugin = parts[0], parts[1]
        name = skill_file.parent.name
        key = (marketplace, name)

        existing = by_key.get(key)
        if existing is not None:
            if plugin not in existing["plugins"]:
                existing["plugins"].append(plugin)
            continue

        fm = read_frontmatter(skill_file)
        display = fm.get("name") or name
        description = clean(fm.get("description", ""))
        by_key[key] = {
            "id": f"{runtime}:{marketplace}:{name}",
            "name": display,
            "slug": name,
            "description": description,
            "path": rel_home(skill_file),
            "runtime": runtime,
            "marketplace": marketplace,
            "plugins": [plugin],
            "activation": "on-demand",
            "k3_domain": classify(name, display, description),
        }

    return sorted(by_key.values(), key=lambda e: e["id"])


def scan_core_skills(root: Path, runtime: str, activation: str = "core") -> list[dict]:
    if not root.is_dir():
        return []
    entries = []
    for child in sorted(root.iterdir()):
        skill_file = child / "SKILL.md"
        if not skill_file.is_file():
            continue
        fm = read_frontmatter(skill_file)
        display = fm.get("name") or child.name
        description = clean(fm.get("description", ""))
        entries.append({
            "id": f"{runtime}:{child.name}",
            "name": display,
            "slug": child.name,
            "description": description,
            "path": rel_home(skill_file),
            "runtime": runtime,
            "marketplace": "local",
            "activation": activation,
            "symlink": child.is_symlink(),
            "k3_domain": classify(child.name, display, description),
        })
    return entries


def scan_agents(root: Path) -> list[dict]:
    if not root.is_dir():
        return []
    entries = []
    for agent_file in sorted(root.glob("*.md")):
        if agent_file.stem == "README":
            continue
        fm = read_frontmatter(agent_file)
        display = fm.get("name") or agent_file.stem
        description = clean(fm.get("description", ""))
        entries.append({
            "id": f"cursor-agent:{agent_file.stem}",
            "name": display,
            "slug": agent_file.stem,
            "description": description,
            "path": rel_home(agent_file),
            "runtime": "cursor-agent",
            "marketplace": "local",
            "activation": "core",
            "k3_domain": classify(agent_file.stem, display, description),
        })
    return entries


def scan_rules(root: Path) -> list[dict]:
    if not root.is_dir():
        return []
    entries = []
    for rule_file in sorted(root.glob("*.mdc")):
        fm = read_frontmatter(rule_file)
        entries.append({
            "id": f"cursor-rule:{rule_file.stem}",
            "name": rule_file.stem,
            "path": rel_home(rule_file),
            "runtime": "cursor-rule",
            "always_apply": fm.get("alwaysApply", "false").lower() == "true",
            "activation": "core",
        })
    return entries


def scan_profiles(root: Path) -> list[dict]:
    if not root.is_dir():
        return []
    entries = []
    for profile_file in sorted(root.glob("*.json")):
        try:
            data = json.loads(profile_file.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            data = {}
        entries.append({
            "id": f"claude-profile:{profile_file.stem}",
            "name": data.get("name", profile_file.stem),
            "path": rel_home(profile_file),
            "runtime": "claude-profile",
            "k3_domain": data.get("k3_domain", "general"),
            "default_effort": data.get("default_effort", "high"),
            "activation": "core",
        })
    return entries


def scan_mcp(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    entries = []
    for name, cfg in sorted(data.get("mcpServers", {}).items()):
        command = cfg.get("command", "")
        entries.append({
            "id": f"mcp:{name.lower()}",
            "name": name,
            "runtime": "mcp",
            "command": command,
            "args": cfg.get("args", []),
            "command_exists": bool(command) and Path(command).exists(),
            "activation": "core",
        })
    return entries


def scan_hooks(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    entries = []
    for event, hooks in sorted(data.get("hooks", {}).items()):
        for idx, hook in enumerate(hooks):
            command = hook.get("command", "")
            binary = command.split()[0] if command else ""
            entries.append({
                "id": f"hook:{event}:{idx}",
                "event": event,
                "runtime": "hook",
                "command": command,
                "binary_exists": bool(binary) and Path(binary).exists(),
                "matcher": hook.get("matcher"),
                "activation": "core",
            })
    return entries


# --- emitters -------------------------------------------------------------
def yaml_scalar(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "null"
    if isinstance(value, (int, float)):
        return str(value)
    return json.dumps(str(value), ensure_ascii=False)


def yaml_block(entries: list[dict], indent: str = "  ") -> str:
    lines = []
    for entry in entries:
        items = list(entry.items())
        head_key, head_val = items[0]
        lines.append(f"{indent}- {head_key}: {yaml_scalar(head_val)}")
        for key, value in items[1:]:
            if isinstance(value, list):
                if not value:
                    lines.append(f"{indent}  {key}: []")
                else:
                    rendered = ", ".join(yaml_scalar(v) for v in value)
                    lines.append(f"{indent}  {key}: [{rendered}]")
            else:
                lines.append(f"{indent}  {key}: {yaml_scalar(value)}")
    return "\n".join(lines)


def write_shards(entries: list[dict], prefix: str) -> list[dict]:
    grouped: dict[str, list[dict]] = {}
    for entry in entries:
        grouped.setdefault(entry["marketplace"], []).append(entry)

    shards = []
    for marketplace, items in sorted(grouped.items()):
        shard_file = SHARDS / f"{prefix}-{marketplace}.jsonl"
        with shard_file.open("w", encoding="utf-8") as fh:
            for item in items:
                fh.write(json.dumps(item, ensure_ascii=False, sort_keys=True) + "\n")
        shards.append({
            "file": f"shards/{shard_file.name}",
            "runtime": prefix,
            "marketplace": marketplace,
            "count": len(items),
        })
    return shards


def disk_counts() -> dict[str, int]:
    """Count what is on disk right now, using the same keys as the catalog."""
    return {
        "pluginSkillsCursor": len(scan_plugin_skills(HOME / ".cursor" / "plugins" / "cache", "cursor-plugin")),
        "pluginSkillsClaude": len(scan_plugin_skills(HOME / ".claude" / "plugins" / "cache", "claude-plugin")),
        "agents": len(scan_agents(HOME / ".cursor" / "agents")),
        "rules": len(scan_rules(HOME / ".cursor" / "rules")),
        "mcp": len(scan_mcp(HOME / ".cursor" / "mcp.json")),
        "hooks": len(scan_hooks(HOME / ".cursor" / "hooks.json")),
    }


def print_drift(catalog_path: Path) -> int:
    """Emit `key<TAB>disk<TAB>catalog<TAB>severity` rows for verify-integrations."""
    try:
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))["counts"]
    except (OSError, json.JSONDecodeError, KeyError):
        print(f"could not read counts from {catalog_path}", file=sys.stderr)
        return 1
    hard = {"pluginSkillsCursor", "pluginSkillsClaude"}
    for key, value in disk_counts().items():
        severity = "hard" if key in hard else "soft"
        print(f"{key}\t{value}\t{catalog.get(key, -1)}\t{severity}")
    return 0


def main() -> int:
    if "--counts" in sys.argv:
        print(json.dumps(disk_counts()))
        return 0

    if "--drift" in sys.argv:
        return print_drift(Path(sys.argv[sys.argv.index("--drift") + 1]))

    OUT.mkdir(parents=True, exist_ok=True)
    SHARDS.mkdir(parents=True, exist_ok=True)
    for stale in SHARDS.glob("*.jsonl"):
        stale.unlink()

    mcp = scan_mcp(HOME / ".cursor" / "mcp.json")
    hooks = scan_hooks(HOME / ".cursor" / "hooks.json")
    rules = scan_rules(HOME / ".cursor" / "rules")
    agents = scan_agents(HOME / ".cursor" / "agents")
    profiles = scan_profiles(HOME / ".claude" / "profiles")

    cursor_user_skills = scan_core_skills(HOME / ".cursor" / "skills", "cursor-skill")
    cursor_managed_skills = scan_core_skills(HOME / ".cursor" / "skills-cursor", "cursor-skill")
    claude_skills = scan_core_skills(HOME / ".claude" / "skills", "claude-skill")

    cursor_plugins = scan_plugin_skills(HOME / ".cursor" / "plugins" / "cache", "cursor-plugin")
    claude_plugins = scan_plugin_skills(HOME / ".claude" / "plugins" / "cache", "claude-plugin")

    shards = write_shards(cursor_plugins, "cursor") + write_shards(claude_plugins, "claude")

    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    core_yaml = f"""# SecureSkills integrations — L1 core (generated)
# Source of truth: scripts/build-integrations-catalog.sh
# Do not hand-edit; regenerate after changing MCP/hooks/rules/agents/skills.
version: 1
generated_at: "{generated_at}"

mcp:
{yaml_block(mcp)}

hooks:
{yaml_block(hooks)}

rules:
{yaml_block(rules)}

agents:
{yaml_block(agents)}

skills_cursor_user:
{yaml_block(cursor_user_skills)}

skills_cursor_managed:
{yaml_block(cursor_managed_skills)}

skills_claude:
{yaml_block(claude_skills)}

profiles:
{yaml_block(profiles)}
"""
    (OUT / "core.yaml").write_text(core_yaml, encoding="utf-8")

    catalog = {
        "version": 1,
        "generatedAt": generated_at,
        "core": "core.yaml",
        "counts": {
            "mcp": len(mcp),
            "hooks": len(hooks),
            "rules": len(rules),
            "agents": len(agents),
            "skillsCursorUser": len(cursor_user_skills),
            "skillsCursorManaged": len(cursor_managed_skills),
            "skillsClaude": len(claude_skills),
            "pluginSkillsCursor": len(cursor_plugins),
            "pluginSkillsClaude": len(claude_plugins),
            "l2Total": len(cursor_plugins) + len(claude_plugins),
        },
        "domains": {},
        "shards": shards,
        "lookupPolicy": {
            "l1": "expert-registry.yaml + integrations/core.yaml",
            "l2": "search shards by name/slug/description/k3_domain; never load whole shards into context",
            "maxActiveExperts": 16,
        },
    }
    domain_counts: dict[str, int] = {}
    for entry in cursor_plugins + claude_plugins:
        domain_counts[entry["k3_domain"]] = domain_counts.get(entry["k3_domain"], 0) + 1
    catalog["domains"] = dict(sorted(domain_counts.items(), key=lambda kv: -kv[1]))

    (OUT / "catalog.json").write_text(
        json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    shard_rows = "\n".join(
        f"| `{s['file']}` | {s['runtime']} | {s['marketplace']} | {s['count']} |" for s in shards
    )
    domain_rows = "\n".join(f"| {d} | {c} |" for d, c in catalog["domains"].items())
    index_md = f"""# Integrations catalog

Generated `{generated_at}` by `scripts/build-integrations-catalog.sh`.
Regenerate after installing/removing plugins; verify with `scripts/verify-integrations.sh`.

## Two-level routing

The K3 cognitive router never loads this catalog wholesale.

- **L1 (core)** — `expert-registry.yaml` plus [`core.yaml`](core.yaml): MCP servers,
  hooks, always-apply rules, Task agents, canonical skills and Claude profiles.
  These are the Top-k candidates (3–16 in full-spectrum).
- **L2 (on-demand)** — the JSONL shards below. The router searches them by
  `slug`, `name`, `description` or `k3_domain` only when L1 has no match, then
  activates the single skill it needs. Activated L2 skills count against Top-k.

## Counts

| Layer | Count |
|-------|-------|
| MCP servers | {len(mcp)} |
| Hooks | {len(hooks)} |
| Always-apply rules | {len(rules)} |
| Task agents | {len(agents)} |
| Cursor user skills | {len(cursor_user_skills)} |
| Cursor managed skills | {len(cursor_managed_skills)} |
| Claude skills | {len(claude_skills)} |
| L2 plugin skills | {len(cursor_plugins) + len(claude_plugins)} |

## Shards

| File | Runtime | Marketplace | Skills |
|------|---------|-------------|--------|
{shard_rows}

## L2 skills by K3 domain

| Domain | Skills |
|--------|--------|
{domain_rows}

## Querying a shard

```bash
# find every security skill mentioning "kubernetes"
grep -h kubernetes integrations/shards/*.jsonl | jq -r 'select(.k3_domain=="security") | .id'
```
"""
    (OUT / "INDEX.md").write_text(index_md, encoding="utf-8")

    print(f"catalog: {OUT / 'catalog.json'}")
    for key, value in catalog["counts"].items():
        print(f"  {key}: {value}")
    print(f"  shards: {len(shards)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
