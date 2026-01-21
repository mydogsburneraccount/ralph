#!/bin/bash
# ============================================================================
# Ralph Autonomous Loop - GitHub Copilot CLI Backend
#
# UNTESTED - Requires active GitHub Copilot license to run
#
# Run this for CLI-only autonomous development using corporate-approved
# GitHub Copilot instead of Aider + Anthropic API.
#
# Supports RALPH_COPILOT_MODEL env var (default: gpt-4o for free tier)
# Premium: claude-sonnet, claude, gpt-5
# Free tier (0x multiplier): gpt-4o, gpt-4.1, gpt-5-mini, gpt-5-codex-mini
#
# Feature parity with Claude Code ralph-loop plugin (2026-01-21):
# - CLI flags: --max-iterations, --completion-promise, --guardrails, --progress, --stuck-threshold
# - Progress injection into prompt (last 50 lines)
# - Completion promise detection via <promise> tags
# - Hash-based stuck detection (git diff comparison)
# - Guardrails content injection with standard format
# ============================================================================

set -euo pipefail

WORKSPACE=$(pwd)
SCRIPT_VERSION="2.0.0-untested"

# ============================================================================
# MODEL CONFIGURATION
# ============================================================================

# Model selection via environment variable
# Default to gpt-4o (free tier) to avoid burning premium quota
RALPH_COPILOT_MODEL="${RALPH_COPILOT_MODEL:-gpt-4o}"

# Known models with premium/free classification
case "$RALPH_COPILOT_MODEL" in
    # Premium models (count against quota)
    claude-sonnet|claude-sonnet-4.5)
        COPILOT_MODEL="claude-sonnet-4.5"
        IS_PREMIUM=true
        MODEL_DISPLAY="Claude Sonnet 4.5 (premium)"
        ;;
    claude|claude-4)
        COPILOT_MODEL="claude-4"
        IS_PREMIUM=true
        MODEL_DISPLAY="Claude 4 (premium)"
        ;;
    gpt-5)
        COPILOT_MODEL="gpt-5"
        IS_PREMIUM=true
        MODEL_DISPLAY="GPT-5 (premium)"
        ;;

    # Free tier models (0x multiplier - don't count against quota)
    gpt-4o)
        COPILOT_MODEL="gpt-4o"
        IS_PREMIUM=false
        MODEL_DISPLAY="GPT-4o (free tier)"
        ;;
    gpt-4.1)
        COPILOT_MODEL="gpt-4.1"
        IS_PREMIUM=false
        MODEL_DISPLAY="GPT-4.1 (free tier)"
        ;;
    gpt-5-mini)
        COPILOT_MODEL="gpt-5-mini"
        IS_PREMIUM=false
        MODEL_DISPLAY="GPT-5-mini (free tier)"
        ;;
    gpt-5-codex-mini)
        COPILOT_MODEL="gpt-5-codex-mini"
        IS_PREMIUM=false
        MODEL_DISPLAY="GPT-5-codex-mini (free tier, code-optimized)"
        ;;

    # Unknown model - pass through with warning (flexible mode)
    *)
        COPILOT_MODEL="$RALPH_COPILOT_MODEL"
        IS_PREMIUM=true  # Assume premium for safety (will log correctly)
        MODEL_DISPLAY="$RALPH_COPILOT_MODEL (unknown - check 'copilot /model')"
        echo "Warning: Unknown model: $RALPH_COPILOT_MODEL"
        echo "   Will attempt to use it. Run 'copilot /model' to see available models."
        echo ""
        ;;
esac

# ============================================================================
# FEATURE FLAGS
# ============================================================================

# Fallback to CLI wrapping if ACP mode fails
RALPH_COPILOT_FALLBACK="${RALPH_COPILOT_FALLBACK:-false}"

# Auto-approve safe operations (file edits in task dir, git status/diff/commit)
RALPH_COPILOT_AUTO_APPROVE="${RALPH_COPILOT_AUTO_APPROVE:-true}"

