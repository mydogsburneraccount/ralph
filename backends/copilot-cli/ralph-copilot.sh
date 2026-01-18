#!/bin/bash
# ============================================================================
# Ralph Autonomous Loop - GitHub Copilot CLI Backend
# 
# UNTESTED - Requires active GitHub Copilot license to run
# 
# Run this for CLI-only autonomous development using corporate-approved
# GitHub Copilot instead of Aider + Anthropic API.
#
# Supports RALPH_COPILOT_MODEL env var: claude-sonnet|claude|gpt (default: claude-sonnet)
# ============================================================================

set -euo pipefail

WORKSPACE=$(pwd)
SCRIPT_VERSION="1.0.0-untested"

# ============================================================================
# MODEL CONFIGURATION
# ============================================================================

# Model selection via environment variable
# Based on copilot-cli research: Claude Sonnet 4.5 is default, Claude 4 and GPT-5 available
RALPH_COPILOT_MODEL="${RALPH_COPILOT_MODEL:-claude-sonnet}"
case "$RALPH_COPILOT_MODEL" in
    claude-sonnet|claude-sonnet-4.5)
        COPILOT_MODEL="claude-sonnet-4.5"
        IS_PREMIUM=true
        MODEL_DISPLAY="Claude Sonnet 4.5"
        ;;
    claude|claude-4)
        COPILOT_MODEL="claude-4"
        IS_PREMIUM=true
        MODEL_DISPLAY="Claude 4"
        ;;
    gpt|gpt-5)
        COPILOT_MODEL="gpt-5"
        IS_PREMIUM=true
        MODEL_DISPLAY="GPT-5"
        ;;
    gpt-4.1|gpt-5-mini|gpt-4o)
        # 0x multiplier models (free tier)
        COPILOT_MODEL="$RALPH_COPILOT_MODEL"
        IS_PREMIUM=false
        MODEL_DISPLAY="$RALPH_COPILOT_MODEL (free tier)"
        ;;
    *)
        echo "❌ Invalid RALPH_COPILOT_MODEL: $RALPH_COPILOT_MODEL"
        echo ""
        echo "Premium models (count against quota):"
        echo "  claude-sonnet  - Claude Sonnet 4.5 (default, best quality)"
        echo "  claude         - Claude 4"
        echo "  gpt            - GPT-5"
        echo ""
        echo "Free tier models (0x multiplier):"
        echo "  gpt-4.1, gpt-5-mini, gpt-4o"
        exit 1
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
# ARGUMENT PARSING
# ============================================================================

TASK_NAME="${1:-}"
if [ -z "$TASK_NAME" ]; then
    echo "╔════════════════════════════════════════════════════╗"
    echo "║ Ralph Copilot Backend v$SCRIPT_VERSION              "
    echo "║ UNTESTED - Requires active Copilot license         ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    echo "Usage: $0 <task-name>"
    echo ""
    echo "Environment variables:"
    echo "  RALPH_COPILOT_MODEL=claude-sonnet|claude|gpt (default: claude-sonnet)"
    echo "  RALPH_COPILOT_FALLBACK=true|false (default: false)"
    echo "  RALPH_COPILOT_AUTO_APPROVE=true|false (default: true)"
    echo "  RALPH_COPILOT_USE_ACP=true|false (default: false, experimental)"
    echo ""
    echo "Available tasks:"
    ls -1 "$WORKSPACE/.ralph/active/" 2>/dev/null || echo "  (no active tasks)"
    echo ""
    echo "Example: RALPH_COPILOT_MODEL=claude $0 my-task"
    exit 1
fi

# ============================================================================
# TASK DIRECTORY SETUP
# ============================================================================

if [ -d "$WORKSPACE/.ralph/active/$TASK_NAME" ]; then
    TASK_DIR="$WORKSPACE/.ralph/active/$TASK_NAME"
elif [ -d "$TASK_NAME" ]; then
    TASK_DIR="$TASK_NAME"
