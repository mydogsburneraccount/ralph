#!/bin/bash
# Ralph Preflight Check - Run at start of any Ralph session
# Quick validation that catches common issues before burning API calls
#
# Usage:
#   ./ralph-preflight.sh                    # Check all
#   ./ralph-preflight.sh <task-name>        # Check specific task
#   ./ralph-preflight.sh --fix              # Auto-fix CRLF issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse arguments
FIX_MODE=false
TASK_NAME=""
for arg in "$@"; do
    case "$arg" in
        --fix) FIX_MODE=true ;;
        -*) ;; # Ignore other flags
        *) TASK_NAME="$arg" ;;
    esac
done

# Find workspace root
find_workspace_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.ralph" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    echo "$PWD"
}

WORKSPACE=$(find_workspace_root)
cd "$WORKSPACE"

echo "═══════════════════════════════════════════════════════════════════"
echo "🔍 Ralph Preflight Check"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

ERRORS=0
WARNINGS=0

# 1. Check CRLF in core scripts
echo -e "${YELLOW}1. Checking script line endings...${NC}"
CRLF_COUNT=0
SCRIPTS=$(find .ralph -name "*.sh" -type f 2>/dev/null || true)
for script in $SCRIPTS; do
    [ -f "$script" ] || continue
    if file "$script" | grep -q "CRLF"; then
        if [ "$FIX_MODE" = true ]; then
            dos2unix "$script" 2>/dev/null
            echo "   🔧 Fixed: $script"
        else
            echo -e "   ${RED}❌ CRLF:${NC} $script"
            CRLF_COUNT=$((CRLF_COUNT + 1))
        fi
    fi
done

if [ $CRLF_COUNT -gt 0 ]; then
    ERRORS=$((ERRORS + CRLF_COUNT))
    echo ""
    echo -e "   ${YELLOW}Fix with:${NC} dos2unix .ralph/core/scripts/*.sh .ralph/backends/*/*.sh"
elif [ "$FIX_MODE" = false ]; then
    echo -e "   ${GREEN}✓${NC} All scripts have Unix line endings"
fi
echo ""

# 2. Check task structure (if task specified)
if [ -n "$TASK_NAME" ]; then
    echo -e "${YELLOW}2. Validating task: $TASK_NAME${NC}"
    TASK_DIR=".ralph/active/$TASK_NAME"

    if [ ! -d "$TASK_DIR" ]; then
        echo -e "   ${RED}❌ Task not found:${NC} $TASK_DIR"
        ERRORS=$((ERRORS + 1))
    else
        # Check TASK.md
        if [ ! -f "$TASK_DIR/TASK.md" ]; then
            echo -e "   ${RED}❌ Missing:${NC} TASK.md"
            ERRORS=$((ERRORS + 1))
        else
            # Check for criteria
            criteria=$(tr -d '\r' < "$TASK_DIR/TASK.md" | grep -cE '\[ \]|\[x\]' || echo "0")
            criteria=$(echo "$criteria" | tr -d '[:space:]')
            criteria=${criteria:-0}

            if [ "$criteria" -eq 0 ]; then
                promise=$(tr -d '\r' < "$TASK_DIR/TASK.md" | grep -c '<promise>' || echo "0")
                promise=$(echo "$promise" | tr -d '[:space:]')
                if [ "${promise:-0}" -eq 0 ]; then
                    echo -e "   ${RED}❌ No criteria:${NC} TASK.md has no checkboxes or promise marker"
                    ERRORS=$((ERRORS + 1))
                else
                    echo -e "   ${GREEN}✓${NC} TASK.md has promise marker"
                fi
            else
                unchecked=$(tr -d '\r' < "$TASK_DIR/TASK.md" | grep -c '\[ \]' || echo "0")
                unchecked=$(echo "$unchecked" | tr -d '[:space:]')
                echo -e "   ${GREEN}✓${NC} TASK.md has $criteria criteria ($unchecked remaining)"
            fi
        fi

        # Check progress.md
        if [ ! -f "$TASK_DIR/progress.md" ]; then
            echo -e "   ${YELLOW}⚠️${NC}  Missing progress.md (will be created)"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "   ${GREEN}✓${NC} progress.md exists"
        fi
    fi
    echo ""
else
    echo -e "${YELLOW}2. Task validation skipped${NC} (no task specified)"
    echo ""
fi

# 3. Check cursor-agent availability
echo -e "${YELLOW}3. Checking cursor-agent...${NC}"
if command -v cursor-agent &> /dev/null; then
    echo -e "   ${GREEN}✓${NC} cursor-agent available"
else
    echo -e "   ${YELLOW}⚠️${NC}  cursor-agent not found (needed for ralph-autonomous)"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 4. Check git status
echo -e "${YELLOW}4. Checking git status...${NC}"
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    echo -e "   ${GREEN}✓${NC} Git repo, branch: $BRANCH"

    # Warn if on main/master
    if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
        echo -e "   ${YELLOW}⚠️${NC}  On $BRANCH - Ralph will create a safety branch"
    fi
else
    echo -e "   ${RED}❌${NC} Not a git repository"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Summary
echo "═══════════════════════════════════════════════════════════════════"
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ Preflight FAILED${NC} - $ERRORS error(s), $WARNINGS warning(s)"
    echo ""
    echo "Fix issues before running Ralph tasks."
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Preflight passed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${GREEN}✓ Preflight PASSED${NC}"
    exit 0
fi
