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
    echo "  $0 validate [task-name]    - Validate task structure (all if no name)"
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
        iter=$(cat "$task_dir/.iteration" 2>/dev/null | tr -d '\r' || echo "0")
        
        # Count checkboxes - strip CRLF to avoid arithmetic errors
        # Use tr -d '\r' to handle Windows line endings in TASK.md files
        unchecked=$(tr -d '\r' < "$task_dir/TASK.md" 2>/dev/null | grep -c '\- \[ \]' || echo "0")
        checked=$(tr -d '\r' < "$task_dir/TASK.md" 2>/dev/null | grep -c '\- \[x\]' || echo "0")
        
        # Ensure variables are numeric (strip any remaining whitespace)
        unchecked=$(echo "$unchecked" | tr -d '[:space:]')
        checked=$(echo "$checked" | tr -d '[:space:]')
        unchecked=${unchecked:-0}
        checked=${checked:-0}
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
    
    # Strip CRLF to handle Windows line endings
    # Check if .iteration file exists before reading
    if [ -f "$task_dir/.iteration" ]; then
        iter=$(tr -d '\r' < "$task_dir/.iteration" | tr -d '[:space:]')
    else
        iter="0"
    fi
    iter=${iter:-0}
    unchecked=$(tr -d '\r' < "$task_dir/TASK.md" 2>/dev/null | grep -c '\[ \]' || echo "0")
    checked=$(tr -d '\r' < "$task_dir/TASK.md" 2>/dev/null | grep -c '\[x\]' || echo "0")
    unchecked=$(echo "$unchecked" | tr -d '[:space:]')
    checked=$(echo "$checked" | tr -d '[:space:]')
    unchecked=${unchecked:-0}
    checked=${checked:-0}
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

function validate_task() {
    local task_name="$1"
    local task_dir="$ACTIVE_DIR/$task_name"
    local guardrails_file="$WORKSPACE/.ralph/guardrails.md"
    local errors=0
    local warnings=0
    
    if [ ! -d "$task_dir" ]; then
        echo "❌ Task not found: $task_name"
        exit 1
    fi
    
    echo "╔════════════════════════════════════════════════════╗"
    echo "║  Validating Task: $task_name"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    # 1. Check TASK.md exists
    if [ ! -f "$task_dir/TASK.md" ]; then
        echo "  ❌ TASK.md not found"
        errors=$((errors + 1))
    else
        echo "  ✓ TASK.md exists"
        
        # 2. Check TASK.md has criteria (checkboxes)
        local unchecked checked total
        unchecked=$(tr -d '\r' < "$task_dir/TASK.md" | grep -c '\[ \]' || echo "0")
        checked=$(tr -d '\r' < "$task_dir/TASK.md" | grep -c '\[x\]' || echo "0")
        unchecked=$(echo "$unchecked" | tr -d '[:space:]')
        checked=$(echo "$checked" | tr -d '[:space:]')
        total=$((unchecked + checked))
        
        if [ "$total" -eq 0 ]; then
            # Check for promise marker as alternative
            local has_promise
            has_promise=$(tr -d '\r' < "$task_dir/TASK.md" | grep -c '<promise>' || echo "0")
            has_promise=$(echo "$has_promise" | tr -d '[:space:]')
            has_promise=${has_promise:-0}
            if [ "$has_promise" -eq 0 ]; then
                echo "  ❌ TASK.md has no criteria (checkboxes or promise marker)"
                echo "     Add criteria like: - [ ] First thing to do"
                echo "     Or add: <promise>INCOMPLETE</promise>"
                errors=$((errors + 1))
            else
                echo "  ✓ TASK.md has promise marker (alternative completion method)"
            fi
        else
            echo "  ✓ TASK.md has $total criteria ($checked done, $unchecked remaining)"
        fi
        
        # 3. Check TASK.md has a title
        local has_title
        has_title=$(tr -d '\r' < "$task_dir/TASK.md" | grep -c '^# ' || echo "0")
        has_title=$(echo "$has_title" | tr -d '[:space:]')
        has_title=${has_title:-0}
        if [ "$has_title" -eq 0 ]; then
            echo "  ⚠️  TASK.md has no title (# heading)"
            warnings=$((warnings + 1))
        else
            echo "  ✓ TASK.md has title"
        fi
        
        # 4. Check for Phase 0 evidence (recommended)
        local has_phase0
        has_phase0=$(tr -d '\r' < "$task_dir/TASK.md" | grep -ci 'phase.0\|pre.*flight\|pre.*work' || echo "0")
        has_phase0=$(echo "$has_phase0" | tr -d '[:space:]')
        has_phase0=${has_phase0:-0}
        if [ "$has_phase0" -eq 0 ]; then
            echo "  ⚠️  TASK.md may be missing Phase 0 checkpoint"
            warnings=$((warnings + 1))
        fi
    fi
    
    # 5. Check progress.md exists
    if [ ! -f "$task_dir/progress.md" ]; then
        echo "  ⚠️  progress.md not found (will be created on first run)"
        warnings=$((warnings + 1))
    else
        echo "  ✓ progress.md exists"
        
        # Check if progress.md has Phase 0 evidence
        local progress_has_phase0
        progress_has_phase0=$(tr -d '\r' < "$task_dir/progress.md" | grep -ci 'phase.0\|rules.read\|\.cursorrules' || echo "0")
        progress_has_phase0=$(echo "$progress_has_phase0" | tr -d '[:space:]')
        progress_has_phase0=${progress_has_phase0:-0}
        if [ "$progress_has_phase0" -gt 0 ]; then
            echo "  ✓ progress.md contains Phase 0 evidence"
        fi
    fi
    
    # 6. Check .iteration file
    if [ ! -f "$task_dir/.iteration" ]; then
        echo "  ⚠️  .iteration not found (will be created on first run)"
        warnings=$((warnings + 1))
    else
        local iter
        iter=$(tr -d '\r' < "$task_dir/.iteration" | tr -d '[:space:]')
        iter=${iter:-0}
        echo "  ✓ .iteration exists (current: $iter)"
    fi
    
    # 7. Check guardrails.md at workspace level
    if [ ! -f "$guardrails_file" ]; then
        echo "  ⚠️  guardrails.md not found at workspace level"
        warnings=$((warnings + 1))
    else
        echo "  ✓ guardrails.md exists"
    fi
    
    echo ""
    echo "─────────────────────────────────────────────────────"
    echo "Summary: $errors error(s), $warnings warning(s)"
    echo "─────────────────────────────────────────────────────"
    
    if [ $errors -gt 0 ]; then
        echo ""
        echo "❌ Validation FAILED - fix errors before running Ralph"
        return 1
    elif [ $warnings -gt 0 ]; then
        echo ""
        echo "⚠️  Validation passed with warnings"
        return 0
    else
        echo ""
        echo "✓ Validation PASSED"
        return 0
    fi
}

