# Changelog

All notable changes to the Copilot CLI backend will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0-untested] - 2026-01-21

### Added

- **CLI Flag Parity**: Added full CLI flag support matching Claude Code ralph-loop plugin:
  - `--max-iterations <n>`: Maximum iterations before auto-stop (was hardcoded)
  - `--completion-promise '<text>'`: Promise phrase that signals task completion
  - `--guardrails <file>`: File to inject into prompt each iteration
  - `--progress <file>`: File to log iteration progress
  - `--stuck-threshold <n>`: Warn after N iterations with no file changes

- **Progress Injection**: Last 50 lines of progress file now injected into prompt with Claude Code format:
  ```
  --- PROGRESS LOG (your work so far, last 50 lines) ---
  [content]
  --- END PROGRESS ---
  ```

- **Completion Promise Detection**: New `detect_promise()` function parses `<promise>` tags from Copilot output using perl regex for reliable multiline extraction.

- **Hash-Based Stuck Detection**: Replaced criterion-only stuck detection with git diff hash comparison (matches Claude Code behavior):
  - Computes `md5sum` of `git diff HEAD --stat`
  - Compares hash between iterations
  - More accurately detects "no progress" states

- **Guardrails Content Injection**: Guardrails file content now inlined in prompt (not just path reference):
  ```
  --- GUARDRAILS (read before proceeding) ---
  [content]
  --- END GUARDRAILS ---
  ```

- **Progress File Initialization**: Creates progress file with full Claude Code format including task name, timestamp, and iteration log structure.

- **Output Capture for Promise**: `run_copilot_with_retry()` now captures Copilot output via `tee` for promise detection while still showing real-time output.

### Changed

- **Version**: Bumped from 1.0.0-untested to 2.0.0-untested
- **Argument Parsing**: Switched from positional-only to full long-option parsing
- **Stuck Detection**: Now uses file hash comparison instead of criterion tracking
- **Progress Updates**: Now include git diff summary per iteration
- **Help Text**: Comprehensive help with examples matching Claude Code style

### Fixed

- Progress file path now configurable via `--progress` flag
- Guardrails file path now configurable via `--guardrails` flag
- Max iterations now configurable via `--max-iterations` flag
- Stuck threshold now configurable via `--stuck-threshold` flag

### Documentation

- Created `PARITY_ANALYSIS.md`: Comprehensive feature gap analysis between Claude Code and Copilot backends
- Created `RECOMMENDATIONS.md`: Research findings for complex gaps with solution options
- Created `CHANGELOG.md`: This file

## [1.0.0-untested] - 2026-01-17

### Added

- Initial Copilot CLI backend implementation
- Model selection via `RALPH_COPILOT_MODEL` environment variable
- Premium vs free tier model classification
- Basic iteration loop with TASK.md checkbox tracking
- Activity logging to task directory
- Premium request tracking for quota awareness
- CLI detection for both `copilot` and deprecated `gh copilot`
- Retry logic with exponential backoff
- Basic stuck detection via criterion repetition

### Known Limitations

- UNTESTED: Requires active GitHub Copilot license
- ACP mode placeholder only
- No completion promise support
- Hardcoded max iterations
- No progress injection into prompt

---

## Feature Parity Status

| Feature | v1.0.0 | v2.0.0 |
|---------|--------|--------|
| CLI flags | Env vars only | Full parity |
| Progress injection | No | Yes |
| Promise detection | No | Yes |
| Hash stuck detection | No | Yes |
| Guardrails injection | Path only | Content |
| Progress init format | Minimal | Full |
| Iteration git summary | No | Yes |

---

## Migration Guide

### From v1.0.0 to v2.0.0

**No breaking changes**. All v1.0.0 usage patterns still work.

New features are opt-in via CLI flags:

```bash
# v1.0.0 style (still works)
./ralph-copilot.sh my-task

# v2.0.0 style (new features)
./ralph-copilot.sh my-task \
  --max-iterations 25 \
  --completion-promise 'TASK COMPLETE' \
  --guardrails .ralph/guardrails.md \
  --progress progress.md \
  --stuck-threshold 5
```

### Environment Variables

Environment variables continue to work for model selection:

```bash
RALPH_COPILOT_MODEL=claude-sonnet ./ralph-copilot.sh my-task
```
