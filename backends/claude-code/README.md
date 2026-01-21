# Claude Code Backend

Uses the official `ralph-loop` plugin for Claude Code with enhanced features.

## When to Use This Backend

**Best for:**
- Personal development with Claude Code CLI
- Tasks requiring deep codebase understanding
- Environments where you control the tooling

**Not ideal for:**
- Corporate environments without Claude Code access
- Teams standardized on other AI tooling

## Installation

The ralph-loop plugin is part of the official Claude Code plugins. Install via:

```bash
# In Claude Code, plugins are auto-discovered from the marketplace
# Or install from fork with enhanced features:
claude plugins add github:mydogsburneraccount/claude-plugins-official/plugins/ralph-loop
```

### Enhanced Fork (Recommended)

For the latest features (progress tracking, stuck detection), use the enhanced fork:

**Repository:** https://github.com/mydogsburneraccount/claude-plugins-official
**Branch:** `ralph-loop/progress-and-fixes`

Features in enhanced fork:
- `--guardrails <file>` - Inject rules into system message each iteration
- `--progress <file>` - Log iteration history, inject into context
- `--stuck-threshold <n>` - Warn after N iterations with no file changes
- Activity logging to `.claude/ralph-activity.log`
- Proper YAML escaping for special characters

## Usage

```bash
# Basic usage
/ralph-loop "Build a REST API for todos" --max-iterations 20

# With completion promise (stops when TRUE)
/ralph-loop "Fix auth bug" --completion-promise "All tests passing" --max-iterations 30

# Full featured (recommended for Ralph tasks)
/ralph-loop "Build feature X" \
  --max-iterations 25 \
  --completion-promise "TASK COMPLETE" \
  --guardrails .ralph/guardrails.md \
  --progress .ralph/active/my-task/progress.md \
  --stuck-threshold 5
```

## How It Works

Unlike external script backends (copilot, aider), the Claude Code backend uses **stop hooks**:

1. `/ralph-loop` creates state file and activates stop hook
2. When Claude tries to exit, the hook intercepts
3. Hook re-injects the original prompt with iteration metadata
4. Claude sees its previous work in files/git, enabling self-reference
5. Loop continues until completion promise is TRUE or max iterations reached

This creates a true autonomous loop where Claude iterates on the same task with full context of previous attempts.

## Integration with Ralph Methodology

### Guardrails (Signs)

Point `--guardrails` at your project's guardrails file:

```bash
/ralph-loop "..." --guardrails .ralph/guardrails.md
```

The guardrails content is injected into every iteration's system message.

### Progress Tracking

Use `--progress` to maintain cross-iteration awareness:

```bash
/ralph-loop "..." --progress .ralph/active/my-task/progress.md
```

The progress file:
- Logs each iteration with timestamp and git diff summary
- Gets injected into system message (last 50 lines)
- Survives session crashes for recovery

### Stuck Detection

Prevent infinite loops with `--stuck-threshold`:

```bash
/ralph-loop "..." --stuck-threshold 5
```

After 5 iterations with no file changes, Claude receives:
```
⚠️ STUCK WARNING: No file changes detected for 5 iterations.
Consider trying a different approach.
```

## Comparison with Other Backends

| Feature | Claude Code | Copilot CLI | Aider |
|---------|-------------|-------------|-------|
| Loop mechanism | Stop hooks (internal) | External script | External script |
| Context awareness | Full (same session) | Limited (prompt injection) | Good (repo map) |
| Guardrails injection | Native | Manual | Manual |
| Progress tracking | Native | Script-based | Script-based |
| Stuck detection | Native | Script-based | Script-based |
| Corporate approved | Varies | Yes (GitHub) | No (personal API) |

## Files

This backend is implemented as a Claude Code plugin, not local scripts.

| Component | Location |
|-----------|----------|
| Plugin source | [mydogsburneraccount/claude-plugins-official](https://github.com/mydogsburneraccount/claude-plugins-official/tree/ralph-loop/progress-and-fixes/plugins/ralph-loop) |
| Setup script | `plugins/ralph-loop/scripts/setup-ralph-loop.sh` |
| Stop hook | `plugins/ralph-loop/hooks/stop-hook.sh` |
| State file | `.claude/ralph-loop.local.md` (created per-session) |
| Activity log | `.claude/ralph-activity.log` |

## Troubleshooting

### Loop won't stop
- Set `--max-iterations` as a safety limit
- Use `--completion-promise` with a verifiable statement
- Kill Claude Code process if needed (loop state cleared on restart)

### Progress not updating
- Ensure `--progress` path is writable
- Check `.claude/ralph-activity.log` for errors

### Guardrails not appearing
- Verify file exists at specified path
- Check file is readable (not empty)

## Version History

- **2026-01-21**: Added `--progress`, `--stuck-threshold`, bug fixes (M1, M3)
- **2026-01-20**: Added `--guardrails`, activity logging
- **2026-01-19**: Initial ralph-loop plugin in claude-plugins-official
