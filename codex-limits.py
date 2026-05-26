"""Parse latest Codex session rollout for rate-limit usage.

Output: "PRIMARY_PCT|SECONDARY_PCT" (e.g. "18|6"). Either side may be empty
on missing data. Silent failure (empty stdout) on any error.

Used by ~/.claude/statusline-command.sh to display Codex 5h/7d usage
alongside Claude's own limits.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

SESS = Path.home() / ".codex" / "sessions"
TAIL_BYTES = 256 * 1024  # read last 256 KB of the rollout — token_count events sit near tail


def find_latest_rollout() -> Path | None:
    if not SESS.is_dir():
        return None
    best: Path | None = None
    best_mtime = -1.0
    for p in SESS.rglob("rollout-*.jsonl"):
        try:
            st = p.stat()
        except OSError:
            continue
        if st.st_size == 0:
            continue
        if st.st_mtime > best_mtime:
            best_mtime = st.st_mtime
            best = p
    return best


def read_tail(path: Path, n: int) -> str:
    try:
        size = path.stat().st_size
        with path.open("rb") as f:
            if size > n:
                f.seek(size - n)
                f.readline()  # drop partial first line
            return f.read().decode("utf-8", errors="replace")
    except OSError:
        return ""


def find_rate_limits(obj):
    """Recursively locate the innermost dict containing primary/secondary keys."""
    if isinstance(obj, dict):
        rl = obj.get("rate_limits")
        if isinstance(rl, dict) and ("primary" in rl or "secondary" in rl):
            return rl
        for v in obj.values():
            r = find_rate_limits(v)
            if r:
                return r
    elif isinstance(obj, list):
        for v in obj:
            r = find_rate_limits(v)
            if r:
                return r
    return None


def fmt_pct(v) -> str:
    if v is None:
        return ""
    try:
        return str(int(round(float(v))))
    except (TypeError, ValueError):
        return ""


def main() -> None:
    p = find_latest_rollout()
    if p is None:
        return
    tail = read_tail(p, TAIL_BYTES)
    if not tail:
        return
    last_rl = None
    for line in tail.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except (ValueError, json.JSONDecodeError):
            continue
        rl = find_rate_limits(obj)
        if rl:
            last_rl = rl
    if not last_rl:
        return
    primary = last_rl.get("primary") or {}
    secondary = last_rl.get("secondary") or {}
    sys.stdout.write(f"{fmt_pct(primary.get('used_percent'))}|{fmt_pct(secondary.get('used_percent'))}")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