else
    echo "❌ Task not found: $TASK_NAME"
    echo ""
    echo "Available tasks:"
    ls -1 "$WORKSPACE/.ralph/active/" 2>/dev/null || echo "  (no active tasks)"
    exit 1
fi

TASK_FILE="$TASK_DIR/TASK.md"
ITERATION_FILE="$TASK_DIR/.iteration"
PROGRESS_FILE="$TASK_DIR/progress.md"
ACTIVITY_LOG="$TASK_DIR/activity.log"
PREMIUM_LOG="$TASK_DIR/premium_requests.log"
GUARDRAILS_FILE="$WORKSPACE/.ralph/guardrails.md"
MAX_ITERATIONS=20

# Stuck detection
STUCK_THRESHOLD=3
LAST_CRITERION_FILE="$TASK_DIR/.last_criterion"
STUCK_COUNT_FILE="$TASK_DIR/.stuck_count"

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

if [ ! -f "$TASK_FILE" ]; then
    echo "❌ TASK.md not found in $TASK_DIR"
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
        echo "⚠️  Using deprecated gh copilot extension"
        echo "   Consider installing: npm install -g @github/copilot"
        return 0
    fi
    
    echo "❌ Copilot CLI not found"
    echo ""
    echo "Install with one of:"
    echo "  npm install -g @github/copilot     # Recommended"
    echo "  brew install github/copilot/copilot"
    echo "  winget install GitHub.Copilot"
    echo ""
    echo "Or install gh extension (deprecated):"
    echo "  gh extension install github/gh-copilot"
    echo ""
    echo "Then authenticate:"
    echo "  copilot /login"
    exit 1
}

check_copilot_cli

# Check GitHub authentication
check_github_auth() {
    # For new copilot-cli, check if logged in
    if [ "$COPILOT_CMD" = "copilot" ]; then
        # Note: This check may need adjustment based on actual copilot-cli behavior
        # The copilot /login command handles auth
        echo "ℹ️  Using copilot-cli. If not authenticated, run: copilot /login"
        return 0
    fi
    
    # For gh copilot, check gh auth
    if ! gh auth status &> /dev/null; then
        echo "❌ Not authenticated with GitHub"
        echo ""
        echo "Authenticate with: gh auth login"
        echo "Then try again."
        exit 1
    fi
}

check_github_auth

# ============================================================================
# FILE INITIALIZATION
# ============================================================================

