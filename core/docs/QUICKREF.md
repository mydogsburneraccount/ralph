# Ralph Wiggum Quick Reference

## 🚀 Quick Start

```bash
# One-time setup
wsl
cd /mnt/c/Users/Ethan/Code/cursor_local_workspace
./.ralph/scripts/ralph-wsl-setup.sh
cursor-agent login

# Install base toolset (optional but recommended)
./.ralph/scripts/ralph-base-toolset.sh

# Create a task
./.ralph/scripts/ralph-task-manager.sh create my-task

# Edit your task
nano .ralph/active/my-task/TASK.md

# Run autonomous loop (will check/install task dependencies)
./.ralph/scripts/ralph-autonomous.sh my-task
```

---

## 📋 Task Format

```markdown
---
dependencies:
  python:
    - pytest>=7.0
  system:
    - jq
  check_commands:
    - pytest --version
---

# Task Name

## Success Criteria
- [ ] Specific criterion 1
- [ ] Specific criterion 2
- [ ] All tests pass

## Context
Tech stack: [your stack]
Constraints: [your constraints]
```

---

## 🔄 Workflow

```
1. Create task → ralph-task-manager.sh create <name>
2. Define criteria → .ralph/active/<name>/TASK.md
3. Run: ./ralph-autonomous.sh <name>
4. Go AFK (seriously, walk away)
5. Come back → check results
6. Archive: ralph-task-manager.sh archive <name>
```

---

## 📁 Files

| File | Purpose |
|------|---------|
| `.ralph/active/<task>/TASK.md` | Task with `[ ]` checkboxes |
| `.ralph/active/<task>/progress.md` | What's been done |
| `.ralph/active/<task>/.iteration` | Current iteration |
| `.ralph/guardrails.md` | Global lessons learned |
| `.ralph/docs/` | Ralph documentation |

---

## 🛠️ Commands

```bash
# Setup
./.ralph/scripts/ralph-wsl-setup.sh

# Install base development tools (Python, Node.js, Docker, etc.)
# Uses pipx for Python CLI tools, follows WSL best practices
sudo ./.ralph/scripts/ralph-base-toolset.sh

# Test base toolset installation
./.ralph/scripts/test-base-toolset.sh

# Install additional dependencies (created by ralph-base-toolset.sh)
ralph-install-dependency system jq          # System package
ralph-install-dependency python requests    # Python library
ralph-install-dependency pipx aider-chat    # Python CLI tool
ralph-install-dependency npm typescript     # npm package

# List tasks
./.ralph/scripts/ralph-task-manager.sh list

# Create task
./.ralph/scripts/ralph-task-manager.sh create <name>

# Run (auto-checks dependencies)
./.ralph/scripts/ralph-autonomous.sh <task-name>

# Run with auto-install dependencies
RALPH_AUTO_INSTALL=true ./.ralph/scripts/ralph-autonomous.sh <task-name>

# Run skipping dependency checks
RALPH_SKIP_DEPS=true ./.ralph/scripts/ralph-autonomous.sh <task-name>

# Check progress
cat .ralph/active/<task-name>/progress.md

# View commits
git log --oneline --grep="ralph(<task-name>):"

# Archive completed task
./.ralph/scripts/ralph-task-manager.sh archive <task-name>

# Rollback a task (delete branch and changes)
./.ralph/scripts/ralph-rollback.sh <task-name>
```

---

## 🤖 Aider Backend (CLI-Only)

For environments without Cursor (corporate Macs, SSH, etc.):

```bash
# Prerequisites (install via pipx for isolation)
pipx install aider-chat
export ANTHROPIC_API_KEY="sk-ant-api03-..."

# Run with default model (Sonnet)
./.ralph/scripts/ralph-aider.sh my-task

# Run with specific model
RALPH_MODEL=haiku ./.ralph/scripts/ralph-aider.sh my-task
RALPH_MODEL=opus ./.ralph/scripts/ralph-aider.sh my-task
```

**Model options**:

| Model | Use Case | Cost |
|-------|----------|------|
| `haiku` | Fast iteration, simple tasks | Cheap |
| `sonnet` | Balanced (default) | Medium |
| `opus` | Complex reasoning | Expensive |

