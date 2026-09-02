# Latency / Composer Fast path

Goal: **same capabilities**, less ceremony on simple turns — fewer tokens in rules, fewer tool rounds, no subagent fan-out.

## When fast path applies (default)

- Single-turn questions, explanations, small diffs, git status, config checks
- User chose a fast model (e.g. Composer 2.5 Fast) without asking for orchestration
- User says: `rápido`, `velocidad`, `sin rodeos`, `composer fast` → harness `composer-fast`

## Fast path checklist

| Do | Skip |
|----|------|
| Answer in the first useful reply | RAOVA narration in user-visible text |
| Parallel read/grep/shell when safe | Task subagents |
| `effort: low`, Top-k 0–2 | `.k3/orchestrator-state.json` |
| L1 experts only if one skill clearly fits | L2 shard grep |
| Semgrep **after** writing code | Blocking scan before first reply on non-code |
| One Graphify query when `graph.json` exists and the question is structural | Full orchestration / subagents for simple path lookup |

## When to escalate (same turn or next)

- User asks for audit, deep research, multi-agent, SPARC, or full-spectrum phrases
- Task needs >1 file area + tests + review
- Security incident / max effort explicitly requested

## Harness

- Default hint: `composer-fast` (see `harness-profiles.yaml`)
- Depth: `coding-default`, `security-max`, `full-spectrum`, etc.

## Registry

`routing_defaults.default_effort: low` and `fast_path` in `expert-registry.yaml`.
