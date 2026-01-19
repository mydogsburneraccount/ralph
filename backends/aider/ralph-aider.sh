#!/bin/bash
# Ralph Autonomous Loop - Aider Backend
# Run this for CLI-only autonomous development (no Cursor required)
# Supports RALPH_MODEL env var: haiku|sonnet|opus (default: sonnet)

set -euo pipefail

WORKSPACE=$(pwd)

# Model selection via environment variable
RALPH_MODEL="${RALPH_MODEL:-sonnet}"
case "$RALPH_MODEL" in
    haiku)
        AIDER_MODEL="claude-3-5-haiku-20241022"
        INPUT_COST_PER_MILLION=1    # $1 per 1M input tokens
        OUTPUT_COST_PER_MILLION=5   # $5 per 1M output tokens
        ;;
    sonnet)
        AIDER_MODEL="claude-sonnet-4-20250514"
        INPUT_COST_PER_MILLION=3    # $3 per 1M input tokens
        OUTPUT_COST_PER_MILLION=15  # $15 per 1M output tokens
        ;;
    opus)
        AIDER_MODEL="claude-3-opus-20240229"
        INPUT_COST_PER_MILLION=15   # $15 per 1M input tokens
        OUTPUT_COST_PER_MILLION=75  # $75 per 1M output tokens
        ;;
    *)
        echo "❌ Invalid RALPH_MODEL: $RALPH_MODEL"
        echo "Valid options: haiku, sonnet, opus"
        exit 1
        ;;
esac

# Parse arguments
TASK_NAME="${1:-}"
if [ -z "$TASK_NAME" ]; then
    echo "Usage: $0 <task-name>"
    echo ""
    echo "Environment variables:"
    echo "  RALPH_MODEL=haiku|sonnet|opus (default: sonnet)"
    echo "  ANTHROPIC_API_KEY=sk-ant-... (required)"
    echo ""
    echo "Available tasks:"
    ls -1 "$WORKSPACE/.ralph/active/" 2>/dev/null || echo "  (no active tasks)"
    echo ""
    echo "Example: RALPH_MODEL=haiku $0 flippanet-security"
    exit 1
fi

# Determine task directory
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
COST_LOG="$TASK_DIR/costs.log"
GUARDRAILS_FILE="$WORKSPACE/.ralph/guardrails.md"
MAX_ITERATIONS=20
CHARS_PER_TOKEN=4  # Rough estimate: 4 characters per token

# Check prerequisites
if [ ! -f "$TASK_FILE" ]; then
    echo "❌ TASK.md not found in $TASK_DIR"
    exit 1
fi

# Check for Anthropic API key
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "❌ ANTHROPIC_API_KEY not set"
    echo ""
    echo "Set it with: export ANTHROPIC_API_KEY='sk-ant-api03-...'"
    echo "Get a key from: https://console.anthropic.com/"
    exit 1
fi

# Check for aider command
if ! command -v aider &> /dev/null; then
    echo "❌ aider not found"
    echo ""
    echo "Install with: pip install aider-chat"
    echo "Or: pipx install aider-chat"
    exit 1
fi

# Initialize files if they don't exist
[ ! -f "$ITERATION_FILE" ] && echo "0" > "$ITERATION_FILE"
[ ! -f "$PROGRESS_FILE" ] && echo "# Progress Log" > "$PROGRESS_FILE"
[ ! -f "$ACTIVITY_LOG" ] && touch "$ACTIVITY_LOG"
[ ! -f "$COST_LOG" ] && echo "# Cost Tracking Log" > "$COST_LOG"

# Function: Estimate tokens from character count
estimate_tokens() {
    local char_count=$1
    # Ensure numeric value
    char_count=$(echo "$char_count" | tr -d '[:space:]')
    char_count=${char_count:-0}
    echo $(( char_count / CHARS_PER_TOKEN ))
}

# Function: Estimate cost in dollars (returns cents for precision)
estimate_cost_cents() {
    local input_tokens=$1
    local output_tokens=${2:-$input_tokens}  # Assume output ~= input if not specified

    # Ensure numeric values
    input_tokens=$(echo "$input_tokens" | tr -d '[:space:]')
    output_tokens=$(echo "$output_tokens" | tr -d '[:space:]')
    input_tokens=${input_tokens:-0}
    output_tokens=${output_tokens:-0}

    # Calculate cost in cents (multiply by 100 to avoid floating point)
    # Formula: (tokens / 1000000) * cost_per_million * 100 cents
    local input_cost=$(( input_tokens * INPUT_COST_PER_MILLION / 10000 ))
    local output_cost=$(( output_tokens * OUTPUT_COST_PER_MILLION / 10000 ))

    echo $(( input_cost + output_cost ))
}

# Function: Format cents as dollars
format_cost() {
    local cents=$1
    # Ensure numeric value
    cents=$(echo "$cents" | tr -d '[:space:]')
    cents=${cents:-0}
    local dollars=$(( cents / 100 ))
    local remainder=$(( cents % 100 ))
    printf "%d.%02d" $dollars $remainder
}

