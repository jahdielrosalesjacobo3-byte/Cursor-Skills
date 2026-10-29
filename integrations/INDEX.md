# Integrations catalog

Generated `2026-10-29T23:11:30Z` by `scripts/build-integrations-catalog.sh`.
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
| MCP servers | 11 |
| Hooks | 6 |
| Always-apply rules | 9 |
| Task agents | 49 |
| Cursor user skills | 22 |
| Cursor managed skills | 25 |
| Claude skills | 40 |
| Local plugin skills (L1-adjacent) | 23 |
| L2 plugin skills | 5229 |

## Shards

| File | Runtime | Marketplace | Skills |
|------|---------|-------------|--------|
| `shards/cursor-local-plugin.jsonl` | cursor | local-plugin | 23 |
| `shards/cursor-agent-browser.jsonl` | cursor | agent-browser | 7 |
| `shards/cursor-agentic-awesome-skills.jsonl` | cursor | agentic-awesome-skills | 1913 |
| `shards/cursor-antigravity-awesome-skills.jsonl` | cursor | antigravity-awesome-skills | 1437 |
| `shards/cursor-claude-code-skills.jsonl` | cursor | claude-code-skills | 11 |
| `shards/cursor-claude-plugins-official.jsonl` | cursor | claude-plugins-official | 1 |
| `shards/cursor-cursor-public.jsonl` | cursor | cursor-public | 283 |
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
| general | 1155 |
| agentic | 925 |
| coding | 913 |
| infra | 826 |
| design | 614 |
| security | 590 |
| research | 126 |
| trading | 80 |

## Querying a shard

```bash
# find every security skill mentioning "kubernetes"
grep -h kubernetes integrations/shards/*.jsonl | jq -r 'select(.k3_domain=="security") | .id'
```
