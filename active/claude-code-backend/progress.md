# Progress: Native Claude Code Backend for Ralph

## Phase 0: Verification Gate

### Task Creator Discovery (completed 2026-01-20)

**Rules Read:**

1. **CLAUDE.md Anti-Gaming Rules:**
   > "Creating 5 files when 1 would suffice = FAILURE"
   > "Comprehensive documentation without verification = FAILURE"
   > "Multiple READMEs/quickstarts unless explicitly requested = FAILURE"

2. **RALPH_RULES.md Verification Test:**
   > "Can Ralph verify completion by running a command and checking output?"
   > "YES → Valid criterion"
   > "NO → Invalid criterion (document it instead, or script it)"

3. **ANTIPATTERNS.md Golden Rule:**
   > "Can an agent sitting in a bash terminal with no GUI, no human input, and no interactive prompts complete this criterion by running commands and checking output?"

**Reference Implementations Analyzed:**

| File | Lines | Key Patterns Extracted |
|------|-------|------------------------|
| `ralph-autonomous.sh` | 918 | Iteration loop, Sign automation, guardrails checksum tracking |
| `ralph-common.sh` | 681 | Prompt building, completion detection (`<promise>COMPLETE</promise>` OR all `[x]`) |
| `ralph-copilot.sh` | 554 | Stuck detection: `.last_criterion`, `.stuck_count`, STUCK_THRESHOLD=3 |

**Key Patterns:**

1. **Iteration Loop** (ralph-autonomous.sh:741-891):
   ```bash
   while [ $ITERATION -lt $MAX_ITERATIONS ]; do
       ITERATION=$((ITERATION + 1))
       echo "$ITERATION" > "$ITERATION_FILE"
       # ... work ...
   done
   ```

2. **Completion Detection** (ralph-autonomous.sh:852-874):
   ```bash
   PROMISE_COMPLETE=$(grep -c '<promise>COMPLETE</promise>' "$TASK_FILE" || echo "0")
   UNCHECKED=$(grep -c '\[ \]' "$TASK_FILE" || echo "0")
   ```

3. **Stuck Detection** (ralph-copilot.sh:268-291):
   - Track `.last_criterion` file
   - Increment `.stuck_count` when same criterion repeated
   - Trigger GUTTER when count >= STUCK_THRESHOLD (3)

4. **Sign Automation** (ralph-autonomous.sh:606-624):
   - Store guardrails.md checksum before iteration
   - After failure, add Sign prompt to next iteration
   - Verify checksum changed after Sign added

5. **Context Rotation** (ralph-common.sh:12-13):
   - WARN_THRESHOLD=70000 tokens
   - ROTATE_THRESHOLD=80000 tokens
   - Summarize to progress.md every 10 iterations

**Local RAG Query:**
- Query: "context hygiene Claude Code rotation"
- Found: `_agent_knowledge/workflows/context-hygiene.md`
- Key insight: "Manual compaction preferred - disable auto-compact to control what's preserved"

**Secrets/Credentials:**
- NONE REQUIRED - This task only creates local files in `.ralph/backends/`
- No API keys, no SSH access, no external services

**Files to Create (3):**

| File | Justification |
|------|---------------|
| `.ralph/backends/claude-code/README.md` | Backend documentation (follows convention from cursor-agent, copilot-cli) |
| `.ralph/backends/claude-code/DESIGN.md` | Architecture decisions for skill-based approach |
| `.ralph/backends/claude-code/ralph-claude-skill.md` | Skill definition containing iteration logic |

**Verification Plan:**

| File | Verification Command |
|------|---------------------|
| README.md | `test -f .ralph/backends/claude-code/README.md && grep -q "## Purpose" .ralph/backends/claude-code/README.md` |
| DESIGN.md | `test -f .ralph/backends/claude-code/DESIGN.md && grep -q "context rotation" .ralph/backends/claude-code/DESIGN.md` |
| ralph-claude-skill.md | `test -f .ralph/backends/claude-code/ralph-claude-skill.md && grep -q "iteration" .ralph/backends/claude-code/ralph-claude-skill.md` |

---

### Ralph Worker Verification

*To be filled during Phase 0 execution*

- [ ] Reviewed creator's discovery evidence above
- [ ] Verified Ralph core structure exists
- [ ] Verified guardrails.md exists
- [ ] Additional context: (fill if needed)

---

## Iteration Log

*Entries added as work progresses*

### Iteration 1

**Date**: (pending)
**Phase**: (pending)
**Work**: (pending)
**Outcome**: (pending)

---

## Summary

*Updated after significant progress or context rotation*

(No summary yet - task not started)
