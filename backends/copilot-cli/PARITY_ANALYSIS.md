# Ralph-Loop Copilot CLI Feature Parity Analysis

**Date**: 2026-01-21
**Analyst**: Claude (via Ralph Loop)
**Status**: Complete

---

## Executive Summary

This document analyzes the feature gap between the Claude Code `ralph-loop` plugin (reference implementation) and the Copilot CLI `ralph-copilot.sh` backend. The implementations use fundamentally different mechanisms:

- **Claude Code**: Internal stop hooks intercept session exit, re-injecting prompts
- **Copilot CLI**: External while-loop script manages iterations

Despite architectural differences, most features can achieve functional parity.

---

## Feature Comparison Matrix

| Feature | Claude Code (plugin) | Copilot (script) | Gap | Solvable? | Priority |
|---------|---------------------|------------------|-----|-----------|----------|
| **Core Loop** |
| Iteration tracking | State file (`ralph-loop.local.md`) + stop hook | `.iteration` file + while loop | Different mechanism | N/A (by design) | - |
| Same-prompt re-injection | Stop hook intercepts exit, re-injects | Script rebuilds prompt each iteration | Different mechanism | N/A (by design) | - |
| Max iterations limit | `--max-iterations` flag | `MAX_ITERATIONS=20` hardcoded | Missing CLI flag | Yes - Easy | High |
| Completion promise | `<promise>` tag parsing from transcript | Checkbox counting only | Missing promise detection | Yes - Medium | High |
| **Guardrails** |
| Guardrails injection | `--guardrails <file>` → system message | Reads `guardrails.md` in prompt | Format differs | Yes - Easy | Medium |
| Guardrails format | `--- GUARDRAILS (read before proceeding) ---` | Inline in prompt | Different format | Yes - Easy | Low |
| **Progress Tracking** |
| Progress file flag | `--progress <file>` | Hardcoded `progress.md` path | Missing CLI flag | Yes - Easy | Medium |
| Progress injection | Last 50 lines injected into system message | Not injected (read manually) | Missing injection | Yes - Medium | High |
| Progress initialization | Creates header with task/timestamp | Creates minimal header | Less informative | Yes - Easy | Low |
| Iteration log format | Markdown with git diff summary | Simple text entries | Less detail | Yes - Easy | Low |
| **Stuck Detection** |
| Stuck threshold flag | `--stuck-threshold <n>` | `STUCK_THRESHOLD=3` hardcoded | Missing CLI flag | Yes - Easy | Medium |
| Hash-based detection | `git diff --stat` MD5 hash comparison | Same-criterion counting | Different algorithm | Yes - Medium | Medium |
| Stuck warning injection | Warning in system message | Stops loop, adds to guardrails | More aggressive | Intentional | - |
| **Activity Logging** |
| Activity log path | `.claude/ralph-activity.log` | `activity.log` in task dir | Different location | Intentional | - |
| Log format | `[timestamp] Event description` | Same format | Equivalent | N/A | - |
| Premium tracking | N/A | `premium_requests.log` | Copilot-specific | N/A | - |
| **Session Management** |
| State persistence | YAML frontmatter in `.local.md` | Multiple `.files` | Different approach | N/A (by design) | - |
| YAML escaping | `jq -Rs` for proper escaping | N/A | Not applicable | N/A | - |
| Transcript access | Via hook input JSON | N/A (no transcript) | Fundamental | No | - |

---

## Detailed Gap Analysis

### Gap 1: Progress File Injection into Prompt

**Claude Code Behavior:**
```bash
# In stop-hook.sh (lines 256-265)
PROGRESS_CONTENT=$(tail -50 "$PROGRESS_FILE" 2>/dev/null || echo "")
SYSTEM_MSG="$SYSTEM_MSG

--- PROGRESS LOG (your work so far, last 50 lines) ---
$PROGRESS_CONTENT
--- END PROGRESS ---"
```

**Current Copilot Behavior:**
- Progress file exists but is not injected into the prompt
- Agent must manually read `progress.md` to see history

**Solution:**
Modify `build_prompt()` to include last 50 lines of progress.md:
```bash
build_prompt() {
    local iteration=$1
    local progress_content=""
    if [[ -f "$PROGRESS_FILE" ]]; then
        progress_content=$(tail -50 "$PROGRESS_FILE")
    fi
    # Include in prompt...
}
```

**Solvable:** Yes
**Effort:** Low
**Fidelity:** 95% (minor format differences acceptable)

