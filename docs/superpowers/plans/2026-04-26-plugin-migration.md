# Plugin Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert `claude-statusline` from a manual-install bash script into a Claude Code marketplace plugin (v0.1.0), removing environment dependencies that prevent it from working on other users' machines.

**Architecture:** Mono-marketplace inside the existing repo. Add `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json` manifests. Edit `statusline-command.sh` to remove the hardcoded jq PATH, add a missing-jq error path, and switch the effort source to the standard statusline JSON `.effort.level` field. Rewrite README with plugin install primary, manual install as fallback. Manual smoke test only (no CI). Tag `v0.1.0` and publish a GitHub release.

**Tech Stack:** Bash, jq, Claude Code plugin system, GitHub (gh CLI).

**Prerequisites for the implementer:**
- Working directory: `C:\Users\seokj\.claude\claude-statusline-repo`
- Git Bash on Windows (Unix shell syntax)
- `jq` installed and on PATH
- `gh` CLI authenticated as `seokjw0727`
- The current branch is `main` and is up to date with `origin/main`. Each task commits directly to `main`. (This is a personal repo with one author; PR workflow is overhead.)

**Reference:** The approved spec is at `docs/superpowers/specs/2026-04-26-plugin-migration-design.md`. If anything in this plan conflicts with that spec, the spec wins — stop and reconcile before proceeding.

---

## Task 0: Verify plugin manifest specification

**Why:** The spec records `statusLine` and `${CLAUDE_PLUGIN_ROOT}` based on prior research. These need to be re-confirmed against current Claude Code plugin documentation before we commit manifests that won't work.

**Files:** None modified unless discrepancies are found.

- [ ] **Step 1: Query the canonical plugin spec**

Dispatch the `claude-code-guide` subagent with this prompt (verbatim):

> Confirm the exact, current Claude Code plugin manifest format. I need to verify three specific things before publishing a plugin:
>
> 1. **`marketplace.json` schema** — exact required and optional top-level fields, exact shape of the `plugins[]` array entries (especially `name`, `source`, `version`, `description`, `category`, `tags`).
>
> 2. **`plugin.json` schema** — does a plugin define a statusline directly in `plugin.json` (e.g. via a top-level `statusLine` object: `{"type": "command", "command": "..."}`)? Or must the statusline be declared in a bundled `settings.json` that the plugin ships? Show me the canonical example.
>
> 3. **Plugin root variable** — when a plugin command needs to reference its own install directory, what is the exact variable name? (`${CLAUDE_PLUGIN_ROOT}`? `${PLUGIN_ROOT}`? Something else?) Show one canonical example from the docs.
>
> Return the answer as: (a) confirmed/different for each item, (b) the canonical field names and example snippets to use, (c) a link to the doc page.

- [ ] **Step 2: Reconcile findings with the spec**

If all three are confirmed as already documented in the spec, proceed to Task 1 with no changes.

If any field name or structure differs, edit `docs/superpowers/specs/2026-04-26-plugin-migration-design.md` to update the affected manifest examples (search the spec for `marketplace.json`, `plugin.json`, `statusLine`, `${CLAUDE_PLUGIN_ROOT}` and update each occurrence to match the canonical form).

- [ ] **Step 3: Commit (only if spec was updated)**