# Use ACP mode for programmatic control (experimental)
RALPH_COPILOT_USE_ACP="${RALPH_COPILOT_USE_ACP:-false}"

# ============================================================================
# ARGUMENT PARSING (Claude Code compatible flags)
# ============================================================================

show_help() {
    cat << 'HELP_EOF'
Ralph Copilot Backend - Autonomous development loop using GitHub Copilot CLI

USAGE:
  ./ralph-copilot.sh <task-name> [OPTIONS]

ARGUMENTS:
  task-name    Name of task directory in .ralph/active/ or full path

OPTIONS:
  --max-iterations <n>           Maximum iterations before auto-stop (default: 20)
  --completion-promise '<text>'  Promise phrase that signals completion
  --guardrails <file>            File to inject into prompt each iteration
  --progress <file>              File to log iteration progress (injected each iteration)
  --stuck-threshold <n>          Warn after N iterations with no file changes (default: 3)
  -h, --help                     Show this help message

ENVIRONMENT VARIABLES:
  RALPH_COPILOT_MODEL=<model>       Model to use (default: gpt-4o)
  RALPH_COPILOT_FALLBACK=true|false Fallback to CLI mode if ACP fails
  RALPH_COPILOT_USE_ACP=true|false  Use experimental ACP mode

  Premium models (count against quota):
    claude-sonnet, claude, gpt-5

  Free tier models (0x multiplier, recommended):
    gpt-4o          - Good all-rounder (default)
    gpt-5-codex-mini - Best for code tasks
    gpt-4.1, gpt-5-mini

EXAMPLES:
  ./ralph-copilot.sh my-task
  ./ralph-copilot.sh my-task --max-iterations 10
  ./ralph-copilot.sh my-task --completion-promise 'DONE' --max-iterations 25
  ./ralph-copilot.sh my-task --guardrails .ralph/guardrails.md
  ./ralph-copilot.sh my-task --progress progress.md --stuck-threshold 5
  RALPH_COPILOT_MODEL=claude-sonnet ./ralph-copilot.sh my-task

COMPLETION PROMISE:
  When --completion-promise is set, the loop checks Copilot's output for:
    <promise>YOUR_PHRASE</promise>

  The loop exits when the promise text matches exactly.

HELP_EOF
}

# Defaults
TASK_NAME=""
MAX_ITERATIONS=20
COMPLETION_PROMISE=""
GUARDRAILS_FILE=""
PROGRESS_FILE_ARG=""
STUCK_THRESHOLD=3

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --max-iterations)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --max-iterations requires a number argument" >&2
                exit 1
            fi
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "Error: --max-iterations must be a positive integer, got: $2" >&2
                exit 1
            fi
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        --completion-promise)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --completion-promise requires a text argument" >&2
                exit 1
            fi
            COMPLETION_PROMISE="$2"
            shift 2
            ;;
        --guardrails)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --guardrails requires a file path argument" >&2
                exit 1
            fi
            if [[ ! -f "$2" ]]; then
                echo "Error: Guardrails file not found: $2" >&2
                exit 1
            fi
            GUARDRAILS_FILE="$2"
            shift 2
            ;;
        --progress)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --progress requires a file path argument" >&2
                exit 1
            fi
            PROGRESS_FILE_ARG="$2"
            shift 2
            ;;
        --stuck-threshold)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --stuck-threshold requires a number argument" >&2
                exit 1
            fi
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "Error: --stuck-threshold must be a positive integer, got: $2" >&2
                exit 1
            fi
            STUCK_THRESHOLD="$2"
            shift 2
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
        *)
            # First non-option argument is the task name
            if [[ -z "$TASK_NAME" ]]; then
                TASK_NAME="$1"
            else
                echo "Error: Unexpected argument: $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$TASK_NAME" ]]; then
    echo "Ralph Copilot Backend v$SCRIPT_VERSION"
    echo "UNTESTED - Requires active Copilot license"
    echo ""
    echo "Usage: $0 <task-name> [OPTIONS]"
    echo ""
    echo "Available tasks:"
    ls -1 "$WORKSPACE/.ralph/active/" 2>/dev/null || echo "  (no active tasks)"
    echo ""
    echo "Use --help for full usage information"
    exit 1
