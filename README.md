# claude-statusline

Minimal Unicode statusline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

```
◆  Opus 4.7 ( High ◉ )  │  ▶  projects/my-app  │  ■  ctx ████░░░░░░ 40%  ·  5h ██░░░░░░░░ 20%  ·  7d ███████░░░ 70%
```

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

### Step 2 — Download the script

**Option A — one-liner (recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/seokjw0727/claude-statusline/v0.1.0/statusline-command.sh \
  -o ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

**Option B — `git clone`:**

```bash
git clone https://github.com/seokjw0727/claude-statusline.git
cp claude-statusline/statusline-command.sh ~/.claude/statusline-command.sh
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
◆  Opus 4.7 ( High ◉ )  │  ▶  projects/my-app  │  ■  ctx ████░░░░░░ 40%  ·  5h ██░░░░░░░░ 20%  ·  7d ███████░░░ 70%
```

## Updating

Re-run the Step 2 one-liner with the desired tag (e.g. `v0.2.0`) to overwrite the existing script:

```bash
curl -fsSL https://raw.githubusercontent.com/seokjw0727/claude-statusline/v0.1.0/statusline-command.sh \
  -o ~/.claude/statusline-command.sh
```

See [CHANGELOG.md](CHANGELOG.md) for what changed between versions.

## Segments

| Icon | Segment | Description |
|------|---------|-------------|
| `◆` | Model | Active model name (e.g. Opus 4.7) |
| `◈ ● ◉ ◐ ○` | Effort | Reasoning effort level (Max / XHigh / High / Medium / Low) |
| `▶` | CWD | Last two path components of the working directory |
| `■` | Context | Context window usage bar with percentage |
| `■` | 5h Rate | 5-hour rate limit usage bar with percentage |
| `■` | 7d Rate | 7-day rate limit usage bar with percentage |

`ctx`, `5h`, and `7d` share a single `■` segment, joined internally by a dimmed `·` separator. Top-level segments are joined by a dimmed `│` separator. Usage bars turn **yellow → orange → red** as they increase. Rate limit and effort segments are hidden automatically when the corresponding field is absent from the statusline JSON input.

## Configuration (optional)

The effort segment shows whatever level Claude Code reports for the current session. Change it any time with `/effort low|medium|high|xhigh|max` and the statusline updates immediately. If the active model does not support effort, the segment is automatically hidden.

There is nothing else to configure.

## Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| Red `■ [jq missing — install: https://jqlang.org]` is the only thing rendered | `jq` is not on PATH. Re-run Step 1 and restart your terminal so the new PATH is picked up. |
| Statusline is empty or shows garbled characters | Terminal does not support ANSI escape codes or Unicode. Switch to Windows Terminal, iTerm2, WezTerm, Alacritty, or another modern terminal. |
| Effort segment (the `( … )` part) does not appear | Expected when the active model does not support effort. Run `/effort high` to set it explicitly. |
| Statusline does not appear at all | Confirm `~/.claude/settings.json` uses `statusLine` (camelCase) with the object form `{ "type": "command", "command": "..." }`. The older lowercase `statusline` key with a string value is no longer the standard. |
| `bash: jq: command not found` only inside Claude Code | Claude Code launched the script with a PATH that does not include `jq`. Easiest fix: install `jq` via the OS package manager from Step 1, then restart Claude Code so it inherits the updated PATH. |

## Plugin distribution (future)

A plugin-distributed version is on hold until the Claude Code plugin system supports a main `statusLine` in plugin-bundled `settings.json` (currently only `subagentStatusLine` is supported). When that lands, this README will be updated with one-command install instructions.

## License

See [LICENSE](LICENSE).
