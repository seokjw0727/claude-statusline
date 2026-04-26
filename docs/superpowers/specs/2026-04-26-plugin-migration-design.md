# Plugin Migration Design

**Date:** 2026-04-26
**Status:** Superseded — see ADDENDUM below
**Scope:** Convert manual-install statusline to a Claude Code marketplace plugin

---

## ADDENDUM (2026-04-26, post-approval)

During execution Task 0 (manifest spec verification), the official Claude Code plugin documentation was confirmed to state:

> "Plugins can include a `settings.json` file at the plugin root to apply default configuration when the plugin is enabled. **Currently, only the `agent` and `subagentStatusLine` keys are supported.**"
>
> — https://code.claude.com/docs/en/plugins.md

This means a plugin **cannot distribute a main `statusLine` configuration**. Only `subagentStatusLine` (for subagents, a different feature) is supported. Even after `/plugin install`, users would still have to manually add a `statusLine` block to their personal `~/.claude/settings.json` to actually activate the statusline — defeating the central benefit of plugin distribution.

**New scope (v0.1.0):** drop plugin packaging entirely. Keep the parts of this design that produce immediate value to all users:
- Script portability fixes (jq detection, `.effort.level` from statusline JSON, dead code removal)
- LICENSE + CHANGELOG file additions
- README cleanup (manual install only, with OS-specific jq install commands)

**Dropped from scope:** `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`, the "Migrating from manual install" section, plugin install commands in README, and all plugin-install smoke tests.

**Plugin distribution is deferred** until the Claude Code plugin system supports `statusLine` in a plugin's bundled `settings.json`. When that lands, a follow-up release will add the manifest files; the script and other changes from this release will not need to be redone.

The remainder of this document reflects the **original** plugin-packaging plan and is preserved as a record. Sections that no longer apply (Manifest files, Plugin identifiers, Migrating from manual install, plugin smoke tests, plugin parts of release process) are obsolete — see the updated plan for what was actually executed.

---

## Goal

Distribute `claude-statusline` as an installable Claude Code plugin so that users can install with two slash commands and receive automatic updates, instead of manually copying a script and editing `settings.json`.

This is the **minimum-scope (MVP)** release. No new features, no segment toggles, no theming. The release packages the existing statusline as a plugin and removes environment dependencies that prevent it from working on other users' machines.

## Out of scope (deferred)

- User-configurable segments (which to show/hide)
- Theme system (color palettes, dark/light variants)
- Modular per-segment files
- Unit tests / CI
- Cross-OS smoke testing on macOS/Linux (no machines available; rely on portable code + user feedback)

## Repo layout

```
claude-statusline/
├── .claude-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── statusline-command.sh        # script stays at repo root
├── README.md                    # rewritten: plugin install primary, manual fallback
├── LICENSE                      # extracted from README
├── CHANGELOG.md                 # new, starts at 0.1.0
└── docs/superpowers/specs/
    └── 2026-04-26-plugin-migration-design.md  # this file
```

The script remains at the repo root (rather than under a `plugins/<name>/` subdirectory) so the repo can later be split out as a standalone plugin if the marketplace is ever moved to its own repo.

## Identifiers

| Field | Value |
|---|---|
| Marketplace name | `seokjw0727` |
| Plugin name | `claude-statusline` |
| Initial version | `0.1.0` |
| License | MIT |

User install commands:
```
/plugin marketplace add seokjw0727/claude-statusline
/plugin install claude-statusline@seokjw0727
```

## Manifest files

### `.claude-plugin/marketplace.json`
```json
{
  "name": "seokjw0727",
  "owner": {
    "name": "seokjw0727",
    "url": "https://github.com/seokjw0727"
  },
  "plugins": [
    {
      "name": "claude-statusline",
      "source": "./",
      "description": "Minimal Unicode statusline for Claude Code (model · effort · cwd · ctx · 5h · 7d)",
      "version": "0.1.0",
      "category": "statusline",
      "tags": ["statusline", "minimal", "unicode"]
    }
  ]
}
```

### `.claude-plugin/plugin.json`
```json
{
  "name": "claude-statusline",
  "version": "0.1.0",
  "description": "Minimal Unicode statusline for Claude Code",
  "author": {
    "name": "seokjw0727",
    "url": "https://github.com/seokjw0727"
  },
  "license": "MIT",
  "homepage": "https://github.com/seokjw0727/claude-statusline",
  "statusLine": {
    "type": "command",
    "command": "bash ${CLAUDE_PLUGIN_ROOT}/statusline-command.sh"
  }
}
```

`${CLAUDE_PLUGIN_ROOT}` is expected to expand to the plugin install directory at runtime, so the same manifest works regardless of where Claude Code installs the plugin on each user's machine.

**Verification required at implementation time:** the exact field names (`statusLine`, `${CLAUDE_PLUGIN_ROOT}`) and whether `statusLine` belongs in `plugin.json` or in a bundled `settings.json` must be re-confirmed against the current Claude Code plugin specification before publishing. This is the first task of the implementation plan.

## Script changes (`statusline-command.sh`)

Four targeted edits to remove environment coupling and switch to standard data sources. No structural rewrite.

### (a) Remove hardcoded winget jq PATH

```diff
-export PATH="/c/Users/seokj/AppData/Local/Microsoft/WinGet/Packages/jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe:$PATH"
```