fi

# ============================================================================
# TASK DIRECTORY SETUP
# ============================================================================

if [[ -d "$WORKSPACE/.ralph/active/$TASK_NAME" ]]; then
    TASK_DIR="$WORKSPACE/.ralph/active/$TASK_NAME"
elif [[ -d "$TASK_NAME" ]]; then
    TASK_DIR="$TASK_NAME"
else
    echo "Error: Task not found: $TASK_NAME" >&2
    echo ""
    echo "Available tasks:"
    ls -1 "$WORKSPACE/.ralph/active/" 2>/dev/null || echo "  (no active tasks)"
    exit 1
fi

TASK_FILE="$TASK_DIR/TASK.md"
ITERATION_FILE="$TASK_DIR/.iteration"
ACTIVITY_LOG="$TASK_DIR/activity.log"
PREMIUM_LOG="$TASK_DIR/premium_requests.log"

# Progress file: use --progress arg or default to task dir
if [[ -n "$PROGRESS_FILE_ARG" ]]; then
    PROGRESS_FILE="$PROGRESS_FILE_ARG"
else
    PROGRESS_FILE="$TASK_DIR/progress.md"
fi

# Guardrails: use --guardrails arg or default
if [[ -z "$GUARDRAILS_FILE" ]]; then
    GUARDRAILS_FILE="$WORKSPACE/.ralph/guardrails.md"
fi

# Hash-based stuck detection files
LAST_HASH_FILE="$TASK_DIR/.last_hash"
STUCK_COUNT_FILE="$TASK_DIR/.stuck_count"
LAST_CRITERION_FILE="$TASK_DIR/.last_criterion"

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

if [[ ! -f "$TASK_FILE" ]]; then
    echo "Error: TASK.md not found in $TASK_DIR" >&2
    exit 1
fi

# Check for copilot CLI
check_copilot_cli() {
    # Try new copilot-cli first (npm @github/copilot)
    if command -v copilot &> /dev/null; then
        COPILOT_CMD="copilot"
        return 0
    fi

    # Fall back to gh copilot extension (deprecated but may work)
    if command -v gh &> /dev/null && gh copilot --help &> /dev/null 2>&1; then
        COPILOT_CMD="gh copilot"
        echo "Warning: Using deprecated gh copilot extension"
        echo "   Consider installing: npm install -g @github/copilot"
        return 0
    fi

    echo "Error: Copilot CLI not found" >&2
    echo ""
    echo "Install with one of:"
    echo "  npm install -g @github/copilot     # Recommended"
    echo "  brew install github/copilot/copilot"
    echo "  winget install GitHub.Copilot"
    echo ""
    echo "Then authenticate:"
    echo "  copilot /login"
    exit 1
}

check_copilot_cli

# Check GitHub authentication
check_github_auth() {
    # For new copilot-cli, check if logged in
    if [[ "$COPILOT_CMD" = "copilot" ]]; then
        echo "Info: Using copilot-cli. If not authenticated, run: copilot /login"
        return 0
    fi

    # For gh copilot, check gh auth
    if ! gh auth status &> /dev/null; then
        echo "Error: Not authenticated with GitHub" >&2
        echo ""
        echo "Authenticate with: gh auth login"
        exit 1
    fi
}

check_github_auth

# ============================================================================
# FILE INITIALIZATION
# ============================================================================

