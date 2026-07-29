"""Simple in-memory sliding-window rate limiter (K3 smoke test B)."""

from __future__ import annotations

import time
from collections import defaultdict, deque
from dataclasses import dataclass


@dataclass(frozen=True)
class RateLimitResult:
    allowed: bool
    remaining: int
    retry_after_seconds: float


class RateLimiter:
    """Allow at most `max_calls` per `window_seconds` for a given key."""

    def __init__(self, max_calls: int, window_seconds: float) -> None:
        if max_calls < 1:
            raise ValueError("max_calls must be >= 1")
        if window_seconds <= 0:
            raise ValueError("window_seconds must be > 0")
        self.max_calls = max_calls
        self.window_seconds = window_seconds
        self._hits: dict[str, deque[float]] = defaultdict(deque)

    def _prune(self, key: str, now: float) -> None:
        q = self._hits[key]
        cutoff = now - self.window_seconds
        while q and q[0] <= cutoff:
            q.popleft()

    def check(self, key: str, *, now: float | None = None) -> RateLimitResult:
        ts = time.monotonic() if now is None else now
        self._prune(key, ts)
        q = self._hits[key]
        if len(q) >= self.max_calls:
            retry = self.window_seconds - (ts - q[0])
            return RateLimitResult(False, 0, max(retry, 0.0))
        q.append(ts)
        remaining = self.max_calls - len(q)
        return RateLimitResult(True, remaining, 0.0)
