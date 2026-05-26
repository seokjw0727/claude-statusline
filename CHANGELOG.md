# Changelog

All notable changes to this project will be documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] — 2026-05-26

### Added
- Two-line layout — line 1: model · effort · directory · context; line 2: Claude and Codex rate limits, each grouped under a labelled segment
- Codex rate-limit display (5h / 7d) via the new `codex-limits.py` helper, parsed from the latest `~/.codex` session rollout. Requires `python`; the segment is hidden automatically when `python` or Codex session data is absent
- `ctx_bar` gained an optional width argument

### Changed
- All usage bars (ctx, Claude 5h/7d, Codex 5h/7d) render at a uniform 10-character width
- Rate-limit colour thresholds raised to yellow >= 66%, orange >= 83%, red >= 99%

## [0.1.0] — 2026-04-26

### Changed
- Read effort from statusline JSON `.effort.level` instead of `~/.claude/settings.json` — works for all users, reflects mid-session `/effort` changes
- Missing `jq` now produces a clear in-statusline notice instead of silent empty output
- README: OS-specific `jq` install commands; tightened install/requirements wording

### Added
- Standalone `LICENSE` file (MIT, extracted from README)
- This `CHANGELOG.md`

### Removed
- Hardcoded winget `jq` PATH from `statusline-command.sh` line 4 (broke on every other machine)
- Dead `fmt_ctx_size()` helper and its implied `bc` dependency