### (b) Detect missing `jq` and surface a clear error

Inserted before the `input=$(cat)` line:

```bash
if ! command -v jq >/dev/null 2>&1; then
  printf '\033[31m■\033[0m \033[37m[jq missing — install: https://jqlang.org]\033[0m\n'
  exit 0
fi
```

`exit 0` — Claude Code may suppress statusline output on non-zero exit; we want the missing-jq notice to be visible.

### (c) Read effort from the statusline JSON input

```diff
-# effortLevel is not in statusline JSON — read from settings.json
-effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
+effort=$(echo "$input" | jq -r '.effort.level // empty')
```

`.effort.level` is a documented field in the statusline JSON input. It is the authoritative source — it reflects mid-session `/effort` changes and is automatically absent when the active model does not support effort. Reading the user's `settings.json` is removed entirely.

### (d) Remove dead code

The `fmt_ctx_size()` helper is never called and brings a `bc` dependency. Both are removed.

## What is preserved (intentionally)

- Effort case mapping for the four documented levels (`low` / `medium` / `high` / `xhigh`) plus an `*` catch-all for any future or unknown value (rendered with the `◈` glyph)
- Visual style: ANSI color codes, Unicode glyphs, segment composition, color thresholds (50% / 75% / 90%)
- Combined `■` segment for `ctx` / `5h` / `7d` separated by dimmed `·`
- Top-level segments separated by dimmed `│`

## README changes

Rewritten section structure:

1. Tagline + ASCII output example
2. **Install — Via Claude Code Plugin (recommended)** — two slash commands
3. **Install — Manual install (fallback)** — old `cp` + `settings.json` edit, kept for users who don't use the plugin system
4. **Segments** — existing table preserved
5. **Requirements** — `jq` (with OS-specific install one-liners: `winget install jqlang.jq` / `brew install jq` / `apt install jq`), Bash 4+, ANSI/Unicode terminal
6. **Migrating from manual install** — three steps: ① delete `~/.claude/statusline-command.sh` ② remove `statusLine` key from `~/.claude/settings.json` ③ run `/plugin install`
7. **Configuration (optional)** — note that effort is shown when the user runs `/effort` in their session (no settings.json edit needed); auto-hidden when the model doesn't support it
8. **Updating** — `/plugin marketplace update`
9. **License** — MIT

## Validation strategy (manual smoke test, no CI)

Per release, before tagging:

1. **Manifest spec re-check** — confirm `marketplace.json` / `plugin.json` field names against current official plugin docs.
2. **Local install test** — register the local repo as a marketplace (`/plugin marketplace add C:\Users\seokj\.claude\claude-statusline-repo`), install, confirm all six segments render.
3. **Live data check** — toggle `/effort low` ↔ `/effort high` and confirm the statusline updates; switch model and confirm the `model` segment updates.
4. **`jq` missing scenario** — temporarily mask `jq` from PATH and confirm the red `[jq missing]` notice appears.
5. **Migration guide accuracy** — leave the old manual install in place, install the plugin, observe the conflict; then follow the README migration steps and confirm only the plugin renders.
6. **Remote install** — push to GitHub, then in a fresh shell run `/plugin marketplace add seokjw0727/claude-statusline` and confirm install/render works without local clone.

Items not validated (accepted risk):
- macOS / Linux behavior — code written portably, validated only by Windows + Git Bash. User feedback covers the gap.
- Automated tests — out of scope for MVP.

## Backwards compatibility

The author's existing manual install will conflict with the plugin install (both define a statusline). Resolution is by README documentation only — no auto-detection, no auto-migration logic. The README migration section covers the three required cleanup steps.

## Release process

1. Implement changes → run manual smoke test (above) → all green
2. Update `CHANGELOG.md` (Keep a Changelog format)
3. Bump `version` field in both `marketplace.json` and `plugin.json`
4. Commit, then `git tag v<version>` and `git push --tags`
5. `gh release create v<version>` with notes from `CHANGELOG.md`
6. README mentions `/plugin marketplace update` so users can pull new versions

### `CHANGELOG.md` (initial)

```markdown
# Changelog

## [0.1.0] — 2026-04-26
### Added
- Plugin packaging (`.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`)
- Auto-install via `/plugin marketplace add seokjw0727/claude-statusline`
- `CHANGELOG.md` and standalone `LICENSE` file

### Changed
- Read effort from statusline JSON `.effort.level` instead of `~/.claude/settings.json`
- jq detection: clear in-statusline error if missing (was: silent empty output)
- README rewritten with plugin install as primary, manual install as fallback

### Removed
- Hardcoded winget jq PATH (line 4 of `statusline-command.sh`)
- Dead `fmt_ctx_size()` helper and the `bc` dependency it implied
```

## Open questions resolved during brainstorming

| # | Question | Decision |
|---|---|---|
| 1 | Scope | (A) MVP — packaging + portability fixes only |
| 2 | Marketplace topology | (A) Mono-marketplace inside the same repo |
| 3 | `jq` dependency handling | (A) Standard PATH + clear error if missing |
| 4 | `effort` data source | Read from statusline JSON `.effort.level` (chosen over the original A/B/C options after user requested portability across all users' environments) |
| 5 | Backwards compatibility | (A) README migration section only, no auto-detect |
| 6 | Marketplace name | `seokjw0727` |
