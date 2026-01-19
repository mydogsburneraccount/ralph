#!/bin/bash
# Install git pre-commit hook for Ralph
# Run this once to enable automatic validation before commits

set -e

# Find the .ralph directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOKS_DIR="$RALPH_ROOT/.git/hooks"

echo "Installing Ralph pre-commit hook..."
echo "Ralph root: $RALPH_ROOT"

# Create hooks directory if needed
mkdir -p "$HOOKS_DIR"

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'HOOK_EOF'
#!/bin/bash
# Ralph pre-commit hook - validates shell scripts before commit

echo "🔍 Running Ralph script validation..."

# Find workspace root (parent of .ralph if this is a submodule)
RALPH_DIR="$(git rev-parse --show-toplevel)"

# Check if dos2unix is available
if ! command -v dos2unix &> /dev/null; then
    echo "⚠️  dos2unix not installed - skipping CRLF check"
fi

# Quick validation (no shellcheck for speed)
ERRORS=0

# Check staged .sh files for CRLF
STAGED_SH=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$' || true)

if [ -n "$STAGED_SH" ]; then
    echo "Checking staged shell scripts..."

    for script in $STAGED_SH; do
        if [ -f "$script" ]; then
            # Check for CRLF
            if file "$script" | grep -q "CRLF"; then
                echo "❌ CRLF line endings: $script"
                echo "   Fix with: dos2unix $script"
                ERRORS=$((ERRORS + 1))
            fi

            # Bash syntax check
            if ! bash -n "$script" 2>/dev/null; then
                echo "❌ Syntax error: $script"
                bash -n "$script" 2>&1 | head -3
                ERRORS=$((ERRORS + 1))
            fi
        fi
    done
fi

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "❌ Pre-commit validation failed with $ERRORS error(s)"
    echo "   Fix issues and try again, or bypass with: git commit --no-verify"
    exit 1
fi

echo "✓ Pre-commit validation passed"
exit 0
HOOK_EOF

chmod +x "$HOOKS_DIR/pre-commit"

echo "✓ Pre-commit hook installed: $HOOKS_DIR/pre-commit"
echo ""
echo "The hook will automatically validate shell scripts before each commit."
echo "To bypass (not recommended): git commit --no-verify"
