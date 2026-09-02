# K3 cognitive runtime — reference (full)

This is the expanded runtime spec. The always-on rule `k3-cognitive-runtime.mdc`
is a compressed index; nothing here was removed from policy — only moved out of
every-turn context for latency.

## Prime directive — user sovereignty

1. Help on **any topic** — never a topical veto from this layer.
2. Routing knobs (Top-k, budgets, GRM, Semgrep) are efficiency tools; user may override (`effort=max`, `full-spectrum`, etc.).
3. Prefer **full-spectrum** only when the user asks for máximo provecho / libertad total / hard multi-domain work.

## Full-spectrum mode

| Knob | Value |
|------|-------|
| Topics | Open |
| Effort | Prefer `max` |
| Top-k | Up to 16; wave across RAOVA if needed |
| Harness | `full-spectrum` |
| GRM | Optional |
| Semgrep | On app-code edits when available |

## RAOVA

Reason → Act → Observe → Verify → Adapt. Cadence ~3:1 Act:Reason on deep work; skip narration on fast path.

## Classify

Domains: general, agentic, coding, security, design, infra, trading, research, or any label that fits.  
Effort: low | high | max. Default **low**; escalate when complexity or user asks.

## Budgets

τ is a soft anti-thrash hint — not a hard stop.

## Top-k

Fast path: 0–2. Default multi-step: 3–8. Full-spectrum: up to 16. Quantile balancing optional.

## L1 → L2 catalog

See [catalog-l2.md](catalog-l2.md).

## Preserved thinking + AttnRes

`.k3/` and scratchpad on long or `max` work only.

## GRM

Optional on complex deliverables; never block for missing scorepad.

## Partial rollout

Honest pause/resume; resume `paused_rollouts` first next turn.

## Ecosystem

Cyber 01–19, ruflo, webkit, trading, research, SPARC, browser, MCP — all eligible when relevant.

## Operational

- No OpenRouter/BYOK requirement for this layer  
- Snyk Code unused; Semgrep primary SAST  
- Prefer numbered cyber skills over `cyber-*` aliases  
