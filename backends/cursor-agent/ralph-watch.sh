#!/bin/bash
# Ralph Watcher - Monitor Ralph's progress without interfering
# Run this in a SEPARATE terminal while Ralph is working

WORKSPACE=$(pwd)
TASK_FILE="$WORKSPACE/RALPH_TASK.md"
PROGRESS_FILE="$WORKSPACE/.ralph/progress.md"
ITERATION_FILE="$WORKSPACE/.ralph/.iteration"
ERRORS_FILE="$WORKSPACE/.ralph/errors.log"

clear
echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Watcher - Live Progress Monitor         ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Monitoring workspace: $WORKSPACE"
echo "Press Ctrl+C to exit"
echo ""

# Function to show status
show_status() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║     Ralph Progress - $(date '+%H:%M:%S')                    ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    # Iteration count
    if [ -f "$ITERATION_FILE" ]; then
        ITERATION=$(cat "$ITERATION_FILE")
        echo "Current Iteration: $ITERATION"
    else
        echo "Current Iteration: Not started"
    fi
    
    # Task progress
    if [ -f "$TASK_FILE" ]; then
        UNCHECKED=$(grep -c '\[ \]' "$TASK_FILE" || echo "0")
        CHECKED=$(grep -c '\[x\]' "$TASK_FILE" || echo "0")
        TOTAL=$((UNCHECKED + CHECKED))
        PERCENT=$((CHECKED * 100 / TOTAL))
        
        echo "Task Progress: $CHECKED / $TOTAL criteria complete ($PERCENT%)"
        
        # Show next unchecked criterion (what Ralph should work on next)
        NEXT_CRITERION=$(grep -m 1 '\[ \]' "$TASK_FILE" | sed 's/^.*\[ \] //')
        if [ -n "$NEXT_CRITERION" ]; then
            echo "Next up: ${NEXT_CRITERION:0:60}..."
        fi
        echo ""
        
        # Simple progress bar
        BAR_LENGTH=50
        FILLED=$((PERCENT * BAR_LENGTH / 100))
        BAR=$(printf "█%.0s" $(seq 1 $FILLED))
        EMPTY=$(printf "░%.0s" $(seq 1 $((BAR_LENGTH - FILLED))))
        echo "[$BAR$EMPTY] $PERCENT%"
    fi
    
    echo ""
    echo "─────────────────────────────────────────────────────"
    echo "Recent Commits (last 5):"
    echo "─────────────────────────────────────────────────────"
    git log --oneline --grep="ralph:" -5 2>/dev/null || echo "No Ralph commits yet"
    
    echo ""
    echo "─────────────────────────────────────────────────────"
    echo "Current Phase (from progress.md):"
    echo "─────────────────────────────────────────────────────"
    if [ -f "$PROGRESS_FILE" ]; then
        # Show the most recent completed phase (last heading with checkmark)
        grep -A 3 "^### Phase.*✅" "$PROGRESS_FILE" | tail -8 || echo "No phases completed yet"
    else
        echo "No progress file yet"
    fi
    
    echo ""
    echo "─────────────────────────────────────────────────────"
    echo "Recent Activity (files changed in last 5 min):"
    echo "─────────────────────────────────────────────────────"
    find . -type f -mmin -5 -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | head -10 || echo "No recent file changes"
    
    echo ""
    echo "─────────────────────────────────────────────────────"
    echo "Errors (last 3):"
    echo "─────────────────────────────────────────────────────"
    if [ -f "$ERRORS_FILE" ]; then
        tail -3 "$ERRORS_FILE"
    else
        echo "No errors logged"
    fi
    
    echo ""
    echo "Refreshing in 10 seconds... (Ctrl+C to exit)"
}

# Main watch loop
while true; do
    show_status
    sleep 10
done
