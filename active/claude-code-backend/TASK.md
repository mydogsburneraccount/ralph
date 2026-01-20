---
dependencies:
  system: []
  python: []
  npm: []
  check_commands:
    - test -d .ralph/core  # Verify Ralph core exists
    - test -f .ralph/guardrails.md  # Verify guardrails exists
---

# Task: Native Claude Code Backend for Ralph

## Task Overview

**Goal**: Create a native Claude Code backend for Ralph that enables skill-based iteration without external CLI dependencies.

**Context**: Ralph currently has cursor-agent (deprecated) and copilot-cli (requires license) backends. Users with Claude Code have no optimized backend. Unlike other backends that wrap external tools, Claude Code IS the executing agent and can directly read/write files, track context usage, and execute bash commands.

**Success Indicator**: `/ralph continue` command executes a single iteration, updates state files, and commits changes with proper Ralph format.

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

#### Task Creator Responsibilities (completed before creating this task)

- [x] Read `.cursorrules` completely: Anti-Gaming Rules quoted in progress.md
- [x] Read `RALPH_RULES.md`: Verification Test quoted in progress.md
- [x] Read `ANTIPATTERNS.md`: Golden Rule quoted in progress.md
- [x] Read reference implementations: Patterns extracted in progress.md
- [x] Query Local RAG for context: Context-hygiene workflow found
- [x] Identify secrets/credentials needed: NONE - local file operations only
- [x] List files to be created: 3 files with justification in progress.md
- [x] State verification plan: Command verification for each file

#### Ralph Worker Responsibilities (during execution)

- [ ] Review creator's discovery evidence in progress.md: `grep -q "Task Creator Discovery" .ralph/active/claude-code-backend/progress.md`
- [ ] Verify Ralph core structure exists: `test -d .ralph/core/docs && echo "PASS"`
- [ ] Verify guardrails.md exists: `test -f .ralph/guardrails.md && echo "PASS"`
- [ ] Add corrections to progress.md if needed (note if none needed)

---

### Phase 1: Core Infrastructure

**Location**: `.ralph/backends/claude-code/`

- [ ] Create backend directory: `test -d .ralph/backends/claude-code && echo "PASS"`
- [ ] Create README.md with backend overview: `test -f .ralph/backends/claude-code/README.md && echo "PASS"`
- [ ] README contains purpose section: `grep -q "## Purpose" .ralph/backends/claude-code/README.md`
- [ ] README contains usage section: `grep -q "## Usage" .ralph/backends/claude-code/README.md`
- [ ] Create DESIGN.md with architecture decisions: `test -f .ralph/backends/claude-code/DESIGN.md && echo "PASS"`
- [ ] DESIGN.md documents context rotation: `grep -q "context rotation" .ralph/backends/claude-code/DESIGN.md`
- [ ] DESIGN.md documents state persistence: `grep -q "state persistence" .ralph/backends/claude-code/DESIGN.md`

---

### Phase 2: Skill Definition

**Location**: `.ralph/backends/claude-code/ralph-claude-skill.md`

- [ ] Create skill file: `test -f .ralph/backends/claude-code/ralph-claude-skill.md && echo "PASS"`
- [ ] Skill contains iteration loop logic: `grep -q "iteration" .ralph/backends/claude-code/ralph-claude-skill.md`
- [ ] Skill contains guardrails reading instruction: `grep -q "guardrails" .ralph/backends/claude-code/ralph-claude-skill.md`
- [ ] Skill contains completion detection: `grep -q "COMPLETE" .ralph/backends/claude-code/ralph-claude-skill.md`
- [ ] Skill contains Sign prompting: `grep -q "Sign" .ralph/backends/claude-code/ralph-claude-skill.md`
- [ ] Skill defines subcommands (start, continue, status): `grep -E "start|continue|status" .ralph/backends/claude-code/ralph-claude-skill.md`

---

### Phase 3: State Management

**State files spec in skill definition**

- [ ] Skill documents .iteration file: `grep -q "\.iteration" .ralph/backends/claude-code/ralph-claude-skill.md`
- [ ] Skill documents progress.md updates: `grep -q "progress.md" .ralph/backends/claude-code/ralph-claude-skill.md`
- [ ] Skill documents activity.log: `grep -q "activity.log" .ralph/backends/claude-code/ralph-claude-skill.md`
- [ ] Skill documents commit format: `grep -q 'ralph(' .ralph/backends/claude-code/ralph-claude-skill.md`

---

### Phase 4: Guardrails Integration

**Sign system integration**

- [ ] Skill instructs reading guardrails FIRST: `grep -qE "FIRST|first|before" .ralph/backends/claude-code/ralph-claude-skill.md | head -5`
- [ ] Skill includes Sign creation format: `grep -q "Trigger" .ralph/backends/claude-code/ralph-claude-skill.md`
- [ ] Skill documents failure handling: `grep -qE "fail|error|failure" .ralph/backends/claude-code/ralph-claude-skill.md`

---

### Phase 5: Stuck Detection

**Threshold-based stuck detection**

- [ ] Skill documents stuck threshold: `grep -qE "stuck|STUCK" .ralph/backends/claude-code/ralph-claude-skill.md`
- [ ] Skill mentions criterion tracking: `grep -qE "same criterion|last_criterion" .ralph/backends/claude-code/ralph-claude-skill.md`
- [ ] Skill includes GUTTER signal: `grep -q "GUTTER" .ralph/backends/claude-code/ralph-claude-skill.md`

---

### Phase 6: Documentation and Integration

**Update existing docs**

- [ ] Update .ralph/backends/README.md with claude-code entry: `grep -q "claude-code" .ralph/backends/README.md`
- [ ] Backend README lists all three backends: `grep -cE "cursor-agent|copilot-cli|claude-code" .ralph/backends/README.md | grep -q "3"`
- [ ] QUICKREF.md updated if exists: `test -f .ralph/core/docs/QUICKREF.md && grep -q "claude-code" .ralph/core/docs/QUICKREF.md || echo "SKIP - no QUICKREF"`

---

## Rollback Plan

If this task causes issues:

```bash
# Remove the new backend directory
rm -rf .ralph/backends/claude-code/

# Revert changes to existing files
git checkout HEAD -- .ralph/backends/README.md
git checkout HEAD -- .ralph/core/docs/QUICKREF.md 2>/dev/null || true

# Verify rollback
test ! -d .ralph/backends/claude-code && echo "Rollback successful"
```

---

## Manual Steps Required

**NONE** - This task only creates local files. No secrets, no external services, no GUI.

---

## Notes

- This backend is skill-driven, not fully autonomous like cursor-agent
- User controls iteration pace by invoking `/ralph continue`
- Context rotation is user-initiated (clear conversation + resume)
- State persists in files, survives conversation clears
- No external CLI dependencies (unlike cursor-agent which needs Cursor IDE)

---

## Context for Future Agents

This task creates the foundation for using Claude Code as a Ralph backend. The key insight is that Claude Code IS the executor (unlike cursor-agent which spawns external processes), so the design uses:

1. **File-based state** - .iteration, progress.md, activity.log survive context rotation
2. **User-controlled iteration** - Each `/ralph continue` is one iteration
3. **Skill-based prompting** - The skill file contains all the iteration logic

Key thresholds from reference implementations:
- MAX_ITERATIONS: 20
- STUCK_THRESHOLD: 3 (same criterion attempted 3+ times)
- WARN_THRESHOLD: 70000 tokens (suggest rotation)

Work incrementally through phases. Test each phase before moving to next.

---

## Completion Status

<promise>INCOMPLETE</promise>