```bash
git -C /c/Users/seokj/.claude/claude-statusline-repo add docs/superpowers/specs/2026-04-26-plugin-migration-design.md
git -C /c/Users/seokj/.claude/claude-statusline-repo commit -m "Reconcile plugin manifest spec with canonical Claude Code plugin format

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

If no changes were needed, skip this step.

---

## Task 1: Edit `statusline-command.sh` (remove env coupling, switch effort source, drop dead code)

**Files:**
- Modify: `statusline-command.sh` (4 targeted edits)

- [ ] **Step 1: Remove the hardcoded winget jq PATH (line 4)**

Use Edit with:
- `old_string`:
  ```
  export PATH="/c/Users/seokj/AppData/Local/Microsoft/WinGet/Packages/jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe:$PATH"

  input=$(cat)
  ```
- `new_string`:
  ```
  if ! command -v jq >/dev/null 2>&1; then
    printf '\033[31m■\033[0m \033[37m[jq missing — install: https://jqlang.org]\033[0m\n'
    exit 0
  fi

  input=$(cat)
  ```

This both removes the hardcoded PATH and adds the missing-jq guard in one edit.

- [ ] **Step 2: Switch effort source to statusline JSON `.effort.level`**

Use Edit with:
- `old_string`:
  ```
  # effortLevel is not in statusline JSON — read from settings.json
  effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
  ```
- `new_string`:
  ```
  effort=$(echo "$input" | jq -r '.effort.level // empty')
  ```

- [ ] **Step 3: Remove the dead `fmt_ctx_size` helper (and its `bc` dependency)**

Use Edit with:
- `old_string`:
  ```
  # Format context window size as human-readable label (e.g. 200000 → "200K", 1000000 → "1M")
  fmt_ctx_size() {
    local n="$1"
    if [ -z "$n" ] || [ "$n" = "null" ]; then echo ""; return; fi
    local int_n
    int_n=$(printf '%.0f' "$n" 2>/dev/null || echo 0)
    if   (( int_n >= 1000000 )); then printf '%sM' "$(echo "scale=0; $int_n / 1000000" | bc)"
    elif (( int_n >= 1000 ));    then printf '%sK' "$(echo "scale=0; $int_n / 1000"    | bc)"
    else echo "$int_n"
    fi
  }

  # ── context bar helper (10-char wide) ──────────────────────────
  ```
- `new_string`:
  ```
  # ── context bar helper (10-char wide) ──────────────────────────
  ```

- [ ] **Step 4: Smoke test the script with sample input**

Run from Git Bash:

```bash
cd /c/Users/seokj/.claude/claude-statusline-repo
echo '{"model":{"display_name":"Opus 4.7"},"cwd":"/c/Users/seokj/test","context_window":{"remaining_percentage":60},"rate_limits":{"five_hour":{"used_percentage":20},"seven_day":{"used_percentage":70}},"effort":{"level":"high"}}' | bash statusline-command.sh
```

Expected: a single line containing `◆  Opus 4.7 ( High ◉ )  │  ▶  seokj/test  │  ■  ctx ████░░░░░░ 40%  ·  5h ██░░░░░░░░ 20%  ·  7d ███████░░░ 70%` (with ANSI colors). If the line is empty or contains errors, stop and debug.

- [ ] **Step 5: Smoke test the missing-jq error path**

Run from Git Bash with a deliberately broken PATH:

```bash
cd /c/Users/seokj/.claude/claude-statusline-repo
PATH="/usr/bin:/bin" bash statusline-command.sh < /dev/null
```

(`/usr/bin:/bin` typically does not contain `jq` on Windows Git Bash. If this PATH happens to include `jq` on your machine, replace it with an empty PATH that genuinely lacks `jq`.)

Expected: a single line `■ [jq missing — install: https://jqlang.org]` with red ■ and white text. Exit code 0 (run `echo $?`).

- [ ] **Step 6: Commit**

```bash
git -C /c/Users/seokj/.claude/claude-statusline-repo add statusline-command.sh
git -C /c/Users/seokj/.claude/claude-statusline-repo commit -m "Make statusline portable: drop hardcoded jq PATH, read effort from input

- Remove hardcoded winget jq PATH (broke on every other machine)
- Add missing-jq guard with red in-statusline notice
- Read effort from statusline JSON .effort.level instead of ~/.claude/settings.json
- Remove dead fmt_ctx_size helper and bc dependency

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Add `LICENSE` and `CHANGELOG.md`

**Files:**
- Create: `LICENSE`
- Create: `CHANGELOG.md`
- Modify: `README.md` (remove `## License` section, since it now lives in `LICENSE`)

- [ ] **Step 1: Create `LICENSE`**

Write `C:\Users\seokj\.claude\claude-statusline-repo\LICENSE` with this exact content:

```
MIT License

Copyright (c) 2026 seokjw0727

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2: Create `CHANGELOG.md`**

Write `C:\Users\seokj\.claude\claude-statusline-repo\CHANGELOG.md` with this exact content:

```markdown
# Changelog

All notable changes to this project will be documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0] — 2026-04-26