Same task format, same protocol - just different backend.

---

## 🤖 Copilot Backend (Corporate-Approved)

For corporate environments with GitHub Copilot licenses:

```bash
# Prerequisites
# - Active GitHub Copilot license
# - copilot CLI installed (npm, brew, or winget)
npm install -g @github/copilot

# Run with Copilot backend
./.ralph/scripts/ralph-copilot.sh my-task

# Run with specific model
RALPH_COPILOT_MODEL=claude ./.ralph/scripts/ralph-copilot.sh my-task
RALPH_COPILOT_MODEL=gpt ./.ralph/scripts/ralph-copilot.sh my-task
```

**Model options**:

| Model | Use Case | Notes |
|-------|----------|-------|
| `claude-sonnet` | Balanced (default) | Claude Sonnet 4.5 |
| `claude` | Complex reasoning | Claude 4 |
| `gpt` | Alternative | GPT-5 |

**Why use Copilot?**

- ✅ Uses corporate GitHub contract (no personal API keys)
- ✅ Data stays in GitHub/Microsoft infrastructure
- ✅ Enterprise audit logging available
- ✅ No additional security approvals needed

**Full docs**: `.ralph/docs/COPILOT_BACKEND.md` and `.ralph/docs/COPILOT_TESTING.md`

---

## 🔙 Rollback (Undo Ralph Changes)

If a Ralph task went wrong and you want to discard all changes:

```bash
# Roll back a specific task
./.ralph/scripts/ralph-rollback.sh my-task

# What it does:
# 1. Finds the ralph-my-task-* branch
# 2. Shows you what changes would be discarded
# 3. Asks for confirmation
# 4. Deletes branch and returns to main
```

**Safety notes**:

- Always review the diff summary before confirming
- Remote branches are NOT deleted (manual cleanup if pushed)
- Task directory remains (use `archive` to clean up)

---

## ✍️ Adding a Sign

```markdown
### Sign: [Rule name]
- **Trigger**: When to apply
- **Instruction**: What to do
- **Added after**: Iteration X - what failed
```

---

## 💰 Cost Tracking

Ralph tracks estimated API costs per iteration:

```bash
# View costs for a task
cat .ralph/active/<task>/costs.log

# Example output:
# [2026-01-17 10:30:00] Iteration 1: ~2500 tokens, ~$0.05
# [2026-01-17 10:32:00] Iteration 2: ~3200 tokens, ~$0.06
```

Cost summary shown at end of run.

---

## 🔀 Auto-Branching (Safety)

Ralph automatically creates a safety branch when starting from main:

```bash
# Starting on main → Auto-creates ralph-my-task-20260117
# Starting on ralph-* → Continues on that branch
```

After completion: merge or rollback the branch.

---

## 🔄 Context Rotation

For long runs (20+ iterations), Ralph auto-rotates context every 10 iterations:

- Summarizes recent progress
- Appends to progress.md
- Keeps agent context fresh

---

## 🏷️ Promise Marker (Alternative)

Tasks can use promise markers instead of checkboxes:

```markdown
<promise>INCOMPLETE</promise>
```

Agent changes to `COMPLETE` when done. See RALPH_RULES.md.

---

## 💡 Tips

- ✅ Make criteria specific and testable
- ✅ Commit frequently (agent does this)
- ✅ Monitor first iteration, then go AFK
- ✅ Use git (so you can revert)
- ⚠️ Watch API costs on long runs

---

## 🎯 This Is Real Ralph

- ✅ Autonomous (go AFK)
- ✅ Fresh context each iteration
- ✅ Works overnight
- ✅ State in git, not LLM memory

**Full docs**: `.ralph/docs/SETUP.md` and `.ralph/docs/INDEX.md`

---

## 📝 Writing Good Tasks

See **[RALPH_RULES.md](RALPH_RULES.md)** for detailed task writing guidance.

Key rules:

- All criteria must be verifiable via command output (no GUI, no TUI)
- Use specific, measurable success criteria
- Include file paths and expected outputs
- Avoid forbidden patterns (see ANTIPATTERNS.md)