[ ! -f "$ITERATION_FILE" ] && echo "0" > "$ITERATION_FILE"
[ ! -f "$PROGRESS_FILE" ] && echo "# Progress Log" > "$PROGRESS_FILE"
[ ! -f "$ACTIVITY_LOG" ] && touch "$ACTIVITY_LOG"
[ ! -f "$PREMIUM_LOG" ] && echo "# Premium Request Tracking" > "$PREMIUM_LOG"
[ ! -f "$LAST_CRITERION_FILE" ] && echo "" > "$LAST_CRITERION_FILE"
[ ! -f "$STUCK_COUNT_FILE" ] && echo "0" > "$STUCK_COUNT_FILE"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Log premium request for quota tracking
log_premium_request() {
    local iteration=$1
    local model=$2
    local is_premium=$3
    
    if [ "$is_premium" = "true" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $iteration: model=$model PREMIUM" >> "$PREMIUM_LOG"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $iteration: model=$model (free tier)" >> "$PREMIUM_LOG"
    fi
}

# Count premium requests from log
count_premium_requests() {
    if [ -f "$PREMIUM_LOG" ]; then
        grep -c "PREMIUM" "$PREMIUM_LOG" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Get first unchecked criterion
get_next_criterion() {
    grep -m1 '\[ \]' "$TASK_FILE" 2>/dev/null | sed 's/.*\[ \]//' | xargs || echo ""
}

# Detect if stuck on same criterion
check_stuck() {
    local current_criterion
    current_criterion=$(get_next_criterion)
    local last_criterion
    last_criterion=$(cat "$LAST_CRITERION_FILE" 2>/dev/null || echo "")
    
    if [ "$current_criterion" = "$last_criterion" ] && [ -n "$current_criterion" ]; then
        local stuck_count
        stuck_count=$(cat "$STUCK_COUNT_FILE" 2>/dev/null || echo "0")
        stuck_count=$((stuck_count + 1))
        echo "$stuck_count" > "$STUCK_COUNT_FILE"
        
        if [ $stuck_count -ge $STUCK_THRESHOLD ]; then
            echo "STUCK"
            return
        fi
    else
        # New criterion, reset counter
        echo "0" > "$STUCK_COUNT_FILE"
    fi
    
    echo "$current_criterion" > "$LAST_CRITERION_FILE"
    echo "OK"
}

# Build prompt for Copilot
build_prompt() {
    local iteration=$1
    local next_criterion
    next_criterion=$(get_next_criterion)
    
    cat << EOF
Start Ralph iteration $iteration for task: $TASK_NAME

Follow the Ralph protocol:

1. Read $TASK_FILE for task definition
2. Read $GUARDRAILS_FILE for lessons learned
3. Read $PROGRESS_FILE to see current state
4. Work on next unchecked [ ] criterion
5. Commit frequently: git commit -m 'ralph($TASK_NAME): [criterion] - change'
6. Update $PROGRESS_FILE when done
7. Check off criterion in $TASK_FILE
8. Commit state files

Current focus: $next_criterion

Task directory: $TASK_DIR
EOF
}

# Run copilot with CLI wrapping (fallback mode)
run_copilot_cli() {
    local prompt="$1"
    
    echo "Running Copilot CLI (standard mode)..."
    
    # For new copilot-cli
    if [ "$COPILOT_CMD" = "copilot" ]; then
        # Use --model flag if available, otherwise default
        # Note: Actual flag syntax may vary - this is based on research
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
    
    # ACP mode uses structured JSON communication
    # Note: This is based on research - actual implementation may need adjustment
    # See: https://github.com/github/copilot-cli/issues?q=acp
    
    if [ "$COPILOT_CMD" = "copilot" ]; then
        # Start ACP session and send message
        # This is a placeholder - actual ACP protocol may differ
        echo "⚠️  ACP mode not yet implemented - falling back to CLI mode"
        run_copilot_cli "$prompt"
        return $?
    fi
    
    echo "❌ ACP mode requires new copilot-cli, not gh copilot"
    return 1
}

# Run copilot with retry logic
run_copilot_with_retry() {
    local prompt="$1"
    local max_retries=3
    local retry_delays=(5 15 30)
    
    for attempt in $(seq 0 $((max_retries - 1))); do
        # Choose mode based on configuration
        if [ "$RALPH_COPILOT_USE_ACP" = "true" ]; then
            run_copilot_acp "$prompt"
        else
            run_copilot_cli "$prompt"
        fi
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            return 0
        fi
        
        # Check for rate limit
        if [ $attempt -lt $((max_retries - 1)) ]; then
            local delay=${retry_delays[$attempt]}
            echo "⚠️  Copilot call failed (attempt $((attempt + 1))/$max_retries)"
            echo "    Retrying in ${delay}s..."
            sleep $delay
        fi
    done
    
    echo "❌ Copilot call failed after $max_retries attempts"
    return 1
}

# ============================================================================
# MAIN LOOP
# ============================================================================

ITERATION=$(cat "$ITERATION_FILE" 2>/dev/null || echo "0")

echo "╔════════════════════════════════════════════════════╗"
echo "║  Ralph Wiggum - COPILOT BACKEND (Corporate)        ║"
echo "║  ⚠️  UNTESTED - Requires Copilot License            ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Task: $TASK_NAME"
echo "Task directory: $TASK_DIR"
echo "Model: $MODEL_DISPLAY"
echo "Copilot CLI: $COPILOT_CMD"
echo "ACP Mode: $RALPH_COPILOT_USE_ACP"
echo "Starting autonomous loop..."
echo "Max iterations: $MAX_ITERATIONS"
echo "Current iteration: $ITERATION"
echo ""
echo "Press Ctrl+C to stop at any time"
echo ""
sleep 2

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    echo "$ITERATION" > "$ITERATION_FILE"
    
    echo ""
    echo "═══════════════════════════════════════════════════"
    echo "Task: $TASK_NAME | Iteration $ITERATION / $MAX_ITERATIONS | Model: $MODEL_DISPLAY"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "═══════════════════════════════════════════════════"
    echo ""
    
    # Check for stuck condition
    STUCK_STATUS=$(check_stuck)
    if [ "$STUCK_STATUS" = "STUCK" ]; then
        echo ""
        echo "🚨 STUCK DETECTED!"
        echo "   Same criterion attempted $STUCK_THRESHOLD times without progress."
        echo "   Criterion: $(get_next_criterion)"
        echo ""
        echo "Adding to guardrails and stopping..."
        
        # Add to guardrails
        echo "" >> "$GUARDRAILS_FILE"
        echo "### Sign: Criterion stuck at iteration $ITERATION" >> "$GUARDRAILS_FILE"
        echo "- **Trigger**: Working on: $(get_next_criterion)" >> "$GUARDRAILS_FILE"
        echo "- **Instruction**: Manual intervention needed - criterion could not be completed" >> "$GUARDRAILS_FILE"
        echo "- **Added after**: Iteration $ITERATION - stuck threshold reached" >> "$GUARDRAILS_FILE"
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] STUCK on criterion: $(get_next_criterion)" >> "$ACTIVITY_LOG"
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
    
    if [ $EXIT_CODE -ne 0 ]; then
        echo ""
        echo "⚠️  Iteration $ITERATION failed with exit code $EXIT_CODE"
        echo "Logged to $ACTIVITY_LOG"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $ITERATION failed (exit $EXIT_CODE)" >> "$ACTIVITY_LOG"
        
        # If ACP mode failed and fallback enabled, retry with CLI mode
        if [ "$RALPH_COPILOT_USE_ACP" = "true" ] && [ "$RALPH_COPILOT_FALLBACK" = "true" ]; then
            echo "🔄 Falling back to CLI mode..."
            RALPH_COPILOT_USE_ACP=false
            run_copilot_with_retry "$PROMPT"
        fi
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $ITERATION completed" >> "$ACTIVITY_LOG"
    fi
    
    # Check if task is complete
    UNCHECKED=$(grep -c '\[ \]' "$TASK_FILE" || echo "0")
    CHECKED=$(grep -c '\[x\]' "$TASK_FILE" || echo "0")
    TOTAL=$((UNCHECKED + CHECKED))
    
    if [ "$UNCHECKED" = "0" ]; then
        echo ""
        echo "✅ TASK COMPLETE! All criteria checked off."
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

if [ $ITERATION -ge $MAX_ITERATIONS ]; then
    echo ""
    echo "⚠️  Max iterations ($MAX_ITERATIONS) reached"
    echo "Task may not be complete. Check $TASK_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Max iterations reached" >> "$ACTIVITY_LOG"
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Copilot Loop Complete                    ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Task: $TASK_NAME"
echo "Model used: $MODEL_DISPLAY"
echo "Total iterations: $ITERATION"

# Show premium request count
PREMIUM_COUNT=$(count_premium_requests)
echo "Premium requests this task: $PREMIUM_COUNT"

if [ "$IS_PREMIUM" = "true" ]; then
    echo "⚠️  Premium requests count against your Copilot quota"
fi

echo ""
echo "Review commits: git log --oneline --grep='ralph($TASK_NAME):'"
echo "Activity log: $ACTIVITY_LOG"
echo "Premium request log: $PREMIUM_LOG"
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