### Added
- Plugin packaging: `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json`
- Install via `/plugin marketplace add seokjw0727/claude-statusline` then `/plugin install claude-statusline@seokjw0727`
- Standalone `LICENSE` file (MIT) and this `CHANGELOG.md`
- README "Migrating from manual install" section

### Changed
- Read effort from statusline JSON `.effort.level` instead of `~/.claude/settings.json` — works for all users, reflects mid-session `/effort` changes
- Missing `jq` now produces a clear in-statusline notice instead of silent empty output
- README rewritten with plugin install as the recommended path; manual install kept as a fallback

### Removed
- Hardcoded winget `jq` PATH from `statusline-command.sh` line 4 (broke on every other machine)
- Dead `fmt_ctx_size()` helper and its implied `bc` dependency
```

- [ ] **Step 3: Remove the `## License` section from `README.md`**

Use Edit on `README.md`:
- `old_string`:
  ```
  ## License

  MIT
  ```
- `new_string`: (empty string — delete the section entirely; the LICENSE file replaces it)

If the README has no trailing newline issue after the edit, leave it. Task 5 will rewrite the README anyway, so trailing-whitespace cleanup is unnecessary here.

- [ ] **Step 4: Commit**

```bash
git -C /c/Users/seokj/.claude/claude-statusline-repo add LICENSE CHANGELOG.md README.md
git -C /c/Users/seokj/.claude/claude-statusline-repo commit -m "Add LICENSE and CHANGELOG; move License out of README

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Create `.claude-plugin/plugin.json`

**Files:**
- Create: `.claude-plugin/plugin.json`

If Task 0 found discrepancies, the field names below may need adjustment — use the canonical form from the updated spec.

- [ ] **Step 1: Create the directory**

```bash
mkdir -p /c/Users/seokj/.claude/claude-statusline-repo/.claude-plugin
```

- [ ] **Step 2: Write `plugin.json`**

Write `C:\Users\seokj\.claude\claude-statusline-repo\.claude-plugin\plugin.json` with this exact content (adjust per Task 0 reconciliation if needed):

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

- [ ] **Step 3: Validate JSON syntax**

```bash
jq . /c/Users/seokj/.claude/claude-statusline-repo/.claude-plugin/plugin.json
```

Expected: pretty-printed JSON, no errors. If `jq` reports a parse error, fix the file before continuing.

- [ ] **Step 4: Commit**

```bash
git -C /c/Users/seokj/.claude/claude-statusline-repo add .claude-plugin/plugin.json
git -C /c/Users/seokj/.claude/claude-statusline-repo commit -m "Add plugin.json manifest

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Create `.claude-plugin/marketplace.json`

**Files:**
- Create: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Write `marketplace.json`**

Write `C:\Users\seokj\.claude\claude-statusline-repo\.claude-plugin\marketplace.json` with this exact content (adjust per Task 0 reconciliation if needed):

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

- [ ] **Step 2: Validate JSON syntax**

```bash
jq . /c/Users/seokj/.claude/claude-statusline-repo/.claude-plugin/marketplace.json
```

Expected: pretty-printed JSON, no errors.

- [ ] **Step 3: Commit**

