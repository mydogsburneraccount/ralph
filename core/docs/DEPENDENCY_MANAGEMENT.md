# Ralph Dependency Management System

## Overview

A comprehensive dependency management system for Ralph that prevents the "20-iteration dependency check loop" problem by declaring, checking, and installing dependencies upfront. **Now uses pipx for Python CLI tools following modern best practices.**

## Problem Solved

**Before**: Ralph tasks would run for many iterations trying to use tools that weren't installed (like the ralph-enhancement task that ran 20 iterations just checking if Aider was available).

**After**: Ralph checks all dependencies before starting work, offers to install them with the correct method (pipx for CLI tools, pip for libraries), and fails fast with clear instructions if dependencies can't be satisfied.

## Key Improvements

### pipx Integration

The system now automatically uses **pipx** for Python CLI tools (like aider, black, pytest) and regular **pip** for libraries (like requests, pyyaml). This provides:

- **Isolated environments** for each CLI tool
- **No dependency conflicts** between tools
- **Easier management** (pipx uninstall, pipx upgrade)
- **Best practices** alignment with PEP 668 (externally-managed environments)

### WSL Optimizations

- Auto-detection of WSL environment
- User-level installs in `~/.local/bin` (no sudo needed for Python/npm tools)
- Automatic PATH configuration
- WSL-specific Docker handling

### Dynamic Dependency Helper

New `ralph-install-dependency` command allows Ralph agents to install dependencies on-the-fly:

```bash
ralph-install-dependency system jq
ralph-install-dependency python requests
ralph-install-dependency pipx aider-chat
ralph-install-dependency npm typescript
```

## Problem Solved

**Before**: Ralph tasks would run for many iterations trying to use tools that weren't installed (like the ralph-enhancement task that ran 20 iterations just checking if Aider was available).

**After**: Ralph checks all dependencies before starting work, offers to install them, and fails fast with clear instructions if dependencies can't be satisfied.

## Components

### 1. Dependency Declaration Format

Tasks declare dependencies in YAML frontmatter:

```yaml
---
dependencies:
  system:
    - docker
    - jq
  python:
    - aider-chat
    - pytest>=7.0
  npm:
    - typescript
  check_commands:
    - docker ps
    - aider --version
---
```

### 2. Dependency Management in ralph-autonomous.sh

**New Functions Added**:

- `parse_task_dependencies()` - Extracts dependencies from TASK.md frontmatter
- `detect_package_manager()` - Auto-detects apt/yum/brew
- `command_exists()` - Checks if a command is available
- `install_system_package()` - Installs system packages
- `install_python_package()` - Installs Python packages
- `install_npm_package()` - Installs npm packages
- `verify_check_command()` - Runs verification commands
- `prompt_install()` - Interactive install prompts
- `check_and_install_dependencies()` - Main orchestration function

**Integration Point**: Dependencies are checked right before the main loop starts (after RAG check, before first iteration).

### 3. Base Toolset Installer

`ralph-base-toolset.sh` - Installs standard development tools:

- **System packages**: curl, wget, git, jq, unzip, ca-certificates, build-essential
- **Python environment**: 
  - Python 3, pip, pipx
  - CLI tools via pipx: pytest, black, ruff, mypy, ipython (isolated)
  - Libraries via pip: requests, pyyaml, python-dotenv
- **Node.js environment**: 
  - Node.js, npm (with user-level global installs)
  - Core packages: typescript, prettier
  - Optional packages: eslint, vitest, @types/node
  - **Note**: Uses vitest instead of jest (no deprecated dependencies)
- **Docker** (optional): Full Docker installation with daemon setup
- **Dependency helper**: `ralph-install-dependency` command for on-the-fly installs

**Best Practices Applied**:
- pipx for Python CLI tools (isolated environments)
- User-level installs (`~/.local/bin`) instead of system-wide
- Automatic PATH configuration
- WSL-specific optimizations
- Modern npm packages (vitest instead of deprecated jest)

### 4. Environment Variables

- `RALPH_AUTO_INSTALL=prompt` (default) - Ask before installing each dependency
- `RALPH_AUTO_INSTALL=true` - Install all dependencies automatically
- `RALPH_AUTO_INSTALL=false` - Check only, fail if missing
- `RALPH_SKIP_DEPS=true` - Skip all dependency checks

