# claude-statusline

Minimal Unicode statusline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

```
◆  Opus 4.7 ( High ◉ )  │  ▶  projects/my-app  │  ■  ctx ████░░░░░░ 40%
Claude  5h ██░░░░░░░░ 20%  ·  7d ███████░░░ 70%  │  Codex  5h █░░░░░░░░░ 12%  ·  7d ████░░░░░░ 38%
```

A single-line variant is still trivial to make — the second line only appears when rate-limit data is present.

## Install

### Step 1 — Install `jq`

`jq` is required to parse the statusline JSON input.

| OS | Command |
|----|---------|
| Windows | `winget install jqlang.jq` |
| macOS | `brew install jq` |
| Linux (Debian / Ubuntu) | `sudo apt install jq` |
| Linux (Fedora / RHEL) | `sudo dnf install jq` |

Verify with `jq --version`.

> **Codex usage (optional):** the second-line Codex segment additionally needs `python` on PATH and at least one local [Codex CLI](https://github.com/openai/codex) session under `~/.codex/sessions`. Without either, the Codex segment is silently hidden — everything else still renders.

### Step 2 — Download the script

**Option A — one-liner (recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/seokjw0727/claude-statusline/v0.2.0/statusline-command.sh \
  -o ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh

# Optional — Codex 5h/7d usage helper
curl -fsSL https://raw.githubusercontent.com/seokjw0727/claude-statusline/v0.2.0/codex-limits.py \
  -o ~/.claude/codex-limits.py
```

**Option B — `git clone`:**

```bash
git clone https://github.com/seokjw0727/claude-statusline.git
cp claude-statusline/statusline-command.sh ~/.claude/statusline-command.sh
cp claude-statusline/codex-limits.py       ~/.claude/codex-limits.py   # optional, for Codex usage
chmod +x ~/.claude/statusline-command.sh
```

> **Windows note:** run these commands in **Git Bash** (bundled with [Git for Windows](https://gitforwindows.org/)). `~` resolves to `C:\Users\<USER>`.

### Step 3 — Register the statusline in Claude Code

Open `~/.claude/settings.json` and add the `statusLine` key (merge into the existing object if other keys are present):

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

### Step 4 — Reload and verify

Restart your Claude Code session (or open a new one). The statusline should appear at the bottom of the window:

```
◆  Opus 4.7 ( High ◉ )  │  ▶  projects/my-app  │  ■  ctx ████░░░░░░ 40%
Claude  5h ██░░░░░░░░ 20%  ·  7d ███████░░░ 70%  │  Codex  5h █░░░░░░░░░ 12%  ·  7d ████░░░░░░ 38%
```

## Updating

Re-run the Step 2 one-liner with the desired tag (e.g. `v0.2.0`) to overwrite the existing script:

```bash
curl -fsSL https://raw.githubusercontent.com/seokjw0727/claude-statusline/v0.2.0/statusline-command.sh \
  -o ~/.claude/statusline-command.sh
```

See [CHANGELOG.md](CHANGELOG.md) for what changed between versions.

## Segments

The statusline renders on two lines.

**Line 1 — session context:**

| Icon | Segment | Description |
|------|---------|-------------|
| `◆` | Model | Active model name (e.g. Opus 4.7) |
| `◈ ● ◉ ◐ ○` | Effort | Reasoning effort level (Max / XHigh / High / Medium / Low) |
| `▶` | CWD | Last two path components of the working directory |
| `■` | Context | Context window usage bar with percentage |

**Line 2 — rate limits:**

| Group | Segment | Description |
|-------|---------|-------------|
| `Claude` | 5h / 7d | Claude's own 5-hour and 7-day rate-limit usage bars (from the statusline JSON) |
| `Codex` | 5h / 7d | Codex 5-hour and 7-day usage bars, parsed from the latest `~/.codex` session (requires `python`) |

Top-level segments are joined by a dimmed `│` separator; the two limits inside a group are joined by a dimmed `·`. All usage bars are 10 characters wide and turn **yellow → orange → red** as they increase. Each segment is hidden automatically when its data is absent — so without `python` or a Codex session, line 2 shows only **Claude**, and if no rate-limit data is present at all, line 2 is omitted entirely.

## Configuration (optional)

The effort segment shows whatever level Claude Code reports for the current session. Change it any time with `/effort low|medium|high|xhigh|max` and the statusline updates immediately. If the active model does not support effort, the segment is automatically hidden.

There is nothing else to configure.

## Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| Red `■ [jq missing — install: https://jqlang.org]` is the only thing rendered | `jq` is not on PATH. Re-run Step 1 and restart your terminal so the new PATH is picked up. |
| Statusline is empty or shows garbled characters | Terminal does not support ANSI escape codes or Unicode. Switch to Windows Terminal, iTerm2, WezTerm, Alacritty, or another modern terminal. |
| Effort segment (the `( … )` part) does not appear | Expected when the active model does not support effort. Run `/effort high` to set it explicitly. |
| Codex segment never appears | Requires `python` on PATH and at least one `~/.codex/sessions/rollout-*.jsonl` from the Codex CLI. Without either, the segment is silently hidden — Claude limits still render. |
| Second line wraps on a narrow terminal | All four rate-limit bars plus separators are wide. Widen the terminal, or shrink the bars by lowering the width passed to `ctx_bar` inside `rl_seg`. |
| Statusline does not appear at all | Confirm `~/.claude/settings.json` uses `statusLine` (camelCase) with the object form `{ "type": "command", "command": "..." }`. The older lowercase `statusline` key with a string value is no longer the standard. |
| `bash: jq: command not found` only inside Claude Code | Claude Code launched the script with a PATH that does not include `jq`. Easiest fix: install `jq` via the OS package manager from Step 1, then restart Claude Code so it inherits the updated PATH. |

## Plugin distribution (future)

A plugin-distributed version is on hold until the Claude Code plugin system supports a main `statusLine` in plugin-bundled `settings.json` (currently only `subagentStatusLine` is supported). When that lands, this README will be updated with one-command install instructions.

## License

See [LICENSE](LICENSE).
