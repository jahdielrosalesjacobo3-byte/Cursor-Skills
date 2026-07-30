# Integrations catalog

Generated `2026-07-30T17:34:43Z` by `scripts/build-integrations-catalog.sh`.
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
| MCP servers | 2 |
| Hooks | 4 |
| Always-apply rules | 2 |
| Task agents | 49 |
| Cursor user skills | 20 |
| Cursor managed skills | 19 |
| Claude skills | 40 |
| L2 plugin skills | 5078 |

## Shards

| File | Runtime | Marketplace | Skills |
|------|---------|-------------|--------|
| `shards/cursor-agent-browser.jsonl` | cursor | agent-browser | 7 |
| `shards/cursor-agentic-awesome-skills.jsonl` | cursor | agentic-awesome-skills | 1913 |
| `shards/cursor-antigravity-awesome-skills.jsonl` | cursor | antigravity-awesome-skills | 1437 |
| `shards/cursor-claude-code-skills.jsonl` | cursor | claude-code-skills | 11 |
| `shards/cursor-claude-plugins-official.jsonl` | cursor | claude-plugins-official | 1 |
| `shards/cursor-cursor-public.jsonl` | cursor | cursor-public | 132 |
| `shards/cursor-hackingtool-marketplace.jsonl` | cursor | hackingtool-marketplace | 1 |
| `shards/cursor-karpathy-skills.jsonl` | cursor | karpathy-skills | 1 |
| `shards/cursor-ruflo.jsonl` | cursor | ruflo | 13 |
| `shards/claude-agent-browser.jsonl` | claude | agent-browser | 7 |
| `shards/claude-antigravity-awesome-skills.jsonl` | claude | antigravity-awesome-skills | 1436 |
| `shards/claude-claude-plugins-official.jsonl` | claude | claude-plugins-official | 15 |
| `shards/claude-hackingtool-marketplace.jsonl` | claude | hackingtool-marketplace | 1 |
| `shards/claude-netresearch-claude-code-marketplace.jsonl` | claude | netresearch-claude-code-marketplace | 1 |
| `shards/claude-ruflo.jsonl` | claude | ruflo | 102 |

## L2 skills by K3 domain

| Domain | Skills |
|--------|--------|
| general | 1125 |
| agentic | 901 |
| coding | 881 |
| infra | 787 |
| design | 605 |
| security | 577 |
| research | 123 |
| trading | 79 |

## Querying a shard

```bash
# find every security skill mentioning "kubernetes"
grep -h kubernetes integrations/shards/*.jsonl | jq -r 'select(.k3_domain=="security") | .id'
```
