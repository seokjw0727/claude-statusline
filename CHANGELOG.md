# Changelog

All notable changes to this project will be documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/).

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
