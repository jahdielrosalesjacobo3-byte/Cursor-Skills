# L2 catalog lookup

The router works from a two-level catalog so that thousands of marketplace
skills stay reachable without ever entering the context window.

| Level | Where | Contents | How it is used |
|-------|-------|----------|----------------|
| **L1** | `expert-registry.yaml`, `integrations/core.yaml` | Curated experts, MCP servers, hooks, always-apply rules, Task agents, canonical skills, Claude profiles | Always eligible; these are the Top-k candidates |
| **L2** | `integrations/shards/*.jsonl` indexed by `integrations/catalog.json` | ~5k plugin skills across the Cursor and Claude marketplaces | Searched on demand, one skill at a time |

Installed copies live at `~/.cursor/secureskills/integrations/`; the repo copies
under `SecureSkills/integrations/` are the source of truth.

## When to reach for L2

Go to L2 only when one of these holds:

- No L1 expert covers the task.
- The user names a skill, plugin or marketplace explicitly.
- The active harness profile lists `catalog_access: l2_on_demand` and the task
  falls inside one of its `preferred_marketplaces`.

Profiles with `catalog_access: none` (for example `general-light`) stay on L1.

## How to search

Each shard is JSON Lines — one skill per line, so `grep` is enough and you never
need to parse a whole file.

```bash
CAT=~/.cursor/secureskills/integrations   # or SecureSkills/integrations

# by keyword, showing id + description
grep -ih 'kubernetes' "$CAT"/shards/*.jsonl \
  | python3 -c 'import sys,json;[print(json.loads(l)["id"], "—", json.loads(l)["description"][:90]) for l in sys.stdin]' \
  | head -20

# scoped to one domain and one marketplace
grep -h '"k3_domain": "security"' "$CAT"/shards/cursor-hackingtool-marketplace.jsonl | head

# what shards exist and how big they are
python3 -c 'import json;[print(s["file"], s["count"]) for s in json.load(open("'"$CAT"'/catalog.json"))["shards"]]'
```

Each record carries `id`, `name`, `slug`, `description`, `path`, `runtime`,
`marketplace`, `plugins`, `activation` and `k3_domain`.

## How to activate

1. Pick **one** candidate from the search results.
2. Read its `path` (a single `SKILL.md`) and follow it.
3. Count it against Top-k — L2 skills are not free.
4. Stop at **4 L2 activations per task**; beyond that, re-`Reason` instead of
   pulling more skills.

## Hard limits

- Never read a whole shard into context, and never paste the catalog into a reply.
- Never activate a batch of L2 skills speculatively; fan out in waves across
  RAOVA cycles instead.
- If the search returns nothing useful, say so and proceed with L1 — a missing
  L2 match is not a reason to stop working on the user's goal.

## Keeping it fresh

```bash
bash scripts/build-integrations-catalog.sh   # rescan disk, rewrite shards
bash scripts/verify-integrations.sh          # health + drift check
```

`verify-integrations.sh` fails hard when the plugin skill count drifts more than
`DRIFT_TOLERANCE` (25 by default) from what is on disk.
