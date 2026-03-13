---
dependencies:
  system:
    # None required - bash scripting only
  python:
    # None required
  npm:
    # None required
  check_commands:
    - test -f .ralph/backends/copilot-cli/ralph-copilot.sh  # Target file exists
    - test -f .ralph/backends/cursor-agent/ralph-autonomous.sh  # Reference file exists
---

# Task: Implement Ralph-Copilot Backend Improvements

## Task Overview

**Goal**: Fix three critical gaps identified in the Ralph-loop compatibility audit to bring copilot-cli backend closer to feature parity with cursor-agent.

**Context**: The copilot-cli backend was audited against the canonical cursor-agent implementation. Three fixes are needed: promise marker support, auto-branching safety, and separate error logging.

**Success Indicator**: All verification commands pass; modified script maintains existing functionality.

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

#### Task Creator Responsibilities (completed)

- [x] Read `.cursorrules` completely: Anti-Gaming Rules noted
- [x] Read `CLAUDE.md`: Verification requirements noted
- [x] Read `.ralph/core/docs/RALPH_RULES.md`: Promise marker format documented
- [x] Query Local RAG for task topic: N/A (new audit-based work)
- [x] Identify secrets/credentials needed: None required
- [x] List files to be modified: 1 file (ralph-copilot.sh)
- [x] State verification plan: grep-based verification for each fix

#### Ralph Worker Responsibilities (during execution)

- [ ] Review creator's discovery evidence in progress.md
- [ ] Verify target file exists: `test -f .ralph/backends/copilot-cli/ralph-copilot.sh`
- [ ] Read current completion check logic (around lines 477-487)
- [ ] Read reference implementation patterns from ralph-autonomous.sh
- [ ] Proceed to Phase 1 only after verification complete

---

### Phase 1: Promise Marker Support

**Location**: `.ralph/backends/copilot-cli/ralph-copilot.sh` completion check section

**Reference**: `.ralph/backends/cursor-agent/ralph-autonomous.sh` lines 852-884

- [ ] Add `PROMISE_COMPLETE` variable that greps for `<promise>COMPLETE</promise>` in TASK_FILE
- [ ] Add `TASK_COMPLETE` boolean variable (initially false)
- [ ] Add `COMPLETION_METHOD` string variable to track how completion was detected
- [ ] Update completion logic: set TASK_COMPLETE=true if promise marker found OR all checkboxes checked
- [ ] Update completion message to show which method triggered success
- [ ] Verify: `grep -c "promise>COMPLETE" .ralph/backends/copilot-cli/ralph-copilot.sh` returns 1 or more

---

### Phase 2: Auto-Branching Safety

**Location**: `.ralph/backends/copilot-cli/ralph-copilot.sh` after auth checks, before main loop

**Reference**: `.ralph/backends/cursor-agent/ralph-autonomous.sh` lines 99-125

- [ ] Create `setup_safety_branch()` function that:
  - Gets current branch via `git branch --show-current`
  - If on `main` or `master`: creates `ralph-${TASK_NAME}-$(date +%Y%m%d)` branch
  - If already on `ralph-*` branch: continues on it
  - If on other branch: continues without creating new branch
  - Logs branch creation to ACTIVITY_LOG
- [ ] Add `RALPH_BRANCH` variable to track working branch
- [ ] Call `setup_safety_branch` after `check_github_auth` (around line 223)
- [ ] Verify: `grep -c "setup_safety_branch" .ralph/backends/copilot-cli/ralph-copilot.sh` returns 1 or more

---

### Phase 3: Separate Error Logging

**Location**: `.ralph/backends/copilot-cli/ralph-copilot.sh` file initialization and failure handling

**Reference**: `.ralph/backends/cursor-agent/ralph-autonomous.sh` uses separate errors.log

- [ ] Add `ERRORS_LOG="$TASK_DIR/errors.log"` variable after ACTIVITY_LOG definition
- [ ] Add initialization: create errors.log with header if not exists
- [ ] Create `log_error()` function that writes to BOTH errors.log and activity.log with timestamp
- [ ] Update iteration failure handling (around line 460) to use `log_error` instead of direct echo
- [ ] Verify: `grep -c "ERRORS_LOG" .ralph/backends/copilot-cli/ralph-copilot.sh` returns 1 or more
- [ ] Verify: `grep -c "log_error" .ralph/backends/copilot-cli/ralph-copilot.sh` returns 1 or more

---

### Phase 4: Final Verification

- [ ] Run shellcheck on modified file: `shellcheck .ralph/backends/copilot-cli/ralph-copilot.sh` (warnings OK, errors not OK)
- [ ] Verify script still shows help: `bash .ralph/backends/copilot-cli/ralph-copilot.sh 2>&1 | head -5` shows usage
- [ ] Commit changes with descriptive message

---

## Manual Steps Required

**None** - All criteria are automatable via bash commands.

---

## Rollback Plan

If this task causes issues:

```bash
# Restore from git
git checkout HEAD -- .ralph/backends/copilot-cli/ralph-copilot.sh

# Or use Ralph rollback
./.ralph/core/scripts/ralph-rollback.sh copilot-backend-fixes
```

---

## Notes

- The copilot-cli backend is marked UNTESTED - these fixes improve parity but don't validate Copilot CLI functionality
- Match existing code style: bash, heredocs, timestamp format `[$(date '+%Y-%m-%d %H:%M:%S')]`
- Do NOT add features beyond the three specified fixes
- Reference implementation patterns are in ralph-autonomous.sh but adapt to copilot context

---

## Context for Future Agents

This task implements audit recommendations from a Ralph-loop compatibility review. The copilot-cli backend is an alternative to cursor-agent for corporate environments with GitHub Copilot.

Key considerations:

1. Promise markers allow research/exploratory tasks to signal completion without checkboxes
2. Auto-branching prevents accidental work on main branch
3. Separate error logging makes debugging easier

Work incrementally through phases. Verify each phase before moving to next. Commit after each phase if convenient.