[[ ! -f "$ITERATION_FILE" ]] && echo "0" > "$ITERATION_FILE"
[[ ! -f "$ACTIVITY_LOG" ]] && touch "$ACTIVITY_LOG"
[[ ! -f "$PREMIUM_LOG" ]] && echo "# Premium Request Tracking" > "$PREMIUM_LOG"
[[ ! -f "$LAST_HASH_FILE" ]] && echo "" > "$LAST_HASH_FILE"
[[ ! -f "$STUCK_COUNT_FILE" ]] && echo "0" > "$STUCK_COUNT_FILE"
[[ ! -f "$LAST_CRITERION_FILE" ]] && echo "" > "$LAST_CRITERION_FILE"

# Initialize progress file with Claude Code format
init_progress_file() {
    if [[ ! -f "$PROGRESS_FILE" ]]; then
        cat > "$PROGRESS_FILE" <<EOF
# Ralph Loop Progress

**Task:** $TASK_NAME
**Started:** $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Current iteration:** 1

## Iteration Log

### Iteration 1 ($(date -u +%Y-%m-%dT%H:%M:%SZ))
- Loop initialized
EOF
    fi
}

init_progress_file

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Log premium request for quota tracking
log_premium_request() {
    local iteration=$1
    local model=$2
    local is_premium=$3

    if [[ "$is_premium" = "true" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $iteration: model=$model PREMIUM" >> "$PREMIUM_LOG"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $iteration: model=$model (free tier)" >> "$PREMIUM_LOG"
    fi
}

# Count premium requests from log
count_premium_requests() {
    if [[ -f "$PREMIUM_LOG" ]]; then
        grep -c "PREMIUM" "$PREMIUM_LOG" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Get first unchecked criterion
get_next_criterion() {
    grep -m1 '\[ \]' "$TASK_FILE" 2>/dev/null | sed 's/.*\[ \]//' | xargs || echo ""
}

# Calculate file state hash for stuck detection (Claude Code style)
get_file_hash() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Use git diff stat for hash (catches staged and unstaged changes)
        git diff HEAD --stat 2>/dev/null | md5sum | cut -d' ' -f1
    else
        # Fallback: hash of recent file changes
        find . -type f -newer "$ITERATION_FILE" 2>/dev/null | sort | md5sum | cut -d' ' -f1
    fi
}

# Check if stuck using hash-based detection (Claude Code style)
check_stuck_by_hash() {
    local current_hash
    current_hash=$(get_file_hash)
    local last_hash
    last_hash=$(cat "$LAST_HASH_FILE" 2>/dev/null || echo "")

    if [[ -n "$last_hash" ]] && [[ "$current_hash" = "$last_hash" ]]; then
        # No changes detected
        local stuck_count
        stuck_count=$(cat "$STUCK_COUNT_FILE" 2>/dev/null || echo "0")
        stuck_count=$((stuck_count + 1))
        echo "$stuck_count" > "$STUCK_COUNT_FILE"

        if [[ $stuck_count -ge $STUCK_THRESHOLD ]]; then
            echo "STUCK"
            return
        fi
    else
        # Changes detected, reset counter
        echo "0" > "$STUCK_COUNT_FILE"
    fi

    echo "$current_hash" > "$LAST_HASH_FILE"
    echo "OK"
}

# Update progress file with iteration entry (Claude Code format)
update_progress() {
    local iteration=$1
    local git_summary=""

    if git rev-parse --git-dir > /dev/null 2>&1; then
        git_summary=$(git diff --stat HEAD 2>/dev/null | tail -1)
        [[ -z "$git_summary" ]] && git_summary="No uncommitted changes"
    else
        git_summary="Not a git repository"
    fi

    # Update current iteration line
    if [[ -f "$PROGRESS_FILE" ]]; then
        sed -i "s/^\*\*Current iteration:\*\* .*/\*\*Current iteration:\*\* $iteration/" "$PROGRESS_FILE"
    fi

    # Append iteration entry
    cat >> "$PROGRESS_FILE" <<EOF

### Iteration $iteration ($(date -u +%Y-%m-%dT%H:%M:%SZ))
- Files: $git_summary
EOF
}

# Build prompt for Copilot (with progress and guardrails injection)
build_prompt() {
    local iteration=$1
    local next_criterion
    next_criterion=$(get_next_criterion)

    # Build base prompt
    local prompt
    prompt=$(cat << EOF
Start Ralph iteration $iteration for task: $TASK_NAME

Follow the Ralph protocol:

1. Read $TASK_FILE for task definition
2. Work on next unchecked [ ] criterion
3. Commit frequently: git commit -m 'ralph($TASK_NAME): [criterion] - change'
4. Update progress when done
5. Check off criterion in $TASK_FILE
6. Commit state files

Current focus: $next_criterion

Task directory: $TASK_DIR
EOF
)

    # Inject guardrails content (Claude Code format)
    if [[ -f "$GUARDRAILS_FILE" ]]; then
        local guardrails_content
        guardrails_content=$(cat "$GUARDRAILS_FILE" 2>/dev/null || echo "")
        if [[ -n "$guardrails_content" ]]; then
            prompt="$prompt

--- GUARDRAILS (read before proceeding) ---
$guardrails_content
--- END GUARDRAILS ---"
        fi
    fi

    # Inject progress log (last 50 lines, Claude Code format)
    if [[ -f "$PROGRESS_FILE" ]]; then
        local progress_content
        progress_content=$(tail -50 "$PROGRESS_FILE" 2>/dev/null || echo "")
        if [[ -n "$progress_content" ]]; then
            prompt="$prompt

--- PROGRESS LOG (your work so far, last 50 lines) ---
$progress_content
--- END PROGRESS ---"
        fi
    fi

    # Add completion promise instructions if set
    if [[ -n "$COMPLETION_PROMISE" ]]; then
        prompt="$prompt

--- COMPLETION PROMISE ---
To signal task completion, output: <promise>$COMPLETION_PROMISE</promise>
Only output this when the statement is completely TRUE.
Do NOT output false promises to exit early.
--- END PROMISE ---"
    fi

    echo "$prompt"
}

# Detect completion promise in output
detect_promise() {
    local output="$1"
    local expected="$2"

    if [[ -z "$expected" ]]; then
        echo "NO_PROMISE_SET"
        return
    fi

    # Extract text from <promise> tags using perl for reliability
    local promise_text
    promise_text=$(echo "$output" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")

    if [[ -n "$promise_text" ]] && [[ "$promise_text" = "$expected" ]]; then
        echo "PROMISE_FULFILLED"
    else
        echo "NO_MATCH"
    fi
}

# Run copilot with CLI wrapping (fallback mode)
run_copilot_cli() {
    local prompt="$1"

    echo "Running Copilot CLI (standard mode)..."

    # For new copilot-cli
    if [[ "$COPILOT_CMD" = "copilot" ]]; then
        # Capture output for promise detection
        echo "$prompt" | $COPILOT_CMD --model "$COPILOT_MODEL" 2>&1
        return $?
    fi

    # For deprecated gh copilot
    echo "$prompt" | $COPILOT_CMD suggest 2>&1
    return $?
}

# Run copilot with ACP mode (experimental)
run_copilot_acp() {
    local prompt="$1"

    echo "Running Copilot ACP mode (experimental)..."

    if [[ "$COPILOT_CMD" = "copilot" ]]; then
        echo "Warning: ACP mode not yet implemented - falling back to CLI mode"
        run_copilot_cli "$prompt"
        return $?
    fi

    echo "Error: ACP mode requires new copilot-cli, not gh copilot" >&2
    return 1
}

# Run copilot with retry logic, capturing output
run_copilot_with_retry() {
    local prompt="$1"
    local max_retries=3
    local retry_delays=(5 15 30)
    local output=""

    for attempt in $(seq 0 $((max_retries - 1))); do
        # Choose mode based on configuration
        if [[ "$RALPH_COPILOT_USE_ACP" = "true" ]]; then
            output=$(run_copilot_acp "$prompt" | tee /dev/tty)
        else
            output=$(run_copilot_cli "$prompt" | tee /dev/tty)
        fi
        local exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            # Return output via global variable (bash limitation)
            COPILOT_OUTPUT="$output"
            return 0
        fi

        # Check for rate limit
        if [[ $attempt -lt $((max_retries - 1)) ]]; then
            local delay=${retry_delays[$attempt]}
            echo "Warning: Copilot call failed (attempt $((attempt + 1))/$max_retries)"
            echo "    Retrying in ${delay}s..."
            sleep $delay
        fi
    done

    echo "Error: Copilot call failed after $max_retries attempts" >&2
    return 1
}

# ============================================================================
# MAIN LOOP
# ============================================================================

ITERATION=$(cat "$ITERATION_FILE" 2>/dev/null || echo "0")
COPILOT_OUTPUT=""

echo "Ralph Copilot Backend v$SCRIPT_VERSION"
echo "UNTESTED - Requires Copilot License"
echo ""
echo "Task: $TASK_NAME"
echo "Task directory: $TASK_DIR"
echo "Model: $MODEL_DISPLAY"
echo "Copilot CLI: $COPILOT_CMD"
echo "ACP Mode: $RALPH_COPILOT_USE_ACP"
echo "Max iterations: $MAX_ITERATIONS"
echo "Stuck threshold: $STUCK_THRESHOLD"
echo "Completion promise: ${COMPLETION_PROMISE:-none}"
echo "Starting autonomous loop..."
echo ""
echo "Press Ctrl+C to stop at any time"
echo ""
sleep 2

while [[ $ITERATION -lt $MAX_ITERATIONS ]]; do
    ITERATION=$((ITERATION + 1))
    echo "$ITERATION" > "$ITERATION_FILE"

    echo ""
    echo "=================================================="
    echo "Task: $TASK_NAME | Iteration $ITERATION / $MAX_ITERATIONS"
    echo "Model: $MODEL_DISPLAY"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=================================================="
    echo ""

    # Update progress file
    update_progress $ITERATION

    # Check for stuck condition (hash-based)
    STUCK_STATUS=$(check_stuck_by_hash)
    if [[ "$STUCK_STATUS" = "STUCK" ]]; then
        echo ""
        echo "STUCK DETECTED!"
        echo "   No file changes detected for $STUCK_THRESHOLD iterations."
        echo ""

        # Add to guardrails if file exists
        if [[ -f "$GUARDRAILS_FILE" ]]; then
            echo "" >> "$GUARDRAILS_FILE"
            echo "### Sign: Stuck at iteration $ITERATION" >> "$GUARDRAILS_FILE"
            echo "- **Trigger**: Working on: $(get_next_criterion)" >> "$GUARDRAILS_FILE"
            echo "- **Instruction**: Manual intervention needed - no progress detected" >> "$GUARDRAILS_FILE"
            echo "- **Added after**: Iteration $ITERATION - stuck threshold reached" >> "$GUARDRAILS_FILE"
        fi

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] STUCK: No file changes for $STUCK_THRESHOLD iterations" >> "$ACTIVITY_LOG"
        echo "Stopping loop. Manual intervention required."
        break
    fi

    # Log to activity log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $ITERATION started (model: $COPILOT_MODEL)" >> "$ACTIVITY_LOG"

    # Log premium request
    log_premium_request $ITERATION "$COPILOT_MODEL" "$IS_PREMIUM"

    # Build and run prompt
    PROMPT=$(build_prompt $ITERATION)

    run_copilot_with_retry "$PROMPT"
    EXIT_CODE=$?

    if [[ $EXIT_CODE -ne 0 ]]; then
        echo ""
        echo "Warning: Iteration $ITERATION failed with exit code $EXIT_CODE"
        echo "Logged to $ACTIVITY_LOG"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $ITERATION failed (exit $EXIT_CODE)" >> "$ACTIVITY_LOG"

        # If ACP mode failed and fallback enabled, retry with CLI mode
        if [[ "$RALPH_COPILOT_USE_ACP" = "true" ]] && [[ "$RALPH_COPILOT_FALLBACK" = "true" ]]; then
            echo "Falling back to CLI mode..."
            RALPH_COPILOT_USE_ACP=false
            run_copilot_with_retry "$PROMPT"
        fi
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $ITERATION completed" >> "$ACTIVITY_LOG"

        # Check for completion promise
        if [[ -n "$COMPLETION_PROMISE" ]] && [[ -n "$COPILOT_OUTPUT" ]]; then
            PROMISE_STATUS=$(detect_promise "$COPILOT_OUTPUT" "$COMPLETION_PROMISE")
            if [[ "$PROMISE_STATUS" = "PROMISE_FULFILLED" ]]; then
                echo ""
                echo "COMPLETION PROMISE FULFILLED!"
                echo "   Detected: <promise>$COMPLETION_PROMISE</promise>"
                echo ""
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Promise fulfilled at iteration $ITERATION" >> "$ACTIVITY_LOG"
                break
            fi
        fi
    fi

    # Check if task is complete (all checkboxes checked)
    UNCHECKED=$(grep -c '\[ \]' "$TASK_FILE" 2>/dev/null || echo "0")
    CHECKED=$(grep -c '\[x\]' "$TASK_FILE" 2>/dev/null || echo "0")
    TOTAL=$((UNCHECKED + CHECKED))

    if [[ "$UNCHECKED" = "0" ]]; then
        echo ""
        echo "TASK COMPLETE! All criteria checked off."
        echo "Completed: $CHECKED / $TOTAL criteria"
        echo ""
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Task completed! $CHECKED/$TOTAL criteria" >> "$ACTIVITY_LOG"
        break
    fi

    echo ""
    echo "Progress: $CHECKED / $TOTAL criteria complete ($UNCHECKED remaining)"
    echo "Continuing to next iteration..."
    sleep 2
done

if [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
    echo ""
    echo "Warning: Max iterations ($MAX_ITERATIONS) reached"
    echo "Task may not be complete. Check $TASK_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Max iterations reached" >> "$ACTIVITY_LOG"
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "=================================================="
echo "     Ralph Copilot Loop Complete"
echo "=================================================="
echo ""
echo "Task: $TASK_NAME"
echo "Model used: $MODEL_DISPLAY"
echo "Total iterations: $ITERATION"

# Show premium request count
PREMIUM_COUNT=$(count_premium_requests)
echo "Premium requests this task: $PREMIUM_COUNT"

if [[ "$IS_PREMIUM" = "true" ]]; then
    echo "Note: Premium requests count against your Copilot quota"
fi

echo ""
echo "Review commits: git log --oneline --grep='ralph($TASK_NAME):'"
echo "Activity log: $ACTIVITY_LOG"
echo "Premium request log: $PREMIUM_LOG"
echo "Progress log: $PROGRESS_FILE"
echo ""

# ============================================================================
# TESTING NOTES (for corp MacBook validation)
# ============================================================================
#
# This script is UNTESTED and based on documentation research.
# To validate on corp MacBook with Copilot license:
#
# 1. Install copilot-cli: npm install -g @github/copilot
# 2. Authenticate: copilot /login
# 3. Test basic command: echo "Hello" | copilot
# 4. Test with simple task: ./ralph-copilot.sh test-task
# 5. Verify:
#    - Task criterion completed
#    - Progress updated
#    - Commits made correctly
#    - No errors in activity.log
#
# Known issues to watch for:
# - ACP mode may have bugs (#989)
# - Non-interactive context handling (#979)
# - Auto-compaction at token thresholds (#947)
#
# If ACP mode fails, set RALPH_COPILOT_USE_ACP=false to use CLI wrapping
# ============================================================================
