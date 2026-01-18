# Ralph Dependency Quick Reference Card

## 🚀 Installation Commands

```bash
# First time setup
sudo ./.ralph/scripts/ralph-base-toolset.sh

# Test installation
./.ralph/scripts/test-base-toolset.sh

# Add to PATH (if needed)
export PATH="$HOME/.local/bin:$PATH"
source ~/.bashrc
```

## 📦 Installing Dependencies

### Using the Helper (Recommended)

```bash
ralph-install-dependency system jq           # System package
ralph-install-dependency python requests     # Python library
ralph-install-dependency pipx aider-chat     # Python CLI tool
ralph-install-dependency npm typescript      # npm package
```

### Manual Installation

```bash
# Python CLI tools (isolated)
pipx install aider-chat
pipx install black

# Python libraries (shared)
sudo apt-get install python3-requests        # System pkg (best)
python3 -m pip install --user requests       # User-level

# System packages
sudo apt-get install jq docker

# npm packages
npm install -g typescript
```

## 🎯 What Goes Where?

| Type | Package Manager | Location | Example |
|------|----------------|----------|---------|
| CLI Tool | pipx | `~/.local/pipx/venvs/` | aider-chat, black, pytest |
| Library | apt/pip | `/usr/lib` or `~/.local/lib` | requests, pyyaml |
| System | apt/yum | `/usr/bin` | jq, docker, git |
| npm | npm -g | `~/.local/lib/node_modules` | typescript, vitest, prettier |

## 🔧 Ralph Task Dependencies

```yaml
---
dependencies:
  system:
    - jq
    - docker
  python:
    - aider-chat   # → pipx (CLI tool)
    - requests     # → system pkg or pip (library)
  npm:
    - typescript
  check_commands:
    - aider --version
    - docker ps
---
```

## 🤖 Environment Variables

```bash
# Auto-install all dependencies
RALPH_AUTO_INSTALL=true ./ralph-autonomous.sh task

# Check only, fail if missing
RALPH_AUTO_INSTALL=false ./ralph-autonomous.sh task

# Skip dependency checks
RALPH_SKIP_DEPS=true ./ralph-autonomous.sh task
```

## 📋 Common Tasks

```bash
# List pipx packages
pipx list

# List pip packages
pip3 list --user

# List npm packages
npm list -g --depth=0

# Update a pipx tool
pipx upgrade aider-chat

# Update all pipx tools
pipx upgrade-all

# Check if PATH is correct
echo $PATH | grep ".local/bin"
```

## 🐛 Troubleshooting

### "externally-managed-environment" Error
✅ **Fixed!** Script now uses system packages or --break-system-packages automatically.

### "command not found: ralph-install-dependency"
```bash
# Re-run base toolset installer
sudo ./.ralph/scripts/ralph-base-toolset.sh

# Or add to PATH manually
export PATH="$HOME/.local/bin:$PATH"
```

### "pipx: command not found"
```bash
# Install pipx
sudo apt-get install pipx
# or
python3 -m pip install --user pipx
python3 -m pipx ensurepath
```

### pip still fails with PEP 668
```bash
# Use system packages (preferred)
sudo apt-get install python3-{package}

# Or use pipx for CLI tools
pipx install {package}

# Last resort
python3 -m pip install --user {package} --break-system-packages
```

## 📚 Decision Tree

```
Need a Python package?
│
├─ Is it a CLI tool (run from terminal)?
│  └─ YES → Use pipx
│     Example: pipx install aider-chat
│
└─ NO → It's a library
   ├─ Ubuntu/Debian?
   │  └─ YES → Try system package first
   │     └─ sudo apt-get install python3-{package}
   │
   └─ System package not available?
      └─ pip3 install --user {package}
```

## 🎓 CLI Tool vs Library

**CLI Tools** (use pipx):
- aider-chat, black, ruff, mypy
- pytest, ipython
- poetry, pipenv
- cookiecutter, pre-commit
- Any tool you run from terminal

**Libraries** (use system pkg or pip):
- requests, pyyaml, python-dotenv
- boto3, flask, django
- Any package you `import` in scripts

## 📖 Documentation

- `DEPENDENCY_MANAGEMENT.md` - Full system overview
- `DEPENDENCY_HELPER.md` - Helper command guide
- `PEP668_HANDLING.md` - PEP 668 details
- `DEPENDENCY_ARCHITECTURE.md` - Visual diagrams
- `QUICKREF.md` - All Ralph commands

---

**Quick Help**: `ralph-install-dependency` (no args shows usage)  
**Test Installation**: `./.ralph/scripts/test-base-toolset.sh`  
**Update Date**: 2026-01-17
