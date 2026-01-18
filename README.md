# Ralph Wiggum - Autonomous AI Development Assistant

> **"I'm helping! I'm Ralph!"** - Autonomous AI-driven development for multi-day tasks

Ralph Wiggum is an autonomous development framework that enables AI agents to work on complex, multi-day tasks with minimal human intervention. Think of it as "go AFK development" - define your task, let Ralph work, come back to completed features.

## 🎯 Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/your-org/ethan-dev-tools.git
cd ethan-dev-tools/ralph

# 2. Choose your backend
cd backends/cursor-agent    # Cursor IDE (recommended for personal use)
cd backends/copilot-cli     # GitHub Copilot (corporate-approved)
cd backends/aider           # Anthropic Claude (personal API)

# 3. Run setup
./setup.sh

# 4. Create and run a task
../../core/scripts/ralph-task-manager.sh create my-first-task
../../core/scripts/ralph-autonomous.sh my-first-task
```

## 📁 Repository Structure

```
ralph/
├── core/                    # Backend-agnostic Ralph core
│   ├── scripts/            # Core automation scripts
│   ├── docs/               # Documentation
│   └── templates/          # Task templates
│
├── backends/               # AI backend implementations
│   ├── cursor-agent/      # Cursor IDE integration
│   ├── copilot-cli/       # GitHub Copilot CLI
│   └── aider/             # Aider + Anthropic API
│
└── examples/              # Example tasks and use cases
```

## 🤖 Backends Comparison

| Backend | Best For | Requires | Corporate OK? | Cost |
|---------|----------|----------|---------------|------|
| **cursor-agent** | Personal dev, Cursor users | Cursor IDE license | ⚠️ Maybe | Included in license |
| **copilot-cli** | Corporate environments | GitHub Copilot license | ✅ Yes | Included in license |
| **aider** | Personal projects, SSH/CLI | Anthropic API key | ❌ No | Pay-per-use |

### Cursor Agent (Recommended for Personal Use)
- Tightly integrated with Cursor IDE
- Excellent AI quality (Claude Sonnet)
- Easiest setup
- **Use when**: You have Cursor and work on personal projects

### GitHub Copilot CLI (Corporate-Approved)
- Uses company's existing GitHub Copilot contract
- Data stays in GitHub/Microsoft infrastructure
- Enterprise audit logging available
- **Use when**: Working on corporate projects, need compliance

### Aider (CLI Alternative)
- Pure CLI, works over SSH
- Direct Anthropic API access
- Good for headless environments
- **Use when**: No GUI access, personal API key available

## 🚀 Features

- **Autonomous Loops**: AI works iteratively without human intervention
- **Multi-Task Support**: Work on multiple tasks simultaneously
- **Cost Tracking**: Monitor API usage and estimated costs
- **Context Rotation**: Handle multi-day tasks with automatic summarization
- **Safety Features**: Automatic branching, rollback capability
- **Dependency Management**: Automatic installation of required tools
- **Progress Tracking**: Detailed logs and progress reports

## 📚 Documentation

- [Core Documentation](./core/docs/README.md)
- [Backend Setup Guides](./backends/README.md)
- [Task Writing Guide](./core/docs/RALPH_RULES.md)
- [Quick Reference](./core/docs/QUICKREF.md)
- [Security & Secrets](./core/docs/SECRET_MANAGEMENT.md)

## 🛠️ Requirements

### All Backends
- Git
- Bash (WSL on Windows, native on Mac/Linux)
- Basic dev tools (curl, jq, etc.)

### Backend-Specific
- **cursor-agent**: Cursor IDE, cursor-agent CLI
- **copilot-cli**: GitHub Copilot license, `@github/copilot` npm package
- **aider**: Python 3.8+, Anthropic API key

## 💡 Example Use Cases

### Personal Development
```bash
# Use Cursor backend for personal projects
cd backends/cursor-agent
./setup.sh
ralph-autonomous my-feature-task
```

### Corporate Development
```bash
# Use Copilot backend for work projects
cd backends/copilot-cli
./setup.sh
ralph-copilot my-corp-task
```

### Headless/SSH Environments
```bash
# Use Aider backend for CLI-only
cd backends/aider
./setup.sh
ralph-aider my-server-task
```

## 🎓 Learning Resources

- [Original Ralph Wiggum Technique](https://ghuntley.com/ralph/) by Geoffrey Huntley
- [Task Writing Best Practices](./core/docs/RALPH_RULES.md)
- [Anti-Patterns to Avoid](./core/docs/ANTIPATTERNS.md)

## 🤝 Contributing

This is a personal tool collection. If you find it useful, feel free to fork and adapt!

## 📜 License

MIT License - See LICENSE file for details

## 🙏 Credits

- Original Ralph Wiggum technique: [Geoffrey Huntley](https://ghuntley.com)
- Multi-task enhancements: Ethan (this repo)
- Copilot backend: Research and implementation by Ralph itself 🤖

---

**Status**: Active development
**Version**: 2.0 (Multi-backend support)
**Last Updated**: 2026-01-17
