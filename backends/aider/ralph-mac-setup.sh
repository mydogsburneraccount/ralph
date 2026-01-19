#!/usr/bin/env bash
# Ralph Setup for Mac
# Run this once to configure Ralph on your Mac (corporate or personal)

set -euo pipefail

echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Wiggum - Mac Setup                      ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

# Detect shell
SHELL_RC="${HOME}/.zshrc"
if [[ "${SHELL}" == *"bash"* ]]; then
    SHELL_RC="${HOME}/.bash_profile"
fi

echo "Detected shell config: ${SHELL_RC}"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
echo ""

# Check bash
if ! command -v bash &> /dev/null; then
    echo "❌ bash not found. This shouldn't happen on Mac."
    exit 1
fi
echo "✅ bash: $(bash --version | head -n1)"

# Check git
if ! command -v git &> /dev/null; then
    echo "❌ git not found. Install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi
echo "✅ git: $(git --version)"

# Check git config
GIT_NAME=$(git config user.name || echo "")
GIT_EMAIL=$(git config user.email || echo "")
if [[ -z "${GIT_NAME}" ]] || [[ -z "${GIT_EMAIL}" ]]; then
    echo "⚠️  git not configured. You'll need to set:"
    echo "   git config --global user.name \"Your Name\""
    echo "   git config --global user.email \"your@email.com\""
    echo ""
fi

# Check curl
if ! command -v curl &> /dev/null; then
    echo "❌ curl not found. Install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi
echo "✅ curl: available"

echo ""
echo "─────────────────────────────────────────────────────"
echo ""

# Check if cursor-agent is installed
if command -v cursor-agent &> /dev/null; then
    echo "✅ cursor-agent already installed: $(cursor-agent --version)"
else
    echo "❌ cursor-agent not found"
    echo ""
    echo "Do you want to install cursor-agent now? (y/n)"
    read -r REPLY
    if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Installing cursor-agent..."
        curl https://cursor.com/install -fsS | bash
        
        # Add to PATH
        export PATH="${HOME}/.local/bin:${PATH}"
        
        # Check if already in shell config
        if ! grep -q "\.local/bin" "${SHELL_RC}" 2>/dev/null; then
            echo "" >> "${SHELL_RC}"
            echo "# Added by Ralph setup" >> "${SHELL_RC}"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${SHELL_RC}"
            echo "✅ Added to ${SHELL_RC}"
        fi
        
        # Verify
        if command -v cursor-agent &> /dev/null; then
            echo "✅ cursor-agent installed: $(cursor-agent --version)"
        else
            echo "❌ Installation failed. Try manual install:"
            echo "   1. Go to https://cursor.com"
            echo "   2. Download Mac installer"
            echo "   3. Run installer"
            exit 1
        fi
    else
        echo "⚠️  Skipping cursor-agent installation"
        echo "   Install manually from https://cursor.com"
        echo ""
    fi
fi

echo ""
echo "─────────────────────────────────────────────────────"
echo ""

# Check authentication
echo "Checking cursor-agent authentication..."
if cursor-agent status &> /dev/null; then
    echo "✅ cursor-agent is authenticated"
else
    echo "❌ cursor-agent not authenticated"
    echo ""
    echo "Run: cursor-agent login"
    echo "Then run this script again."
    exit 1
fi

echo ""
echo "─────────────────────────────────────────────────────"
echo ""

# Setup workspace structure
WORKSPACE=$(pwd)
echo "Setting up Ralph workspace in: ${WORKSPACE}"
echo ""

# Create .ralph directory
if [[ ! -d "${WORKSPACE}/.ralph" ]]; then
    echo "Creating .ralph directory..."
    mkdir -p "${WORKSPACE}/.ralph"
fi

# Create state files if they don't exist
if [[ ! -f "${WORKSPACE}/.ralph/progress.md" ]]; then
    echo "Creating .ralph/progress.md..."
    cat > "${WORKSPACE}/.ralph/progress.md" << 'EOF'
# Ralph Progress

## Current Status
- Workspace initialized
- Ready for first task

## History
- [$(date +%Y-%m-%d)] Setup complete
EOF
fi

if [[ ! -f "${WORKSPACE}/.ralph/guardrails.md" ]]; then
    echo "Creating .ralph/guardrails.md..."
    cat > "${WORKSPACE}/.ralph/guardrails.md" << 'EOF'
