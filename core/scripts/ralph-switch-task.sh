#!/bin/bash
# Switch Ralph Tasks - Proper Archive Workflow
# This script archives the current task WITH state files and activates a new one

set -euo pipefail

WORKSPACE="/mnt/c/Users/Ethan/Code/cursor_local_workspace"
TASKS_DIR="$WORKSPACE/.ralph/tasks"
RALPH_DIR="$WORKSPACE/.ralph"

echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Task Switcher                            ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

# Check current task
if [ ! -f "$WORKSPACE/RALPH_TASK.md" ]; then
    echo "❌ No active RALPH_TASK.md found"
    exit 1
fi

# Show current task
echo "Current active task:"
head -3 "$WORKSPACE/RALPH_TASK.md" | grep "^#" | head -1
echo ""

# Count progress
UNCHECKED=$(grep -c '\[ \]' "$WORKSPACE/RALPH_TASK.md" || echo "0")
CHECKED=$(grep -c '\[x\]' "$WORKSPACE/RALPH_TASK.md" || echo "0")
ITERATION=$(cat "$RALPH_DIR/.iteration" 2>/dev/null || echo "0")
echo "Progress: $CHECKED / $((UNCHECKED + CHECKED)) criteria complete"
echo "Iteration: $ITERATION"
echo ""

# Ask for archive name
echo "Archive current task as? (e.g., 'docker-optimization-2026-01-16')"
echo -n "> "
read ARCHIVE_NAME

if [ -z "$ARCHIVE_NAME" ]; then
    echo "❌ Archive name required"
    exit 1
fi

# Create archive directory for this task
TASK_ARCHIVE_DIR="$TASKS_DIR/$ARCHIVE_NAME"
mkdir -p "$TASK_ARCHIVE_DIR"

# Archive current task file
mv "$WORKSPACE/RALPH_TASK.md" "$TASK_ARCHIVE_DIR/RALPH_TASK.md"
echo "✅ Archived task to: .ralph/tasks/${ARCHIVE_NAME}/RALPH_TASK.md"

# Archive state files
if [ -f "$RALPH_DIR/progress.md" ]; then
    cp "$RALPH_DIR/progress.md" "$TASK_ARCHIVE_DIR/progress.md"
    echo "✅ Archived progress.md"
fi

if [ -f "$RALPH_DIR/guardrails.md" ]; then
    cp "$RALPH_DIR/guardrails.md" "$TASK_ARCHIVE_DIR/guardrails.md"
    echo "✅ Archived guardrails.md"
fi

if [ -f "$RALPH_DIR/.iteration" ]; then
    cp "$RALPH_DIR/.iteration" "$TASK_ARCHIVE_DIR/iteration.txt"
    echo "✅ Archived iteration count ($ITERATION)"
fi

if [ -f "$RALPH_DIR/errors.log" ]; then
    cp "$RALPH_DIR/errors.log" "$TASK_ARCHIVE_DIR/errors.log"
    echo "✅ Archived errors.log"
fi

echo ""

# Show available tasks to activate
echo "Available tasks to activate:"
ls -1 "$WORKSPACE"/RALPH_TASK_*.md 2>/dev/null | sed 's|.*/||' || echo "  (none found)"
echo ""

# Ask for new task
echo "Activate which task? (enter filename without path, e.g., 'RALPH_TASK_CURSORRULES_REFACTOR.md')"
echo -n "> "
read NEW_TASK

if [ -z "$NEW_TASK" ]; then
    echo "❌ No task specified"
    echo "⚠️  Current task has been archived but no new task activated"
    exit 1
fi

# Check new task exists
if [ ! -f "$WORKSPACE/$NEW_TASK" ]; then
    echo "❌ Task not found: $NEW_TASK"
    echo "⚠️  Current task has been archived but no new task activated"
    exit 1
fi

# Activate new task
cp "$WORKSPACE/$NEW_TASK" "$WORKSPACE/RALPH_TASK.md"
echo "✅ Activated: $NEW_TASK → RALPH_TASK.md"

# Reset state files for new task
echo "0" > "$RALPH_DIR/.iteration"
echo "✅ Reset iteration counter to 0"

# Reset progress.md
cat > "$RALPH_DIR/progress.md" <<'EOF'
# Ralph Progress Log

> **Auto-updated by the agent after each iteration**
> 
> This file tracks what has been accomplished. Each iteration reads this first
> to understand what's already done, then continues from there.

---

## Current Status

**Last Updated**: (Not yet started)
**Iteration**: 0
**Task**: (Starting new task)

---

## Completed Work

(No work completed yet - this is a fresh start)

---
EOF
echo "✅ Reset progress.md"

# Keep guardrails.md (lessons learned carry forward)
echo "ℹ️  Kept guardrails.md (lessons learned persist across tasks)"

# Clear errors.log
> "$RALPH_DIR/errors.log"
echo "✅ Cleared errors.log"

echo ""

# Show new task info
echo "New active task:"
head -3 "$WORKSPACE/RALPH_TASK.md" | grep "^#" | head -1
TOTAL_NEW=$(grep -c '\[ \]' "$WORKSPACE/RALPH_TASK.md" || echo "0")
echo "Total criteria: $TOTAL_NEW"
echo ""

echo "╔════════════════════════════════════════════════════╗"
echo "║     Task Switch Complete                           ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Ready to run: ./.cursor/ralph-scripts/ralph-autonomous.sh"
echo ""
