# claude-statusline

Minimal Unicode statusline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

```
◆  Opus 4.7 ( High ◉ )  │  ▶  projects/my-app  │  ■  ctx ████░░░░░░ 40%  ·  5h ██░░░░░░░░ 20%  ·  7d ███████░░░ 70%
```

## Install

```bash
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

Then add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

## Segments

| Icon | Segment | Description |
|------|---------|-------------|
| `◆` | Model | Active model name (e.g. Opus 4.7) |
| `◈ ● ◉ ◐ ○` | Effort | Reasoning effort level (Max / XHigh / High / Medium / Low) |
| `▶` | CWD | Last two path components of working directory |
| `■` | Context | Context window usage bar with percentage |
| `■` | 5h Rate | 5-hour rate limit usage bar with percentage |
| `■` | 7d Rate | 7-day rate limit usage bar with percentage |

`ctx`, `5h`, and `7d` share a single `■` segment, joined internally by a dimmed `·` separator. Top-level segments are joined by a dimmed `│` separator. Usage bars turn **yellow → orange → red** as they increase. Rate limit and effort segments are hidden automatically when the corresponding field is absent from the statusline JSON input.

## Requirements

- **`jq`** — used to parse the statusline JSON input. Install:
  - Windows: `winget install jqlang.jq`
  - macOS: `brew install jq`
  - Linux (Debian/Ubuntu): `sudo apt install jq`
- Bash 4+ (Git Bash on Windows works)
- A terminal that supports ANSI escape codes and Unicode

If `jq` is missing, the statusline shows a single red `■ [jq missing — install: https://jqlang.org]` notice.

## Configuration (optional)

The effort segment shows whatever level Claude Code reports for the current session. Change it any time with `/effort low|medium|high|xhigh|max` and the statusline updates immediately. If the active model does not support effort, the segment is automatically hidden.

There is nothing else to configure.

## Plugin distribution (future)

A plugin-distributed version is on hold until the Claude Code plugin system supports a main `statusLine` in plugin-bundled `settings.json` (currently only `subagentStatusLine` is supported). When that lands, this README will be updated with one-command install instructions.

## License

See [LICENSE](LICENSE).
