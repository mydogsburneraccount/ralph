#!/bin/bash
# Ralph Task Manager - Create, list, archive tasks

set -euo pipefail

WORKSPACE=$(pwd)
ACTIVE_DIR="$WORKSPACE/.ralph/active"
COMPLETED_DIR="$WORKSPACE/.ralph/completed"

function show_usage() {
    echo "Ralph Task Manager"
    echo ""
    echo "Usage:"
    echo "  $0 list                    - List all active tasks"
    echo "  $0 create <task-name>      - Create a new task"
    echo "  $0 archive <task-name>     - Archive a completed task"
    echo "  $0 status <task-name>      - Show task status"
    echo "  $0 resume <task-name>      - Resume a completed task"
    echo ""
}

function list_tasks() {
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           Active Ralph Tasks                       ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    if [ ! -d "$ACTIVE_DIR" ] || [ -z "$(ls -A $ACTIVE_DIR 2>/dev/null)" ]; then
        echo "No active tasks."
        return
    fi
    
    for task_dir in "$ACTIVE_DIR"/*; do
        [ -d "$task_dir" ] || continue
        
        task_name=$(basename "$task_dir")
        iter=$(cat "$task_dir/.iteration" 2>/dev/null || echo "0")
        unchecked=$(grep -c '\[ \]' "$task_dir/TASK.md" 2>/dev/null || echo "0")
        checked=$(grep -c '\[x\]' "$task_dir/TASK.md" 2>/dev/null || echo "0")
        total=$((unchecked + checked))
        
        if [ "$total" -gt 0 ]; then
            percent=$((checked * 100 / total))
        else
            percent=0
        fi
        
        echo "📋 $task_name"
        echo "   Iteration: $iter"
        echo "   Progress: $checked/$total ($percent%)"
        echo ""
    done
}

function create_task() {
    local task_name="$1"
    local task_dir="$ACTIVE_DIR/$task_name"
    
    if [ -d "$task_dir" ]; then
        echo "❌ Task already exists: $task_name"
        exit 1
    fi
    
    echo "Creating new task: $task_name"
    mkdir -p "$task_dir"
    
    # Create TASK.md template
    cat > "$task_dir/TASK.md" << 'EOF'
# Ralph Task: [Task Name]

## Task Overview

**Goal**: [Describe the goal]

**Context**: [Background information]

**Success Indicator**: [How to know when it's done]

---

## Success Criteria

### Phase 1: [Phase Name]

**Location: [Where work happens]**

- [ ] First criterion
- [ ] Second criterion

---
EOF
    
    # Initialize state files
    echo "0" > "$task_dir/.iteration"
    cat > "$task_dir/progress.md" << 'EOF'
# Progress Log

## Current Status

**Last Updated**: $(date +%Y-%m-%d)
**Iteration**: 0
**Task**: [Task Name]
**Status**: Not started

---

## Completed Work

(None yet)

---
EOF
    
    touch "$task_dir/activity.log"
    
    echo "✅ Task created: $task_dir"
    echo ""
    echo "Next steps:"
    echo "  1. Edit $task_dir/TASK.md"
    echo "  2. Run: ./ralph-autonomous.sh $task_name"
}

function archive_task() {
    local task_name="$1"
    local task_dir="$ACTIVE_DIR/$task_name"
    local archive_dir="$COMPLETED_DIR/${task_name}-$(date +%Y-%m-%d)"
    
    if [ ! -d "$task_dir" ]; then
        echo "❌ Task not found: $task_name"
        exit 1
    fi
    
    echo "Archiving task: $task_name"
    mkdir -p "$COMPLETED_DIR"
    mv "$task_dir" "$archive_dir"
    
    echo "✅ Task archived to: $archive_dir"
}

function show_status() {
    local task_name="$1"
    local task_dir="$ACTIVE_DIR/$task_name"
    
    if [ ! -d "$task_dir" ]; then
        echo "❌ Task not found: $task_name"
        exit 1
    fi
    
    echo "╔════════════════════════════════════════════════════╗"
    echo "║  Task Status: $task_name"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    iter=$(cat "$task_dir/.iteration" 2>/dev/null || echo "0")
    unchecked=$(grep -c '\[ \]' "$task_dir/TASK.md" 2>/dev/null || echo "0")
    checked=$(grep -c '\[x\]' "$task_dir/TASK.md" 2>/dev/null || echo "0")
    total=$((unchecked + checked))
    
    echo "Iteration: $iter"
    echo "Progress: $checked/$total criteria"
    echo "Remaining: $unchecked"
    echo ""
    echo "Latest progress:"
    tail -20 "$task_dir/progress.md"
}

function resume_task() {
    local task_name="$1"
    local completed_task=$(find "$COMPLETED_DIR" -maxdepth 1 -type d -name "${task_name}*" | head -1)
    
    if [ -z "$completed_task" ]; then
        echo "❌ Completed task not found: $task_name"
        exit 1
    fi
    
    local new_name="${task_name}-resumed"
    local task_dir="$ACTIVE_DIR/$new_name"
    
    echo "Resuming task: $(basename $completed_task) as $new_name"
    cp -r "$completed_task" "$task_dir"
    
    echo "✅ Task resumed: $task_dir"
}

# Main
case "${1:-}" in
    list)
        list_tasks
        ;;
    create)
        [ -z "${2:-}" ] && show_usage && exit 1
        create_task "$2"
        ;;
    archive)
        [ -z "${2:-}" ] && show_usage && exit 1
        archive_task "$2"
        ;;
    status)
        [ -z "${2:-}" ] && show_usage && exit 1
        show_status "$2"
        ;;
    resume)
        [ -z "${2:-}" ] && show_usage && exit 1
        resume_task "$2"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
