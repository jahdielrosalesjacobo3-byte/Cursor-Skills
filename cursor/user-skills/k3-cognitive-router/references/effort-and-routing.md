# Effort, teachers, and routing (post polish)

## 9-teacher surface

Paper trains 3 domains × {low, high, max}. We expose the same surface via `teacher_matrix` in `expert-registry.yaml`.

1. Map fine `domain` → `teacher_family` (`teacher_family_map`)
2. Select `teacher_matrix[family][effort]`
3. Optionally merge 1–2 from `domain_routings` if specialized (e.g. trading)
4. Cap at 8; apply quantile balancing with `expert_usage`

## Effort budgets

| Effort | τ | When |
|--------|---|------|
| low | 0.5 | Q&A, tiny edits |
| high | 1.0 | Default multi-step |
| max | 1.5–2.0 | Audits, deep research, long agentic — then anneal down if thrashing |

## AttnRes keys (examples)

`plan`, `rubric`, `scorepad`, `diff_summary`, `security_findings`, `test_results`, `paused_rollouts`, `open_questions`

## Anti-patterns

1. Spawning all ruflo agents  
2. Mega catalog activation  
3. Dropping scratchpad between tools  
4. Declaring done on `max` without GRM scorepad  
5. Ignoring `paused_rollouts` next turn  
6. Preferring `cyber-*` over `01–19`  
7. Requiring Snyk Code  
