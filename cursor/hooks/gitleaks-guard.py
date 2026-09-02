#!/usr/bin/env python3
"""Cursor beforeShellExecution hook: block `git commit` / `git push` that would ship secrets.

- commit  -> gitleaks git --staged (pre-commit mode)
- push    -> gitleaks git over @{upstream}..HEAD (falls back to HEAD~10..HEAD)
Fail-open on tool errors/timeouts; deny only on confirmed leaks (gitleaks exit 2).
Opt out per command with GITLEAKS_SKIP_HOOK=1 or `# gitleaks:allow` handled upstream.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

_COMMIT = re.compile(r"(^|[;&|]\s*)git\b[^;&|]*\bcommit\b")
_PUSH = re.compile(r"(^|[;&|]\s*)git\b[^;&|]*\bpush\b")
_TIMEOUT_S = 25


def _allow(agent_message: str | None = None) -> None:
    out = {"permission": "allow"}
    if agent_message:
        out["agent_message"] = agent_message
    print(json.dumps(out))
    sys.exit(0)


def _deny(user_message: str, agent_message: str) -> None:
    print(json.dumps({
        "permission": "deny",
        "user_message": user_message,
        "agent_message": agent_message,
    }))
    sys.exit(0)


def _repo_root(cwd: str) -> str | None:
    try:
        res = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=cwd, capture_output=True, text=True, timeout=5, check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    root = res.stdout.strip()
    return root if res.returncode == 0 and root else None


def _rev_ok(root: str, rev: str) -> bool:
    res = subprocess.run(
        ["git", "rev-parse", "--verify", "--quiet", rev],
        cwd=root, capture_output=True, text=True, timeout=5, check=False,
    )
    return res.returncode == 0


def _push_range(root: str) -> str:
    if _rev_ok(root, "@{upstream}"):
        return "@{upstream}..HEAD"
    if _rev_ok(root, "HEAD~10"):
        return "HEAD~10..HEAD"
    return "HEAD"  # young repo without upstream: scan everything reachable


def _summarize(report_path: str, limit: int = 6) -> list[str]:
    try:
        with open(report_path, encoding="utf-8") as fh:
            findings = json.load(fh)
    except (OSError, json.JSONDecodeError):
        return []
    lines = []
    for f in findings[:limit]:
        lines.append(
            f"{f.get('RuleID', 'rule')} @ {f.get('File', '?')}:{f.get('StartLine', '?')}"
        )
    if len(findings) > limit:
        lines.append(f"... +{len(findings) - limit} more")
    return lines


def _run_gitleaks(args: list[str], root: str) -> tuple[int, list[str], str]:
    fd, report = tempfile.mkstemp(prefix="gitleaks-", suffix=".json")
    os.close(fd)
    try:
        res = subprocess.run(
            ["gitleaks", *args, "--redact", "--no-banner", "--exit-code", "2",
             "--report-format", "json", "--report-path", report],
            cwd=root, capture_output=True, text=True, timeout=_TIMEOUT_S, check=False,
        )
        return res.returncode, _summarize(report), (res.stderr or "")[-400:]
    finally:
        try:
            os.unlink(report)
        except OSError:
            pass


def main() -> None:
    if os.environ.get("GITLEAKS_SKIP_HOOK") == "1":
        _allow()
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except json.JSONDecodeError:
        _allow()
        return
    command = str(payload.get("command") or "")
    is_commit = bool(_COMMIT.search(command))
    is_push = bool(_PUSH.search(command))
    if not (is_commit or is_push):
        _allow()
    if not shutil.which("gitleaks"):
        _allow("gitleaks not installed (brew install gitleaks); secret scan skipped.")
    cwd = str(payload.get("cwd") or payload.get("workspace_root") or os.getcwd())
    root = _repo_root(cwd)
    if not root:
        _allow()
        return

    try:
        if is_commit:
            code, summary, err = _run_gitleaks(["git", "--pre-commit", "--staged"], root)
            scope = "staged changes"
        else:
            rng = _push_range(root)
            code, summary, err = _run_gitleaks(["git", f"--log-opts={rng}"], root)
            scope = f"unpushed commits ({rng})"
    except subprocess.TimeoutExpired:
        _allow("gitleaks timed out; secret scan skipped (fail-open).")
        return
    except OSError as exc:
        _allow(f"gitleaks could not run ({exc}); secret scan skipped.")
        return

    if code == 2:
        detail = "\n".join(f"  - {s}" for s in summary) or "  - see `gitleaks git --staged -v`"
        _deny(
            f"gitleaks found potential secrets in {scope}; the git command was blocked.",
            "Blocked by gitleaks-guard: potential secrets in "
            f"{scope}:\n{detail}\nRemove the secret (use env vars / a vault), "
            "or add `# gitleaks:allow` for a verified false positive, then retry. "
            "Do not bypass with GITLEAKS_SKIP_HOOK unless the user approves.",
        )
    if code == 0:
        _allow()
    _allow(f"gitleaks exited {code} (scan error); secret scan skipped. {err.strip()}")


if __name__ == "__main__":
    main()
