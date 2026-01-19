#!/bin/bash
# Ralph Rollback Script - Safely undo Ralph changes
# Finds Ralph branch, shows changes, confirms, and rolls back

set -euo pipefail

WORKSPACE=$(pwd)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
TASK_NAME="${1:-}"
if [ -z "$TASK_NAME" ]; then
    echo "Usage: $0 <task-name>"
    echo ""
    echo "Safely roll back Ralph changes for a task by:"
    echo "  1. Finding the ralph-<task>-* branch"
    echo "  2. Showing what would be discarded"
    echo "  3. Confirming with you before acting"
    echo "  4. Deleting the branch and returning to main"
    echo ""
    echo "Example: $0 my-feature"
    exit 1
fi

# Find Ralph branch for this task
find_ralph_branch() {
    local task="$1"
    local branches
    
    # Look for branches matching ralph-<task>-* pattern
    branches=$(git branch --list "ralph-${task}-*" 2>/dev/null | sed 's/^[ *]*//' || true)
    
    if [ -z "$branches" ]; then
        # Also try exact match without date suffix
        branches=$(git branch --list "ralph-${task}" 2>/dev/null | sed 's/^[ *]*//' || true)
    fi
    
    if [ -z "$branches" ]; then
        echo ""
        return
    fi
    
    # If multiple branches, get the most recent one (by date suffix)
    echo "$branches" | sort -r | head -1
}

# Get the main branch name (main or master)
get_main_branch() {
    if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
        echo "main"
    elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
        echo "master"
    else
        echo "main"  # Default assumption
    fi
}

# Main rollback logic
echo -e "${BLUE}=== Ralph Rollback ===${NC}"
echo ""

# Check we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Not in a git repository${NC}"
    exit 1
fi

# Find the Ralph branch
RALPH_BRANCH=$(find_ralph_branch "$TASK_NAME")

if [ -z "$RALPH_BRANCH" ]; then
    echo -e "${YELLOW}⚠️  No Ralph branch found for task: $TASK_NAME${NC}"
    echo ""
    echo "Looking for branches matching: ralph-${TASK_NAME}-*"
    echo ""
    echo "Available Ralph branches:"
    git branch --list "ralph-*" 2>/dev/null | sed 's/^/  /' || echo "  (none)"
    exit 1
fi

MAIN_BRANCH=$(get_main_branch)
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

echo -e "Found branch: ${GREEN}$RALPH_BRANCH${NC}"
echo -e "Main branch:  ${BLUE}$MAIN_BRANCH${NC}"
echo -e "Current:      ${YELLOW}$CURRENT_BRANCH${NC}"
echo ""

# Show diff summary
echo -e "${BLUE}=== Changes that would be discarded ===${NC}"
echo ""

# Check if branch has been pushed
REMOTE_EXISTS=$(git ls-remote --heads origin "$RALPH_BRANCH" 2>/dev/null | wc -l | tr -d ' ')
REMOTE_EXISTS=${REMOTE_EXISTS:-0}

if [ "$REMOTE_EXISTS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Warning: This branch exists on remote origin${NC}"
    echo ""
fi

# Show commit count
COMMIT_COUNT=$(git rev-list --count "$MAIN_BRANCH".."$RALPH_BRANCH" 2>/dev/null | tr -d ' ')
COMMIT_COUNT=${COMMIT_COUNT:-0}
echo -e "Commits: ${YELLOW}$COMMIT_COUNT${NC}"
echo ""

# Show file changes summary
echo -e "${BLUE}Files changed:${NC}"
git diff "$MAIN_BRANCH"..."$RALPH_BRANCH" --stat 2>/dev/null || echo "  (could not compute diff)"
echo ""

# Show recent commits
if [ "$COMMIT_COUNT" -gt 0 ]; then
    echo -e "${BLUE}Recent commits on this branch:${NC}"
    git log --oneline "$MAIN_BRANCH".."$RALPH_BRANCH" 2>/dev/null | head -10 || true
    if [ "$COMMIT_COUNT" -gt 10 ]; then
        echo "  ... and $((COMMIT_COUNT - 10)) more"
    fi
    echo ""
fi

# Confirm rollback
echo -e "${RED}=== CONFIRM ROLLBACK ===${NC}"
echo ""
echo "This will:"
echo "  1. Checkout $MAIN_BRANCH"
echo "  2. Delete local branch: $RALPH_BRANCH"
if [ "$REMOTE_EXISTS" -gt 0 ]; then
    echo -e "  ${YELLOW}3. NOTE: Remote branch will NOT be deleted (do this manually if needed)${NC}"
fi
echo ""
echo -e "${RED}This action CANNOT be undone!${NC}"
echo ""

read -p "Delete branch and discard changes? (y/n): " -n 1 -r CONFIRM
echo ""

if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Rollback cancelled.${NC}"
    exit 0
fi

# Execute rollback
echo ""
echo -e "${BLUE}Executing rollback...${NC}"

# First, checkout main (need to be off the branch to delete it)
if [ "$CURRENT_BRANCH" = "$RALPH_BRANCH" ]; then
    echo "  Switching to $MAIN_BRANCH..."
    git checkout "$MAIN_BRANCH"
fi

# Delete the branch
echo "  Deleting branch $RALPH_BRANCH..."
git branch -D "$RALPH_BRANCH"

echo ""
echo -e "${GREEN}✓ Rollback complete!${NC}"
echo ""
echo "Current branch: $(git branch --show-current)"
echo ""

# Check for task directory
TASK_DIR="$WORKSPACE/.ralph/active/$TASK_NAME"
if [ -d "$TASK_DIR" ]; then
    echo -e "${YELLOW}Note: Task directory still exists: $TASK_DIR${NC}"
    echo "Run this to archive it: ./.ralph/core/scripts/ralph-task-manager.sh archive $TASK_NAME"
fi