# Ralph Guardrails (Signs)

## What Are Signs?
When failures occur, document them here so future iterations don't repeat the same mistakes.

### Example Format:
```markdown
### Sign: [Rule name]
- **Trigger**: When to apply this rule
- **Instruction**: What to do
- **Added after**: Iteration X - what went wrong
```

## Signs
_None yet - add after first iteration if needed_
EOF
fi

if [[ ! -f "${WORKSPACE}/.ralph/errors.log" ]]; then
    echo "Creating .ralph/errors.log..."
    touch "${WORKSPACE}/.ralph/errors.log"
fi

if [[ ! -f "${WORKSPACE}/.ralph/.iteration" ]]; then
    echo "Creating .ralph/.iteration..."
    echo "0" > "${WORKSPACE}/.ralph/.iteration"
fi

echo "✅ Workspace structure created"

echo ""
echo "─────────────────────────────────────────────────────"
echo ""

# Make scripts executable
if [[ -d "${WORKSPACE}/.ralph/core/scripts" ]]; then
    echo "Making Ralph scripts executable..."
    chmod +x "${WORKSPACE}/.ralph/core/scripts"/*.sh 2>/dev/null || true
    chmod +x "${WORKSPACE}/.ralph/backends"/*/*.sh 2>/dev/null || true
    echo "✅ Scripts are executable"
else
    echo "⚠️  .ralph/core/scripts directory not found"
    echo "   Make sure Ralph module is installed in this workspace"
fi

echo ""
echo "─────────────────────────────────────────────────────"
echo ""

# Initialize git if not already
if [[ ! -d "${WORKSPACE}/.git" ]]; then
    echo "Initializing git repository..."
    git init
    echo "✅ Git initialized"
    echo ""
    echo "⚠️  Configure git before running Ralph:"
    echo "   git config user.name \"Your Name\""
    echo "   git config user.email \"your@email.com\""
else
    echo "✅ Git repository already initialized"
fi

echo ""
echo "─────────────────────────────────────────────────────"
echo ""

# Create sample task if none exists
if [[ ! -f "${WORKSPACE}/RALPH_TASK.md" ]]; then
    echo "Creating sample RALPH_TASK.md..."
    cat > "${WORKSPACE}/RALPH_TASK.md" << 'EOF'
# Sample Ralph Task

## Task Overview

This is a sample task file. Edit this to define your actual task.

**Goal**: [Describe what you want to accomplish]

**Context**: [Any relevant information about the project, tech stack, constraints]

---

## Success Criteria

Replace these with your actual criteria. Make them specific and testable!

- [ ] Criterion 1: Specific, measurable outcome
- [ ] Criterion 2: Another specific outcome
- [ ] All tests pass
- [ ] Documentation is updated

---

## Notes

- Each criterion should be independently verifiable
- Use this format: `- [ ]` for unchecked, `- [x]` for checked
- Ralph tracks completion by counting remaining `[ ]` checkboxes
- Be specific! "Make it work" is bad. "GET /health returns 200" is good.

---

## Rollback Plan

If things go wrong:

```bash
# View recent commits
git log --oneline --grep="ralph:"

# Revert specific commit
git revert <commit-hash>

# Or reset to before Ralph started
git reset --hard <commit-before-ralph>
```
EOF
    echo "✅ Sample RALPH_TASK.md created (edit before running Ralph)"
else
    echo "✅ RALPH_TASK.md already exists"
fi

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║     Setup Complete!                                ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo ""
echo "1. Edit RALPH_TASK.md with your actual task"
echo "   nano RALPH_TASK.md"
echo ""
echo "2. (If needed) Configure git:"
echo "   git config user.name \"Your Name\""
echo "   git config user.email \"your@email.com\""
echo ""
echo "3. Run Ralph autonomous mode:"
echo "   ./.ralph/backends/cursor-agent/ralph-autonomous.sh"
echo ""
echo "4. Or test with single iteration first:"
echo "   cursor-agent -p \"Read RALPH_TASK.md and work on first criterion\""
echo ""
echo "For help, see:"
echo "  - .ralph/core/docs/INDEX.md"
echo "  - .ralph/core/docs/QUICKREF.md"
echo "  - .ralph/backends/aider/RALPH_MAC_QUICKSTART.md"
echo ""