---

### Gap 2: Hash-Based Stuck Detection

**Claude Code Behavior:**
```bash
# In stop-hook.sh (lines 171-192)
if git rev-parse --git-dir > /dev/null 2>&1; then
    CURRENT_HASH=$(git diff HEAD --stat 2>/dev/null | md5sum | cut -d' ' -f1)
else
    CURRENT_HASH=$(find . -type f -newer "$RALPH_STATE_FILE" 2>/dev/null | sort | md5sum | cut -d' ' -f1)
fi

if [[ "$CURRENT_HASH" = "$LAST_FILE_HASH" ]]; then
    STUCK_COUNT=$((STUCK_COUNT + 1))
fi
```

**Current Copilot Behavior:**
```bash
# Tracks same-criterion attempts
if [ "$current_criterion" = "$last_criterion" ]; then
    stuck_count++
fi
```

**Analysis:**
- Claude Code detects stuck by file changes (git diff hash)
- Copilot detects stuck by criterion progress (checkbox movement)
- Both are valid; git hash approach catches more subtle stuck states

**Solution:**
Add hash-based detection alongside criterion tracking:
```bash
check_stuck_by_hash() {
    local current_hash=""
    if git rev-parse --git-dir > /dev/null 2>&1; then
        current_hash=$(git diff HEAD --stat 2>/dev/null | md5sum | cut -d' ' -f1)
    fi
    # Compare with stored hash...
}
```

**Solvable:** Yes
**Effort:** Medium
**Fidelity:** 100%

---

### Gap 3: Completion Promise Detection

**Claude Code Behavior:**
```bash
# In stop-hook.sh (lines 125-139)
# Extracts <promise>text</promise> from transcript
PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s')
if [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    echo "Detected <promise>$COMPLETION_PROMISE</promise>"
    exit 0  # Allow exit
fi
```

**Current Copilot Behavior:**
- No promise detection
- Relies solely on checkbox counting

**Analysis:**
- Copilot CLI doesn't have transcript access like Claude Code's stop hook
- Would need to capture and parse Copilot's output stream

**Solution:**
Capture Copilot output and scan for promise tags:
```bash
OUTPUT=$(run_copilot_cli "$PROMPT" | tee /dev/tty)
if echo "$OUTPUT" | grep -qP '<promise>.*</promise>'; then
    PROMISE_TEXT=$(echo "$OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s')
    if [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
        echo "Promise fulfilled!"
        break
    fi
fi
```

**Solvable:** Yes
**Effort:** Medium
**Fidelity:** 90% (depends on Copilot output capture reliability)

---

### Gap 4: CLI Flag Parity

**Claude Code Flags:**
- `--max-iterations <n>`
- `--completion-promise '<text>'`
- `--guardrails <file>`
- `--progress <file>`
- `--stuck-threshold <n>`

**Current Copilot Flags:**
- Positional: `<task-name>` (required)
- Environment variables for all configuration

**Solution:**
Add getopts-based flag parsing to match Claude Code interface:
```bash
while getopts ":m:c:g:p:s:" opt; do
    case $opt in
        m) MAX_ITERATIONS="$OPTARG" ;;
        c) COMPLETION_PROMISE="$OPTARG" ;;
        g) GUARDRAILS_FILE="$OPTARG" ;;
        p) PROGRESS_FILE="$OPTARG" ;;
        s) STUCK_THRESHOLD="$OPTARG" ;;
    esac
done
```

Or use long options with case parsing (matching current Claude Code style).

**Solvable:** Yes
**Effort:** Low-Medium
**Fidelity:** 100%

---

### Gap 5: Guardrails Injection Format

**Claude Code Format:**
```
--- GUARDRAILS (read before proceeding) ---
[guardrails content]
--- END GUARDRAILS ---
```

**Current Copilot Behavior:**
- Includes path in prompt: "Read $GUARDRAILS_FILE for lessons learned"
- Expects agent to read file

**Solution:**
Inline guardrails content with Claude Code format:
```bash
GUARDRAILS_CONTENT=""
if [[ -f "$GUARDRAILS_FILE" ]]; then
    GUARDRAILS_CONTENT="
--- GUARDRAILS (read before proceeding) ---
$(cat "$GUARDRAILS_FILE")
--- END GUARDRAILS ---"
fi
```

**Solvable:** Yes
**Effort:** Low
**Fidelity:** 100%

---

