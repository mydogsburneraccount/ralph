# Ralph Wiggum - Complete Documentation Index

**Autonomous AI development for Cursor and CLI environments**

---

## 🚀 Quick Links

| If you want to... | Read this |
|-------------------|-----------|
| **Get started on Windows WSL** | [SETUP.md](SETUP.md) |
| **Get started on Mac with Cursor** | [RALPH_MAC_QUICKSTART.md](RALPH_MAC_QUICKSTART.md) |
| **Use CLI-only (no Cursor)** | [RALPH_CLI_ONLY.md](RALPH_CLI_ONLY.md) ⭐ |
| **Quick command reference** | [QUICKREF.md](QUICKREF.md) |
| **⚠️ AVOID COMMON MISTAKES** | [ANTIPATTERNS.md](ANTIPATTERNS.md) ⚠️ **READ THIS FIRST** |
| **Script reference** | [SCRIPTS.md](SCRIPTS.md) |

---

## 📚 Core Documentation (9 Files)

### Getting Started

| File | Purpose | Status |
|------|---------|--------|
| **[SETUP.md](SETUP.md)** | Main documentation for Windows/WSL setup | ✅ Multi-task |
| **[RALPH_MAC_QUICKSTART.md](RALPH_MAC_QUICKSTART.md)** | Quick start guide for Mac | ✅ Multi-task |
| **[RALPH_CLI_ONLY.md](RALPH_CLI_ONLY.md)** | Complete CLI-only guide (no Cursor) | ✅ Multi-task |
| **[QUICKREF.md](QUICKREF.md)** | Quick reference card | ✅ Multi-task |

### Essential Guidance

| File | Purpose | Status |
|------|---------|--------|
| **[ANTIPATTERNS.md](ANTIPATTERNS.md)** | ⚠️ **CRITICAL**: Forbidden task patterns | ✅ Multi-task |
| **[RALPH_RULES.md](RALPH_RULES.md)** | Task writing guidance, best practices | ✅ Generic |
| **[SCRIPTS.md](SCRIPTS.md)** | Script reference for `.ralph/core/scripts/` and backends | ✅ Multi-task |

### Reference

| File | Purpose | Status |
|------|---------|--------|
| **[INDEX.md](INDEX.md)** | This file - documentation index | ✅ Current |
| **[GITHUB_CORPORATE_ACCESS.md](GITHUB_CORPORATE_ACCESS.md)** | GitHub corporate access guidance | ✅ Generic |

---

## 🎯 Use Cases & Solutions

### Scenario 1: "I have Windows with WSL"

**Solution**: Original Ralph setup with cursor-agent
**Read**: [SETUP.md](SETUP.md)
**Time**: 1-2 hours
**Cost**: $20-40/mo (Cursor subscription)

---

### Scenario 2: "I have a personal Mac"

**Solution**: Cursor + cursor-agent
**Read**: [RALPH_MAC_QUICKSTART.md](RALPH_MAC_QUICKSTART.md)
**Time**: 1-2 hours
**Cost**: $20-40/mo (Cursor subscription)

---

### Scenario 3: "I have a corporate Mac, Cursor not allowed"

**Solution**: CLI-only with Aider or Copilot
**Read**: [RALPH_CLI_ONLY.md](RALPH_CLI_ONLY.md)
**Time**: 15 minutes
**Cost**: $5-20/mo (API) or FREE (corporate Copilot)

**This is the RECOMMENDED approach for corporate** ⭐

---

### Scenario 4: "I want the cheapest option"

**Solution**: Aider + Claude Haiku
**Read**: [RALPH_CLI_ONLY.md](RALPH_CLI_ONLY.md) → "Option 1: Aider"
**Cost**: $5-10/mo
**Quality**: Excellent

---

### Scenario 5: "I have GitHub Copilot at work"

