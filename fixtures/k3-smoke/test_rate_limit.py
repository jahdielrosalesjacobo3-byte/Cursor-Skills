"""Tests for RateLimiter (K3 smoke test B)."""

from __future__ import annotations

import unittest

from rate_limit import RateLimiter


class RateLimiterTests(unittest.TestCase):
    def test_allows_under_limit(self) -> None:
        lim = RateLimiter(3, 10.0)
        for i in range(3):
            r = lim.check("user", now=float(i))
            self.assertTrue(r.allowed, msg=f"call {i}")
        self.assertEqual(lim.check("user", now=2.0).remaining, 0)

    def test_blocks_over_limit(self) -> None:
        lim = RateLimiter(2, 10.0)
        self.assertTrue(lim.check("a", now=0.0).allowed)
        self.assertTrue(lim.check("a", now=1.0).allowed)
        blocked = lim.check("a", now=2.0)
        self.assertFalse(blocked.allowed)
        self.assertEqual(blocked.remaining, 0)
        self.assertGreater(blocked.retry_after_seconds, 0)

    def test_window_slides(self) -> None:
        lim = RateLimiter(1, 5.0)
        self.assertTrue(lim.check("x", now=0.0).allowed)
        self.assertFalse(lim.check("x", now=1.0).allowed)
        self.assertTrue(lim.check("x", now=5.1).allowed)

    def test_keys_are_isolated(self) -> None:
        lim = RateLimiter(1, 10.0)
        self.assertTrue(lim.check("u1", now=0.0).allowed)
        self.assertTrue(lim.check("u2", now=0.0).allowed)

    def test_rejects_invalid_config(self) -> None:
        with self.assertRaises(ValueError):
            RateLimiter(0, 1.0)
        with self.assertRaises(ValueError):
            RateLimiter(1, 0.0)


if __name__ == "__main__":
    unittest.main()