function validate_all_tasks() {
    echo "╔════════════════════════════════════════════════════╗"
    echo "║     Validating All Active Tasks                    ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    local total_errors=0
    local total_warnings=0
    local task_count=0
    
    for task_dir in "$ACTIVE_DIR"/*; do
        [ -d "$task_dir" ] || continue
        task_count=$((task_count + 1))
        
        local task_name=$(basename "$task_dir")
        echo "─────────────────────────────────────────────────────"
        echo "Task: $task_name"
        echo "─────────────────────────────────────────────────────"
        
        # Quick validation
        local errors=0
        local warnings=0
        
        if [ ! -f "$task_dir/TASK.md" ]; then
            echo "  ❌ Missing TASK.md"
            errors=$((errors + 1))
        else
            local checkbox_count
            checkbox_count=$(tr -d '\r' < "$task_dir/TASK.md" | grep -cE '\[ \]|\[x\]' || echo "0")
            checkbox_count=$(echo "$checkbox_count" | tr -d '[:space:]')
            
            if [ "$checkbox_count" -eq 0 ]; then
                local has_promise
                has_promise=$(tr -d '\r' < "$task_dir/TASK.md" | grep -c '<promise>' || echo "0")
                if [ "$has_promise" -eq 0 ]; then
                    echo "  ❌ No criteria"
                    errors=$((errors + 1))
                else
                    echo "  ✓ Valid (promise marker)"
                fi
            else
                echo "  ✓ Valid ($checkbox_count criteria)"
            fi
        fi
        
        [ ! -f "$task_dir/progress.md" ] && warnings=$((warnings + 1))
        [ ! -f "$task_dir/.iteration" ] && warnings=$((warnings + 1))
        
        total_errors=$((total_errors + errors))
        total_warnings=$((total_warnings + warnings))
        echo ""
    done
    
    echo "═══════════════════════════════════════════════════════"
    echo "Total: $task_count tasks, $total_errors errors, $total_warnings warnings"
    echo "═══════════════════════════════════════════════════════"
    
    [ $total_errors -gt 0 ] && return 1
    return 0
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
    validate)
        if [ -z "${2:-}" ]; then
            validate_all_tasks
        else
            validate_task "$2"
        fi
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
