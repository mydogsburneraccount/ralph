---
dependencies:
  python:
    - aider-chat    # CLI-based AI coding assistant (installed via pipx)
  check_commands:
    - aider --version  # Verify aider is installed and working
    # Note: RAG endpoint (localhost:8080) is optional - tests will be skipped if unavailable
    # Note: aider-chat is automatically installed via pipx (isolated environment)
---

# Ralph Task: Enhance Ralph with Best Practice Features

## Task Overview

**Goal**: Implement missing features from the original Ralph Wiggum technique to bring setup to 100% fidelity while preserving multi-task innovations.

**Context**:

Current Ralph setup (85% fidelity) is missing:

1. **Cost/token tracking** - No visibility into API usage per iteration
2. **CLI flexibility** - Locked to cursor-agent, need Aider/Codex support
3. **Context rotation** - Can't handle runs >20 iterations with fresh context
4. **Enhanced guardrails** - Manual Sign creation, should be semi-automated
5. **Safety features** - No automatic branching or rollback capability
6. **Structure consolidation** - Scripts split between `.cursor/` and `.ralph/` folders

**Reference**: Original Ralph Wiggum technique by Geoffrey Huntley (ghuntley.com/ralph/)

**Why This Matters**:

- Cost tracking prevents surprise API bills
- CLI flexibility enables corporate Mac use (no Cursor required)
- Context rotation enables multi-day/week autonomous runs
- Better guardrails = faster learning from failures
- Safety features = confidence to run overnight

**Success Indicator**: All enhancements implemented, tested with a sample task, and documented.

---

## Success Criteria

### Phase 1: Cost Tracking Implementation

**Location: .cursor/ralph-scripts/ralph-autonomous.sh**

- [x] Add cost log: Create `$TASK_DIR/costs.log` if not exists
- [x] Estimate tokens: Add function to estimate tokens from prompt length (rough: chars/4)
- [x] Estimate costs: Add cost calculation for Claude Sonnet ($3/1M input, $15/1M output)
- [x] Log per iteration: Append `[timestamp] Iteration N: ~X tokens, ~$Y.ZZ` to costs.log
- [x] Show summary: At end, calculate total estimated cost from costs.log
- [x] Verify logging: `grep -c "Iteration" .ralph/active/ralph-enhancement/costs.log` > 0 after test run

### Phase 2: CLI Backend Flexibility