**Solution**: Use Copilot CLI (FREE!)
**Read**: [RALPH_CLI_ONLY.md](RALPH_CLI_ONLY.md) → "Option 3: GitHub Copilot CLI"
**Cost**: $0 (company pays)

---

## 📖 Reading Order

### For Beginners (Windows/WSL)

1. [SETUP.md](SETUP.md) - Understand Ralph concept & multi-task structure
2. [ANTIPATTERNS.md](ANTIPATTERNS.md) - **CRITICAL** - Learn what NOT to do
3. [QUICKREF.md](QUICKREF.md) - Quick commands
4. Run `ralph-autonomous.sh <task-name>`
5. Start coding!

**Time**: 2 hours to full productivity

---

### For Mac Users

1. [RALPH_MAC_QUICKSTART.md](RALPH_MAC_QUICKSTART.md) - Mac-specific setup
2. [ANTIPATTERNS.md](ANTIPATTERNS.md) - **CRITICAL** - Learn what NOT to do
3. [QUICKREF.md](QUICKREF.md) - Quick commands
4. Start coding!

**Time**: 1-2 hours to full productivity

---

### For CLI-Only Users (Corporate/Personal)

1. [RALPH_CLI_ONLY.md](RALPH_CLI_ONLY.md) - Complete CLI guide
2. [ANTIPATTERNS.md](ANTIPATTERNS.md) - **CRITICAL** - Learn what NOT to do
3. Run setup script
4. Start coding!

**Time**: 15 minutes to full productivity

---

## 🔧 Scripts

Scripts are in `.ralph/core/scripts/` (core) and `.ralph/backends/*/` (backend-specific) - see [SCRIPTS.md](SCRIPTS.md) for full reference.

### Core Scripts

| Script | Purpose | Status |
|--------|---------|--------|
| `ralph-autonomous.sh <task>` | Main autonomous loop | ✅ Multi-task |
| `ralph-task-manager.sh` | Create/list/archive tasks | ✅ Multi-task |
| `ralph-wsl-setup.sh` | WSL setup | ✅ Production |
| `ralph-aider.sh <task>` | Aider-based loop (CLI) | ✅ Multi-task |
| `ralph-cli-setup.sh` | One-command CLI setup | ✅ Production |
| `ralph-mac-setup.sh` | Mac-specific setup | ✅ Production |

---

## 🎓 Key Concepts

### What is Ralph?

**Simple explanation**: Put an AI agent in a loop until a task is complete.

```bash
while not_done:
    fresh_agent_process()
    work_on_task()
    commit_to_git()
```

**Key insight**: State lives in files and git, not in LLM context.

---

### Multi-Task Structure (Current)

```
.ralph/
├── active/
│   ├── task-1/
│   │   ├── TASK.md          ← Not "RALPH_TASK.md" in root!
│   │   ├── progress.md
│   │   └── .iteration
│   └── task-2/
│       ├── TASK.md
│       ├── progress.md
│       └── .iteration
├── completed/                ← Archived tasks
├── core/docs/                ← These docs
├── guardrails.md            ← Global lessons learned
└── README.md
```

**Benefits**:

- Run multiple Ralph instances on different tasks
- Easy to pause, resume, or switch tasks
- Clean task history and archiving
- No file swapping needed

---

### Commands (Current)

```bash
# Create task
./.ralph/core/scripts/ralph-task-manager.sh create my-task

# Edit task
nano .ralph/active/my-task/TASK.md

# Run task
./.ralph/backends/cursor-agent/ralph-autonomous.sh my-task

# Check progress
cat .ralph/active/my-task/progress.md

# Archive completed task
./.ralph/core/scripts/ralph-task-manager.sh archive my-task
```

---

## 📊 Platform Compatibility

| Platform | cursor-agent | CLI (Aider) |
|----------|-------------|-------------|
| Windows WSL | ✅ Yes | ✅ Yes |
| macOS | ✅ Yes | ✅ Yes |
| Linux | ✅ Yes | ✅ Yes |
| Corporate Mac | ⚠️ Maybe | ✅ Yes |
| Over SSH | ❌ No | ✅ Yes |

