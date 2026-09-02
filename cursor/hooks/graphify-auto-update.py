#!/usr/bin/env python3
"""Cursor afterFileEdit hook: incremental Graphify AST update (fail-open).

Finds the nearest graphify-out/graph.json from the edited file, marks the graph
dirty, and runs `graphify update .` in the background. Never blocks the agent.
Honor GRAPHIFY_SKIP_HOOK=1. Optional GRAPHIFY_AUTO_FORCEGRAPH=1 refreshes the
3D sidecar after a successful update.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse

_CODE_EXTS = {
    ".py", ".js", ".cjs", ".mjs", ".ts", ".tsx", ".jsx", ".astro", ".vue",
    ".svelte", ".go", ".rs", ".java", ".rb", ".c", ".h", ".cpp", ".hpp", ".cc",
    ".cs", ".kt", ".kts", ".swift", ".php", ".scala", ".lua", ".sh", ".md",
    ".rst", ".txt", ".mdx",
}
_DIRTY = ".graphify_dirty"
_LOCK = ".graphify_update.lock"
_LOG = ".graphify_auto_update.log"


def _fail_open() -> None:
    sys.exit(0)


def _paths_from_payload(payload: object) -> list[str]:
    found: list[str] = []
    if isinstance(payload, str) and payload:
        found.append(payload)
        return found
    if not isinstance(payload, dict):
        if isinstance(payload, list):
            for item in payload:
                found.extend(_paths_from_payload(item))
        return found
    for key in ("file_path", "path", "file", "uri"):
        val = payload.get(key)
        if isinstance(val, str) and val:
            found.append(val)
    for key in ("files", "edits", "file_paths"):
        val = payload.get(key)
        if isinstance(val, list):
            for item in val:
                found.extend(_paths_from_payload(item))
    return found


def _normalize(path: str) -> Path | None:
    raw = path.strip()
    if raw.startswith("file://"):
        parsed = urlparse(raw)
        raw = unquote(parsed.path or "")
    if not raw:
        return None
    try:
        return Path(raw).expanduser().resolve()
    except OSError:
        return None


def _graph_root(start: Path) -> Path | None:
    for parent in (start.parent, *start.parents):
        if (parent / "graphify-out" / "graph.json").is_file():
            return parent
    return None


def _is_code(path: Path) -> bool:
    return path.suffix.lower() in _CODE_EXTS


def _graphify_cmd(root: Path) -> list[str] | None:
    pinned = root / "graphify-out" / ".graphify_python"
    if pinned.is_file():
        py = pinned.read_text(encoding="utf-8").strip()
        if py and Path(py).is_file():
            return [py, "-m", "graphify"]
    exe = shutil.which("graphify") or str(Path.home() / ".local/bin/graphify")
    if Path(exe).is_file() or shutil.which("graphify"):
        return [exe if Path(exe).is_file() else "graphify"]
    return None


def _spawn_update(root: Path) -> None:
    out = root / "graphify-out"
    lock = out / _LOCK
    try:
        lock.mkdir()
    except FileExistsError:
        return
    cmd = _graphify_cmd(root)
    if not cmd:
        try:
            lock.rmdir()
        except OSError:
            pass
        return
    log = out / _LOG
    script = f"""
import os, subprocess, time
from pathlib import Path
root = Path({str(root)!r})
out = root / "graphify-out"
lock = out / { _LOCK!r }
dirty = out / { _DIRTY!r }
log = out / { _LOG!r }
cmd = {cmd!r}
try:
    rounds = 0
    while dirty.exists() and rounds < 3:
        try:
            dirty.unlink()
        except OSError:
            pass
        with log.open("a", encoding="utf-8") as fh:
            fh.write("\\n--- graphify update ---\\n")
            fh.flush()
            subprocess.run(cmd + ["update", "."], cwd=str(root), stdout=fh, stderr=fh, check=False)
        if os.environ.get("GRAPHIFY_AUTO_FORCEGRAPH") == "1":
            graph = out / "graph.json"
            if graph.is_file():
                with log.open("a", encoding="utf-8") as fh:
                    subprocess.run(cmd + ["export", "forcegraph", "--graph", str(graph), "--html"],
                                   cwd=str(root), stdout=fh, stderr=fh, check=False)
        rounds += 1
        time.sleep(0.2)
finally:
    try:
        lock.rmdir()
    except OSError:
        pass
"""
    subprocess.Popen(
        [sys.executable, "-c", script],
        cwd=str(root),
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def main() -> None:
    if os.environ.get("GRAPHIFY_SKIP_HOOK") == "1":
        _fail_open()
    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
    except (json.JSONDecodeError, OSError):
        _fail_open()
        return
    roots: set[Path] = set()
    for item in _paths_from_payload(payload):
        path = _normalize(item)
        if path is None or not _is_code(path):
            continue
        root = _graph_root(path)
        if root is not None:
            roots.add(root)
    for root in roots:
        dirty = root / "graphify-out" / _DIRTY
        try:
            dirty.write_text("1", encoding="utf-8")
        except OSError:
            continue
        _spawn_update(root)
    _fail_open()


if __name__ == "__main__":
    main()