### 5. Documentation

- **RALPH_RULES.md** - Complete dependency declaration guide with examples
- **TASK_TEMPLATE.md** - Template with dependency examples
- **DEPENDENCY_TESTING.md** - Comprehensive test procedures
- **QUICKREF.md** - Updated with dependency commands

## Usage Examples

### Declare Dependencies in Task

```yaml
---
dependencies:
  python:
    - aider-chat  # Installed via pipx (CLI tool)
    - requests    # Installed via pip (library)
  check_commands:
    - aider --version
---
```

### Run with Different Modes

```bash
# Prompt mode (default) - asks before installing
./ralph-autonomous.sh my-task

# Auto-install mode - installs everything automatically
RALPH_AUTO_INSTALL=true ./ralph-autonomous.sh my-task

# Check-only mode - fails if dependencies missing
RALPH_AUTO_INSTALL=false ./ralph-autonomous.sh my-task

# Skip dependencies - for testing or when dependencies already verified
RALPH_SKIP_DEPS=true ./ralph-autonomous.sh my-task
```

### Install Base Toolset

```bash
# One-time setup of standard tools
cd .ralph/scripts
sudo ./ralph-base-toolset.sh
```

### Install Dependencies On-The-Fly

```bash
# The helper is created by ralph-base-toolset.sh
ralph-install-dependency system jq
ralph-install-dependency python requests       # Library
ralph-install-dependency pipx aider-chat      # CLI tool
ralph-install-dependency npm typescript
```

## How It Prevents the 20-Iteration Loop

**Old Behavior** (ralph-enhancement task):

```
Iteration 1-20: Check if aider available → Not found → Document this → Repeat
```

**New Behavior**:

```
Pre-check: Check if aider available → Not found → Offer to install → Install or fail fast
Iteration 1: Start actual work with all dependencies satisfied
```

## Benefits

1. **Fail Fast** - Know about missing dependencies immediately, not after 20 iterations
2. **Clear Instructions** - Automatic install with correct method (pipx vs pip) or clear manual commands
3. **No Wasted Iterations** - Don't burn API calls checking dependencies repeatedly
4. **Better Testing** - Dependencies are part of the task definition
5. **Reproducibility** - Anyone can run the task with correct dependencies
6. **Documentation** - Dependencies are self-documenting in TASK.md
7. **Isolation** - CLI tools installed via pipx don't conflict with each other
8. **Best Practices** - Follows PEP 668, uses user-level installs, proper PATH management

## Files Modified/Created

### Modified Files

- `.ralph/scripts/ralph-autonomous.sh` - Added ~300 lines of dependency management
- `.ralph/docs/RALPH_RULES.md` - Added dependency declaration documentation
- `.ralph/docs/QUICKREF.md` - Added dependency commands
- `.ralph/active/ralph-enhancement/TASK.md` - Added dependency declarations

### New Files

- `.ralph/scripts/ralph-base-toolset.sh` - Base toolset installer (370 lines)
- `.ralph/scripts/test-dependency-parsing.sh` - Dependency parsing tests
- `.ralph/docs/TASK_TEMPLATE.md` - Task template with dependencies
- `.ralph/docs/DEPENDENCY_TESTING.md` - Comprehensive test guide

## Testing

Run the test script to verify dependency parsing:

```bash
./ralph/scripts/test-dependency-parsing.sh
```

For comprehensive testing in a fresh WSL environment, see `.ralph/docs/DEPENDENCY_TESTING.md`.

## Future Enhancements

Possible improvements:

- Cache dependency check results between iterations
- Support for more package managers (pacman, zypper, etc.)
- Dependency version locking (requirements.txt style)
- Offline dependency bundles for air-gapped environments
- Integration with container-based isolation
- pipx injection for adding packages to existing tools
- Auto-detection of more CLI tools that should use pipx

## Rollback

If this system causes issues:

```bash
git checkout HEAD~1 .ralph/scripts/ralph-autonomous.sh
```

Or revert the entire feature:

```bash
git log --oneline | grep "dependency management"  # Find commit hash
git revert <commit-hash>
```

---

**Implementation Date**: 2026-01-17  
**Last Updated**: 2026-01-17 (added pipx support and WSL optimizations)  
**Status**: ✅ Complete and tested  
**Impact**: Prevents wasted iterations on dependency issues, follows best practices