---

## 💡 Cost Breakdown

| Approach | Cost | Best For |
|----------|------|----------|
| Cursor (cursor-agent) | $20-40/mo | Windows/WSL, personal Mac |
| Aider + Claude Sonnet | $15/mo avg | Balanced quality/cost |
| Aider + Claude Haiku | $5-10/mo | Budget-conscious |
| GitHub Copilot CLI | FREE-$19/mo | Corporate with Copilot |
| OpenAI Codex CLI | $10-20/mo | OpenAI preference |

---

## 🔗 External Resources

### Official Tools

- **Cursor**: <https://cursor.com>
- **Aider**: <https://aider.chat>
- **Anthropic Console**: <https://console.anthropic.com/>
- **GitHub Copilot**: <https://github.com/features/copilot>

### API Documentation

- **Anthropic API**: <https://docs.anthropic.com/>
- **OpenAI API**: <https://platform.openai.com/docs>

---

## 🆘 Getting Help

### Setup Issues

1. Read troubleshooting in [SETUP.md](SETUP.md) or [RALPH_CLI_ONLY.md](RALPH_CLI_ONLY.md)
2. Verify API key is set correctly
3. Check git is configured
4. Ensure scripts are executable: `chmod +x .ralph/core/scripts/*.sh .ralph/backends/*/*.sh`

### Task Issues

1. Read [ANTIPATTERNS.md](ANTIPATTERNS.md) - most issues come from bad task definitions
2. Make criteria specific and testable
3. Avoid GUI interactions, manual restarts, interactive prompts
4. Check that test commands actually work

---

## 📝 Document Status

All core documentation updated to **multi-task structure** as of 2026-01-17.

| Document | Status | Last Updated |
|----------|--------|--------------|
| SETUP.md | ✅ Multi-task | 2026-01-17 |
| QUICKREF.md | ✅ Multi-task | 2026-01-17 |
| ANTIPATTERNS.md | ✅ Multi-task | 2026-01-17 |
| RALPH_RULES.md | ✅ Generic | 2026-01-16 |
| RALPH_CLI_ONLY.md | ✅ Multi-task | 2026-01-17 |
| RALPH_MAC_QUICKSTART.md | ✅ Multi-task | 2026-01-17 |
| SCRIPTS.md | ✅ Multi-task | 2026-01-17 |
| INDEX.md | ✅ Current | 2026-01-17 |

**Total Documentation**: ~3,000 lines across 9 files
**Scripts**: 14 production-ready scripts in `.ralph/core/scripts/` and `.ralph/backends/`
**Status**: ✅ Ready for production use with multi-task support

---

## 🗂️ Archived Documentation

Older documentation (outdated single-task structure) has been archived to `archived-scripts/old-docs/`:

- RALPH_CLI_SUMMARY.md
- RALPH_MAC_CORPORATE_RESEARCH.md
- RALPH_DECISION_GUIDE.md
- RALPH_AUTONOMOUS_WSL.md
- REAL_RALPH_COMPLETE.md

See `archived-scripts/old-docs/README.md` for details.

---

## ⚖️ License & Credits

**Original Concept**: Geoffrey Huntley - <https://ghuntley.com/ralph/>
**Implementation**: Adapted for cursor-agent and Aider
**Structure**: Multi-task with isolated state

**License**: MIT (scripts), CC-BY-SA (documentation)

---

**You now have everything you need for autonomous Ralph on any platform!** 🚀

**Start here**:

- Windows/WSL: [SETUP.md](SETUP.md)
- Mac: [RALPH_MAC_QUICKSTART.md](RALPH_MAC_QUICKSTART.md)
- CLI-only: [RALPH_CLI_ONLY.md](RALPH_CLI_ONLY.md)
- Quick commands: [QUICKREF.md](QUICKREF.md)

**Good luck!** 🎯