# Function: Log iteration cost
log_iteration_cost() {
    local iteration=$1
    local prompt_chars=$2
    local tokens=$(estimate_tokens $prompt_chars)
    local cost_cents=$(estimate_cost_cents $tokens $tokens)
    local cost_formatted=$(format_cost $cost_cents)

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $iteration: ~$tokens tokens, ~\$$cost_formatted ($RALPH_MODEL)" >> "$COST_LOG"
}

# Function: Calculate total cost from log
calculate_total_cost() {
    if [ -f "$COST_LOG" ]; then
        local total_cents=0
        # Strip CRLF when reading log file
        while IFS= read -r line || [ -n "$line" ]; do
            # Remove any carriage returns
            line=$(echo "$line" | tr -d '\r')
            # Extract cost value from line like "~$0.05"
            if [[ $line =~ \~\$([0-9]+)\.([0-9]+) ]]; then
                local dollars="${BASH_REMATCH[1]}"
                local cents="${BASH_REMATCH[2]}"
                # Clean extracted values
                dollars=$(echo "$dollars" | tr -d '[:space:]')
                cents=$(echo "$cents" | tr -d '[:space:]')
                dollars=${dollars:-0}
                cents=${cents:-0}
                total_cents=$(( total_cents + dollars * 100 + cents ))
            fi
        done < "$COST_LOG"
        format_cost $total_cents
    else
        echo "0.00"
    fi
}

# Get current iteration (strip CRLF for Windows line endings)
ITERATION=$(tr -d '\r' < "$ITERATION_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
ITERATION=${ITERATION:-0}

echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Wiggum - AIDER BACKEND (CLI-Only)        ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Task: $TASK_NAME"
echo "Task directory: $TASK_DIR"
echo "Model: $AIDER_MODEL ($RALPH_MODEL)"
echo "Starting autonomous loop..."
echo "Max iterations: $MAX_ITERATIONS"
echo "Current iteration: $ITERATION"
echo ""
echo "Press Ctrl+C to stop at any time"
echo ""
sleep 2

# Main autonomous loop
while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    echo "$ITERATION" > "$ITERATION_FILE"

    echo ""
    echo "═══════════════════════════════════════════════════"
    echo "Task: $TASK_NAME | Iteration $ITERATION / $MAX_ITERATIONS | Model: $RALPH_MODEL"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "═══════════════════════════════════════════════════"
    echo ""

    # Log to activity log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $ITERATION started (model: $RALPH_MODEL)" >> "$ACTIVITY_LOG"

    # Build the prompt (and track its size for cost estimation)
    PROMPT="Start Ralph iteration $ITERATION for task: $TASK_NAME

Follow the Ralph protocol:

1. Read $TASK_FILE for task definition
2. Read $GUARDRAILS_FILE for lessons learned
3. Read $PROGRESS_FILE to see current state
4. Work on next unchecked [ ] criterion
5. Commit frequently: git commit -m 'ralph($TASK_NAME): [criterion] - change'
6. Update $PROGRESS_FILE when done
7. Check off criterion in $TASK_FILE
8. Commit state files

Current focus: First unchecked criterion in $TASK_FILE

Task directory: $TASK_DIR"

    # Run aider with:
    #   --model: specified Claude model
    #   --yes-always: auto-accept all file changes (autonomous mode)
    #   --no-auto-commits: let Ralph protocol handle commits
    #   --message: the prompt
    aider --model "$AIDER_MODEL" --yes-always --no-auto-commits --message "$PROMPT"
    EXIT_CODE=$?

    # Log estimated cost for this iteration
    PROMPT_LENGTH=${#PROMPT}
    log_iteration_cost $ITERATION $PROMPT_LENGTH

    if [ $EXIT_CODE -ne 0 ]; then
        echo ""
        echo "⚠️  Iteration $ITERATION failed with exit code $EXIT_CODE"
        echo "Logged to $ACTIVITY_LOG"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $ITERATION failed (exit $EXIT_CODE)" >> "$ACTIVITY_LOG"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $ITERATION completed" >> "$ACTIVITY_LOG"
    fi

    # Check if task is complete (no unchecked boxes)
    # Strip CRLF to handle Windows line endings
    UNCHECKED=$(tr -d '\r' < "$TASK_FILE" | grep -c '\[ \]' || echo "0")
    CHECKED=$(tr -d '\r' < "$TASK_FILE" | grep -c '\[x\]' || echo "0")
    UNCHECKED=$(echo "$UNCHECKED" | tr -d '[:space:]')
    CHECKED=$(echo "$CHECKED" | tr -d '[:space:]')
    UNCHECKED=${UNCHECKED:-0}
    CHECKED=${CHECKED:-0}
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

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Aider Loop Complete                      ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Task: $TASK_NAME"
echo "Model used: $AIDER_MODEL ($RALPH_MODEL)"
echo "Total iterations: $ITERATION"

# Show cost summary
TOTAL_COST=$(calculate_total_cost)
echo "Estimated total cost: ~\$$TOTAL_COST"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Total estimated cost: ~\$$TOTAL_COST" >> "$COST_LOG"

echo ""
echo "Review commits: git log --oneline --grep='ralph($TASK_NAME):'"
echo "Activity log: $ACTIVITY_LOG"
echo "Cost log: $COST_LOG"
echo ""