```bash
git -C /c/Users/seokj/.claude/claude-statusline-repo add .claude-plugin/marketplace.json
git -C /c/Users/seokj/.claude/claude-statusline-repo commit -m "Add marketplace.json with single claude-statusline plugin entry

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Rewrite `README.md`

**Files:**
- Modify (full rewrite): `README.md`

- [ ] **Step 1: Replace `README.md` with the new structure**

Write `C:\Users\seokj\.claude\claude-statusline-repo\README.md` with this exact content:

````markdown
# claude-statusline

Minimal Unicode statusline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

```
◆  Opus 4.7 ( High ◉ )  │  ▶  projects/my-app  │  ■  ctx ████░░░░░░ 40%  ·  5h ██░░░░░░░░ 20%  ·  7d ███████░░░ 70%
```

## Install

### Via Claude Code Plugin (recommended)

```
/plugin marketplace add seokjw0727/claude-statusline
/plugin install claude-statusline@seokjw0727
```

To pull future updates:

```
/plugin marketplace update
```

### Manual install (fallback)

If you prefer not to use the plugin system:

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

## Migrating from manual install

If you previously installed this script manually and are switching to the plugin, the two installs will collide (both define a statusline). Clean up the manual install first:

1. Delete `~/.claude/statusline-command.sh`
2. Remove the `"statusLine"` key from `~/.claude/settings.json`
3. Run `/plugin install claude-statusline@seokjw0727`

## License

See [LICENSE](LICENSE).
````

- [ ] **Step 2: Commit**

```bash
git -C /c/Users/seokj/.claude/claude-statusline-repo add README.md
git -C /c/Users/seokj/.claude/claude-statusline-repo commit -m "Rewrite README: plugin install primary, manual install as fallback

- Add plugin install commands as the recommended path
- Keep manual install as a fallback section
- Add OS-specific jq install commands
- Add 'Migrating from manual install' section
- Document /effort as the way to set effort (no settings.json edit)
- Replace inline License section with link to LICENSE file

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Local install smoke test

**Files:** None modified. This task is verification only — no commits.

Goal: confirm the plugin actually installs and renders correctly on the author's machine before pushing to GitHub.

- [ ] **Step 1: Register the local repo as a marketplace in Claude Code**

In an interactive Claude Code session, run:

```
/plugin marketplace add C:\Users\seokj\.claude\claude-statusline-repo
```

Expected: confirmation that marketplace `seokjw0727` was added.

- [ ] **Step 2: Install the plugin**

```
/plugin install claude-statusline@seokjw0727
```

Expected: confirmation that `claude-statusline` was installed and the statusline reloaded.

- [ ] **Step 3: Visually verify all segments render**

Look at the statusline at the bottom of the Claude Code window. Confirm you see (in order, separated by dim `│`):
- `◆  <model name>  ( <effort label> <effort glyph> )`
- `▶  <last-two-cwd-components>`
- `■  ctx <bar> <pct>%  ·  5h <bar> <pct>%  ·  7d <bar> <pct>%`

If anything is missing or garbled, stop and diagnose. Most likely culprit: `${CLAUDE_PLUGIN_ROOT}` not expanding (if so, return to Task 0).

- [ ] **Step 4: Toggle effort and confirm live update**

```
/effort low
```

Statusline should update within seconds to show `( Low ○ )`.

```
/effort high
```

Statusline should update to `( High ◉ )`.

- [ ] **Step 5: Verify missing-jq behavior in plugin context**

Skip if step 3 confirms jq is on PATH for the plugin runtime. To force-test: temporarily rename the `jq` binary, observe the red `■ [jq missing — install: https://jqlang.org]` notice in the statusline, then restore the binary.

If steps 1–4 pass, this verification is complete. No commit.

---

## Task 7: Migration guide accuracy test

**Files:** None modified. Verification only.

Goal: confirm the README's "Migrating from manual install" steps actually work on the author's environment, since the author currently has both manual and (post-Task-6) plugin installs.

- [ ] **Step 1: Reproduce the conflict scenario**

Confirm the following are present simultaneously:
- `~/.claude/statusline-command.sh` (the manual install file)
- `~/.claude/settings.json` containing a `statusLine` key
- The plugin installed (from Task 6)

Observe the statusline. Note which of the two installs wins (this is informational — record it for the user, but the README does not need to predict it).

- [ ] **Step 2: Follow the README migration steps**

Execute the three migration steps from `README.md`:

```bash
rm ~/.claude/statusline-command.sh
```

Then edit `~/.claude/settings.json` and remove the statusline key. The author's existing settings.json may use either `statusLine` (camelCase, current Claude Code spec) or `statusline` (lowercase, the form used in the old manual-install README). Delete both with `jq` to be safe:

```bash
jq 'del(.statusLine, .statusline)' ~/.claude/settings.json > ~/.claude/settings.json.tmp && mv ~/.claude/settings.json.tmp ~/.claude/settings.json
```

The third step (`/plugin install`) is already done from Task 6 — no need to re-run.

- [ ] **Step 3: Verify only the plugin renders**

Confirm the statusline still renders correctly after the cleanup. If it doesn't, the README migration steps are incomplete — return to Task 5 and fix.

No commit.

---

## Task 8: Push to GitHub and verify remote install

**Files:** None modified. Pushes existing commits.

- [ ] **Step 1: Push all local commits**

```bash
git -C /c/Users/seokj/.claude/claude-statusline-repo push origin main
```

Expected: all commits from Tasks 1–5 land on `origin/main`.

- [ ] **Step 2: Remove the local-marketplace registration to avoid masking the remote test**

In Claude Code:

```
/plugin uninstall claude-statusline@seokjw0727
/plugin marketplace remove seokjw0727
```

(If the exact command names differ, use whatever Claude Code documents for "remove a marketplace registration".)

- [ ] **Step 3: Add the marketplace from GitHub and install**

```
/plugin marketplace add seokjw0727/claude-statusline
/plugin install claude-statusline@seokjw0727
```

Expected: install succeeds without referencing the local clone path.

- [ ] **Step 4: Re-verify the statusline renders**

Look at the statusline at the bottom of the Claude Code window. Confirm you see (in order, separated by dim `│`):
- `◆  <model name>  ( <effort label> <effort glyph> )`
- `▶  <last-two-cwd-components>`
- `■  ctx <bar> <pct>%  ·  5h <bar> <pct>%  ·  7d <bar> <pct>%`

If everything renders, the remote distribution path works. No commit.

---

## Task 9: Tag `v0.1.0` and publish a GitHub release

**Files:** None modified. Tags and releases the existing commits.

- [ ] **Step 1: Confirm working tree is clean and on main**

```bash
git -C /c/Users/seokj/.claude/claude-statusline-repo status
```

Expected: `working tree clean` and `On branch main`. If not, stop.

- [ ] **Step 2: Tag the release**

```bash
git -C /c/Users/seokj/.claude/claude-statusline-repo tag -a v0.1.0 -m "v0.1.0 — first plugin release"
git -C /c/Users/seokj/.claude/claude-statusline-repo push origin v0.1.0
```

- [ ] **Step 3: Create the GitHub release with notes from CHANGELOG**

```bash
gh release create v0.1.0 \
  --repo seokjw0727/claude-statusline \
  --title "v0.1.0 — Plugin release" \
  --notes "First release as a Claude Code plugin.

Install:

\`\`\`
/plugin marketplace add seokjw0727/claude-statusline
/plugin install claude-statusline@seokjw0727
\`\`\`

See [CHANGELOG.md](https://github.com/seokjw0727/claude-statusline/blob/v0.1.0/CHANGELOG.md) for the full list of changes."
```

Expected: `gh` returns a release URL. Open it in a browser to confirm the page renders correctly.

- [ ] **Step 4: Final smoke check from a clean install**

If possible (e.g. on a different machine or in a different Claude Code workspace), verify that `/plugin marketplace add seokjw0727/claude-statusline` from a brand-new state pulls v0.1.0 and the statusline works. Skip if no second environment is available.

---

## After all tasks

The plugin is published. Future improvement ideas (deferred per spec — do **not** add them in this release):
- Per-segment toggles (env var or plugin config)
- Theme system
- Modular per-segment files
- Automated tests / CI
- macOS / Linux smoke tests

Open issues for any of these only if a real user requests them.