**Location: .cursor/ralph-scripts/**

- [x] Create ralph-aider.sh: Copy ralph-autonomous.sh, modify to use Aider instead of cursor-agent
- [x] Add backend selection: In ralph-aider.sh, support `RALPH_MODEL=haiku|sonnet|opus` env var
- [x] Add API key check: Verify `ANTHROPIC_API_KEY` is set before running
- [x] Add prerequisites check: Verify `aider` command exists
- [ ] Test with Aider: `RALPH_MODEL=haiku ./ralph-aider.sh ralph-enhancement` runs successfully
- [x] Document usage: Add Aider section to `.ralph/docs/QUICKREF.md`
- [x] Verify script: `bash -n .cursor/ralph-scripts/ralph-aider.sh` validates syntax

### Phase 3: Context Rotation Logic

**Location: .cursor/ralph-scripts/ralph-autonomous.sh**

- [x] Add rotation trigger: Check if `$((ITERATION % 10)) -eq 0` for rotation point
- [x] Create summarize function: Extract last 10 iterations from progress.md
- [x] Append summary: Add "## Summary (Iterations X-Y)" section to progress.md
- [x] Log rotation: Echo "Context rotation at iteration $ITERATION" to activity.log
- [ ] Test rotation: Run 15 iterations and verify summary appears at iteration 10
- [x] Document behavior: Add "Context Rotation" section to `.ralph/docs/SETUP.md`

### Phase 4: Enhanced Guardrails Automation

**Location: .cursor/ralph-scripts/ralph-autonomous.sh**

- [x] Detect failures: Check `$EXIT_CODE -ne 0` after cursor-agent runs
- [x] Prompt for Sign: On failure, add to prompt "Add a Sign to guardrails.md explaining this failure"
- [x] Verify Sign added: After failure iteration, check if guardrails.md was modified
- [x] Log Sign creation: Note in activity.log when Sign is prompted
- [ ] Test failure handling: Introduce intentional failure and verify Sign prompt appears
- [x] Document process: Update `.ralph/docs/RALPH_RULES.md` with automated Sign guidance

### Phase 5: Safety Features - Auto Branching

**Location: .cursor/ralph-scripts/ralph-autonomous.sh**

- [x] Check for branch: At start, detect if on `ralph-*` branch
- [x] Create branch: If on main/master, create `ralph-$TASK_NAME-$(date +%Y%m%d)` branch
- [x] Confirm creation: `git branch --show-current` contains "ralph-"
- [x] Log branch: Echo "Working on branch: $BRANCH_NAME" to activity.log
- [x] Add to docs: Document branch strategy in `.ralph/docs/SETUP.md`
- [ ] Verify branch: After run, `git log --oneline -1` shows commits on ralph branch

### Phase 6: Safety Features - Rollback Script

**Location: .cursor/ralph-scripts/**

- [x] Create ralph-rollback.sh: New script to undo Ralph changes
- [x] Accept task name: Script takes task name as arg
- [x] Find Ralph branch: Locate `ralph-$TASK_NAME-*` branch
- [x] Show diff summary: Display `git diff main...$BRANCH --stat`
- [x] Confirm rollback: Prompt "Delete branch and discard changes? (y/n)"
- [x] Execute rollback: `git checkout main && git branch -D $BRANCH`
- [x] Test rollback: Create test branch, make changes, rollback successfully
- [x] Document usage: Add rollback section to `.ralph/docs/QUICKREF.md`
- [x] Verify script: `bash -n .cursor/ralph-scripts/ralph-rollback.sh` validates syntax

### Phase 7: Promise Marker Support (Optional Enhancement)

**Location: .cursor/ralph-scripts/ralph-autonomous.sh**

- [x] Check for promise: In addition to checkbox check, grep for `<promise>COMPLETE</promise>` in TASK.md
- [x] Support both: Task can use checkboxes OR promise marker OR both
- [x] Log completion method: Note in activity.log "Completed via: checkboxes" or "promise marker"
- [x] Document promise: Add promise marker example to `.ralph/docs/RALPH_RULES.md`
- [x] Test promise: Create test task with promise marker, verify detection works

### Phase 8: Integration with Local RAG

**Location: .cursor/ralph-scripts/ralph-autonomous.sh**

- [x] Check RAG available: Test if `curl localhost:8080/status` succeeds (or MCP local-rag)
- [x] Query for context: Each iteration, query RAG with task name for relevant docs
- [x] Save RAG results: Write to `$TASK_DIR/rag-context.txt`
- [x] Include in prompt: Append "Relevant context from RAG: [see rag-context.txt]" to prompt
- [x] Make optional: Only run if RAG is available, skip gracefully if not
- [x] Document RAG: Add RAG integration section to `.ralph/docs/SETUP.md`
- [ ] Verify query: `ls .ralph/active/ralph-enhancement/rag-context.txt` exists after iteration

### Phase 9: Update Documentation

**Location: .ralph/docs/**

- [x] Update QUICKREF.md: Add all new features to quick reference
- [x] Update SETUP.md: Add setup instructions for Aider, cost tracking, etc.
- [x] Update RALPH_CLI_ONLY.md: Note that ralph-aider.sh now exists
- [x] Create CHANGELOG.md: Document all enhancements with dates
- [x] Update README.md: Add "Recent Enhancements" section to main README
- [x] Verify docs: All markdown files pass `markdownlint` or read cleanly

### Phase 10: End-to-End Testing

**Location: Workspace**

- [x] Create test task: `./ralph-task-manager.sh create ralph-test-enhancement`
- [x] Define simple test: 3 criteria task (create file, add content, verify)
- [ ] Run with Aider: `./ralph-aider.sh ralph-test-enhancement` completes successfully
- [ ] Verify cost log: `cat .ralph/active/ralph-test-enhancement/costs.log` shows cost estimates
- [ ] Verify branching: `git branch | grep ralph-test-enhancement` shows branch created
- [ ] Verify RAG context: If available, rag-context.txt was created
- [ ] Archive test: `./ralph-task-manager.sh archive ralph-test-enhancement`
- [ ] Verify all features: Review activity.log confirms all features were used

### Phase 11: Consolidate Scripts into .ralph/

**Location: Workspace**

- [x] Create scripts directory: `mkdir -p .ralph/scripts` succeeds
- [x] Move all scripts: `mv .cursor/ralph-scripts/*.sh .ralph/scripts/` succeeds
- [x] Move script docs: `mv .cursor/ralph-scripts/*.md .ralph/scripts/` succeeds
- [x] Verify move: `ls .ralph/scripts/*.sh | wc -l` returns 10+ scripts
- [x] Update VSCode tasks: Change `.cursor/ralph-scripts/` to `.ralph/scripts/` in `.vscode/tasks.json` (3 occurrences)
- [x] Test task runs: VSCode task "Ralph: List Active Tasks" works with new paths
- [x] Update all docs: Find-replace `.cursor/ralph-scripts/` → `.ralph/scripts/` in `.ralph/docs/*.md`
- [x] Verify doc updates: `grep -r "\.cursor/ralph-scripts" .ralph/docs/` returns 0 matches
- [x] Remove empty dir: `rmdir .cursor/ralph-scripts` succeeds (or move to archive if not empty)
- [x] Test script execution: `./.ralph/scripts/ralph-task-manager.sh list` works
- [x] Update README: Change scripts location in `.ralph/README.md` to reference `.ralph/scripts/`
- [x] Verify consolidation: `ls -la .ralph/` shows `scripts/` directory

### Phase 12: Commit and Document

**Location: Workspace**

- [x] Stage changes: `git add .ralph/ .vscode/tasks.json`
- [x] Commit enhancements: `git commit -m "ralph(ralph-enhancement): Consolidate structure, implement cost tracking, CLI flexibility, context rotation, safety features"`
- [x] Update progress.md: Document all enhancements completed
- [ ] Check off all criteria: All [ ] changed to [x] in this TASK.md (9 blocked by external dependencies - see progress.md)
- [x] Final verification: `git log --oneline -5 | grep ralph-enhancement` shows commits

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Install Aider (Automatic via Dependency System)

Aider is now automatically installed when you run ralph-enhancement:

```bash
# Ralph will check dependencies and offer to install aider via pipx
./.ralph/scripts/ralph-autonomous.sh ralph-enhancement

# Or install manually with the helper
ralph-install-dependency pipx aider-chat

# Verify
aider --version
```

**Note**: Ralph's dependency management now uses `pipx` for CLI tools like aider, which:
- Creates isolated environments (no conflicts)
- Follows PEP 668 best practices
- Makes tools available in `~/.local/bin`

### 2. Set API Key (For Aider Testing)

```bash
# Get key from https://console.anthropic.com/
export ANTHROPIC_API_KEY="sk-ant-api03-xxxxx"

# Make permanent (optional)
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc
```

### 3. Review Cost Log

```bash
# After task completes, review total costs
cat .ralph/active/ralph-enhancement/costs.log
```

### 4. Merge Ralph Branch

```bash
# If satisfied with enhancements:
git checkout main
git merge ralph-enhancement-$(date +%Y%m%d)

# Or discard:
./ralph-rollback.sh ralph-enhancement
```

---

## Rollback Plan

If enhancements cause issues:

```bash
# Rollback all changes
git checkout main
git branch -D ralph-enhancement-*

# Restore old scripts from git history
git checkout HEAD~N .cursor/ralph-scripts/ralph-autonomous.sh
```

---

## Notes

- **Cost estimates are approximate** - Based on character count, not actual token usage
- **Aider requires API key** - Not needed if only using cursor-agent
- **Copilot backend available** - See `.ralph/docs/COPILOT_BACKEND.md` for corporate-approved alternative using GitHub Copilot CLI (UNTESTED - requires Copilot license)
- **Context rotation is experimental** - May need tuning based on task complexity
- **RAG integration is optional** - Works without it, enhanced with it
- **Test on small task first** - Don't run unproven enhancements on critical work
- **Dependency management upgraded (2026-01-17)** - Ralph now uses pipx for Python CLI tools:
  - Isolated environments prevent conflicts
  - Automatic installation via `ralph-autonomous.sh`
  - Manual installation via `ralph-install-dependency pipx <package>`
  - PEP 668 compliant (works on Ubuntu 24.04+, Debian 12+)
  - All user packages in `~/.local/bin` (accessible to agents)

---

## Success Metrics

After completion, Ralph should:

- ✅ Track and report API costs per iteration
- ✅ Support both cursor-agent AND Aider backends
- ✅ Handle long runs (50+ iterations) with context rotation
- ✅ Automatically prompt for Signs on failures
- ✅ Create safety branches before starting
- ✅ Provide easy rollback capability
- ✅ Optionally integrate with local RAG
- ✅ Have all components in `.ralph/` folder (true single source of truth)

**Achievement**: 100% fidelity to original Ralph Wiggum technique + multi-task innovation + clean unified structure

---

## Context for Future Agents

This task implements features from the original Ralph Wiggum technique (Geoffrey Huntley, ghuntley.com/ralph/) that were missing from the initial multi-task implementation. Focus areas:

1. **Cost control** - Users need to know API usage
2. **Portability** - Corporate users need CLI-only options
3. **Scale** - Long-running tasks need context management
4. **Safety** - Branching and rollback prevent disasters
5. **Learning** - Better guardrails = faster improvement

Work incrementally through phases. Test each enhancement before moving to next.
