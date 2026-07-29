# Partial rollout resume semantics

Inspired by K3 partial rollouts + resumable sandboxes (§4.1.2 / §5.3).

## When to pause

- User interrupts / switches topic mid-task
- Blocked on external auth, missing secrets, or human decision
- Long-tail tool work still running conceptually next turn
- Budget τ exhausted without success → checkpoint rather than thrash

## State

```json
"paused_rollouts": [
  {
    "id": "pr-auth-tests",
    "summary": "Rate limiter implemented; 2 tests still failing",
    "status": "paused",
    "resume_hint": "Fix window-edge assertion in test_window_slides",
    "experts": ["coder", "tester"]
  }
]
```

Status machine: `paused` → `ready` → `done` | `failed`.

## Next-turn priority (λ-style)

1. Load `.k3/orchestrator-state.json` if present  
2. Resume all `paused`/`ready` rollouts first  
3. Only then accept new scope  
4. On completion, mark `done` and clear or archive  

Never invent success for paused work.
