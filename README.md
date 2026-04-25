# claude-statusline

Minimal Unicode statusline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Segments

| Icon | Segment | Description |
|------|---------|-------------|
| `◆` | Model | Active model name (e.g. Opus 4.6) |
| `◈ ● ◉ ◐ ○` | Effort | Reasoning effort level (Max / XHigh / High / Medium / Low) |
| `▶` | CWD | Last two path components of working directory |
| `■` | Context | Context window usage bar with percentage |
| `■` | 5h Rate | 5-hour rate limit usage bar with percentage |
| `■` | 7d Rate | 7-day rate limit usage bar with percentage |

`ctx`, `5h`, and `7d` share a single `■` segment, joined internally by a dimmed `·` separator. Top-level segments are joined by a dimmed `│` separator. Usage bars turn **yellow → orange → red** as they increase. Rate limit segments are hidden automatically when the corresponding field is absent from the statusline JSON input.

## Installation

### 1. Copy the script

```bash
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

### 2. Configure Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "statusline": "bash ~/.claude/statusline-command.sh"
}
```

### 3. Requirements

- `jq` — used to parse the statusline JSON input
- Bash 4+ (Git Bash on Windows works)
- A terminal that supports ANSI escape codes and Unicode

## License

MIT