### Gap 6: Progress Initialization and Update Format

**Claude Code Progress Header:**
```markdown
# Ralph Loop Progress

**Task:** $PROMPT
**Started:** 2026-01-21T03:33:59Z
**Current iteration:** 1

## Iteration Log

### Iteration 1 (2026-01-21T03:33:59Z)
- Loop initialized
```

**Claude Code Iteration Entry:**
```markdown
### Iteration N (timestamp)
- Files: X files changed, Y insertions(+), Z deletions(-)
```

**Current Copilot Behavior:**
- Minimal header: `# Progress Log`
- Simple entries, no git diff summary

**Solution:**
Match Claude Code format exactly:
```bash
init_progress_file() {
    cat > "$PROGRESS_FILE" <<EOF
# Ralph Loop Progress

**Task:** $TASK_NAME
**Started:** $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Current iteration:** 1

## Iteration Log

### Iteration 1 ($(date -u +%Y-%m-%dT%H:%M:%SZ))
- Loop initialized
EOF
}

update_progress() {
    local iteration=$1
    local git_summary=$(git diff --stat HEAD 2>/dev/null | tail -1)
    [[ -z "$git_summary" ]] && git_summary="No uncommitted changes"

    # Update current iteration line
    sed -i "s/^\*\*Current iteration:\*\* .*/\*\*Current iteration:\*\* $iteration/" "$PROGRESS_FILE"

    # Append entry
    cat >> "$PROGRESS_FILE" <<EOF

### Iteration $iteration ($(date -u +%Y-%m-%dT%H:%M:%SZ))
- Files: $git_summary
EOF
}
```

**Solvable:** Yes
**Effort:** Low
**Fidelity:** 100%

---

## Unsolvable Gaps (By Design)

### Transcript Access

**Problem:** Claude Code's stop hook receives `transcript_path` via hook input JSON, enabling it to read the full assistant output and detect `<promise>` tags precisely.

**Copilot Limitation:** No stop hook mechanism; external script cannot access internal Copilot state.

**Workaround:** Capture stdout/stderr and parse, but less reliable.

---

### In-Session Context Continuity

**Problem:** Claude Code's stop hook keeps the same Claude session alive, preserving full context (conversation history, tool results, etc.).

**Copilot Limitation:** Each iteration is a fresh Copilot invocation; no persistent session context.

**Workaround:** Inject context via prompt (progress log, guardrails). This is already the Copilot pattern.

---

## Implementation Priority

### High Priority (Core Functionality)
1. Progress file injection into prompt
2. Completion promise detection
3. CLI flag parity (`--max-iterations`, `--completion-promise`, etc.)

### Medium Priority (Enhanced Experience)
4. Hash-based stuck detection
5. Guardrails format matching
6. Progress file initialization format

### Low Priority (Polish)
7. Git diff summary in iteration entries
8. Current iteration line updates

---

## Recommended Implementation Order

1. **Add CLI flags** - Makes script more usable and matches Claude Code interface
2. **Progress injection** - Critical for cross-iteration awareness
3. **Promise detection** - Enables intelligent loop termination
4. **Hash-based stuck detection** - Catches subtle stuck states
5. **Format matching** - Polish for consistency

---

## Verification Commands

After implementation, verify with:

```bash
# Check CLI flags work
./ralph-copilot.sh --help
./ralph-copilot.sh my-task --max-iterations 5 --completion-promise "DONE"

# Check progress injection
grep "PROGRESS LOG" <(./ralph-copilot.sh my-task 2>&1 | head -100)

# Check promise detection (mock test)
echo '<promise>TEST</promise>' | ./test-promise-detection.sh

# Check stuck detection
# Run 5+ iterations with no changes, verify warning
```

---

## Appendix: Claude Code Plugin Source Locations

| Component | File | Key Lines |
|-----------|------|-----------|
| Flag parsing | `setup-ralph-loop.sh` | 18-171 |
| State file creation | `setup-ralph-loop.sh` | 221-236 |
| Progress initialization | `setup-ralph-loop.sh` | 250-263 |
| Iteration detection | `stop-hook.sh` | 21-33 |
| Promise detection | `stop-hook.sh` | 125-139 |
| Stuck detection | `stop-hook.sh` | 166-192 |
| Progress injection | `stop-hook.sh` | 256-265 |
| Guardrails injection | `stop-hook.sh` | 244-253 |
| System message building | `stop-hook.sh` | 229-265 |
