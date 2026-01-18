# PEP 668 Handling in Ralph

## What is PEP 668?

PEP 668 introduces "externally-managed environments" for Python installations. Modern Linux distributions (Ubuntu 24.04+, Debian 12+) mark their system Python as "externally managed" to prevent pip from breaking system packages.

## The Error

```
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
```

## Ralph's Solution

Ralph now handles PEP 668 systems gracefully with a multi-tier approach:

### 1. CLI Tools → pipx (Always)

Python CLI tools are **always** installed via pipx, which creates isolated virtual environments:

```bash
pipx install aider-chat
pipx install black
pipx install pytest
```

This completely avoids PEP 668 restrictions because pipx manages its own environments.

### 2. Libraries → System Packages First

For Python libraries, Ralph tries system packages first on apt-based systems:

```bash
# Ralph tries this first
sudo apt-get install python3-requests
sudo apt-get install python3-yaml
sudo apt-get install python3-dotenv
```

**Benefits:**
- Works on PEP 668 systems
- Faster installation
- Better system integration
- Automatic updates via apt

### 3. Libraries → pip --user (Fallback)

If system package isn't available, falls back to user-level pip:

```bash
python3 -m pip install --user requests
```

### 4. Libraries → --break-system-packages (Last Resort)

Only if everything else fails:

```bash
python3 -m pip install --user requests --break-system-packages
```

## Package Name Mapping

Ralph automatically maps PyPI names to apt package names:

| PyPI Package | apt Package |
|--------------|-------------|
| requests | python3-requests |
| pyyaml | python3-yaml |
| python-dotenv | python3-dotenv |
| pytest | python3-pytest |
| black | python3-black |
| (generic) | python3-{name} |

## Usage in Ralph Scripts

### Base Toolset Installer

The base toolset now:
1. Installs pipx via apt (if available) or pip
2. Installs CLI tools via pipx
3. Installs libraries via system packages (preferred) or pip

```bash
sudo ./.ralph/scripts/ralph-base-toolset.sh
```

### Dependency Helper

The `ralph-install-dependency` helper automatically:
- Uses pipx for CLI tools
- Tries system packages for libraries on apt systems
- Falls back to pip with proper flags

```bash
ralph-install-dependency pipx aider-chat    # Always uses pipx
ralph-install-dependency python requests    # Tries apt, then pip
```

### Task Dependencies

In TASK.md, just declare what you need:

```yaml
---
dependencies:
  python:
    - aider-chat   # Detected as CLI → pipx
    - requests     # Detected as library → system pkg or pip
---
```

Ralph's `install_python_package()` function automatically:
1. Checks if it's a known CLI tool
2. Uses pipx for CLI tools
3. Uses system packages or pip for libraries

## Why This Approach?

### Pros
- **Compatible** with PEP 668 systems out of the box
- **Best practices** - pipx is the recommended way for CLI tools
- **Fast** - system packages are faster than pip
- **Reliable** - system packages are tested by distro maintainers
- **Clean** - no system Python pollution

### Cons
- System packages may be older versions
- Not all PyPI packages have apt equivalents

## When to Use --break-system-packages

**Only as a last resort!** This flag:
- Bypasses PEP 668 protection
- Can break your system Python
- Should be avoided in automation

Ralph only uses it when:
1. No system package is available
2. User-level pip install fails
3. The library is critical for the task

## Alternative: Virtual Environments

For complex projects with many dependencies, consider using a virtual environment:

```bash
# Create venv
python3 -m venv ~/.ralph-venv

# Activate and install
source ~/.ralph-venv/bin/activate
pip install requests pyyaml python-dotenv

# Use in scripts
~/.ralph-venv/bin/python script.py
```

Ralph doesn't use venvs by default because:
- CLI tools need to be globally available
- Adds complexity to task execution
- pipx provides better tool isolation

## Testing PEP 668 Handling

```bash
# Test on Ubuntu 24.04+ or Debian 12+
python3 -m pip install requests                    # Should fail
python3 -m pip install --user requests             # Should fail
python3 -m pip install --break-system-packages ... # Should work (not recommended)

# Ralph's approach
sudo apt-get install python3-requests              # Should work ✅
pipx install aider-chat                            # Should work ✅
```

## References

- [PEP 668](https://peps.python.org/pep-0668/) - Marking Python base environments as "externally managed"
- [pipx documentation](https://pypa.github.io/pipx/)
- [Debian Python Policy](https://www.debian.org/doc/packaging-manuals/python-policy/)

---

**Status**: ✅ Fully implemented in ralph-base-toolset.sh  
**Date**: 2026-01-17  
**Impact**: Ralph now works seamlessly on modern Linux distributions
