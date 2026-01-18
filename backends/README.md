# Ralph Backends

Ralph supports multiple AI backends to suit different environments and requirements.

## Quick Backend Selection

| Your Situation | Use This Backend |
|----------------|------------------|
| I have Cursor IDE | [cursor-agent](./cursor-agent/) |
| I work at a company with GitHub Copilot | [copilot-cli](./copilot-cli/) |
| I have an Anthropic API key | [aider](./aider/) |
| I need CLI-only (SSH/headless) | [aider](./aider/) or [copilot-cli](./copilot-cli/) |
| Corporate environment, need compliance | [copilot-cli](./copilot-cli/) |

## Backend Comparison

### Cursor Agent

**Pros:**
- ✅ Excellent AI quality (Claude Sonnet)
- ✅ Easiest setup
- ✅ Most mature/tested
- ✅ Full feature support

**Cons:**
- ❌ Requires Cursor IDE
- ❌ May need corporate approval
- ❌ Not CLI-only

**Best for**: Personal development, Cursor users

[→ Setup Guide](./cursor-agent/README.md)

---

### GitHub Copilot CLI

**Pros:**
- ✅ Corporate-approved (uses existing contract)
- ✅ Data stays in GitHub/Microsoft
- ✅ Enterprise audit logging
- ✅ CLI-only capable
- ✅ No personal API key needed

**Cons:**
- ❌ Requires Copilot license
- ❌ Untested (needs validation)
- ❌ New tool (may have bugs)

**Best for**: Corporate environments, compliance-focused teams

[→ Setup Guide](./copilot-cli/README.md)

---

### Aider + Anthropic

**Pros:**
- ✅ Pure CLI, works everywhere
- ✅ Excellent AI quality (Claude)
- ✅ Direct API control
- ✅ Works over SSH

**Cons:**
- ❌ Costs money (pay-per-use)
- ❌ NOT for corporate use
- ❌ Data leaves company
- ❌ Requires API key

**Best for**: Personal projects, SSH environments

[→ Setup Guide](./aider/README.md)

---

## Security Comparison

| Aspect | Cursor | Copilot | Aider |
|--------|--------|---------|-------|
| Data Location | Cursor servers | GitHub/Microsoft | Anthropic |
| Corporate Approved | ⚠️ Maybe | ✅ Yes | ❌ No |
| Audit Logging | ⚠️ Limited | ✅ Yes | ❌ No |
| Compliance | ⚠️ Varies | ✅ Good | ❌ Poor |
| Cost | License | License | Pay-per-use |

## Feature Comparison

| Feature | Cursor | Copilot | Aider |
|---------|--------|---------|-------|
| Autonomous loops | ✅ | ✅* | ✅ |
| Cost tracking | ✅ | ✅* | ✅ |
| Context rotation | ✅ | ✅* | ✅ |
| Dependency mgmt | ✅ | ✅* | ✅ |
| CLI-only | ❌ | ✅ | ✅ |
| SSH capable | ❌ | ✅ | ✅ |

*= Untested, designed but not validated

## Installation Quick Start

### Cursor Agent
```bash
cd backends/cursor-agent
./ralph-wsl-setup.sh  # Windows only
cursor-agent login
```

### Copilot CLI
```bash
cd backends/copilot-cli
npm install -g @github/copilot
gh auth login
```

### Aider
```bash
cd backends/aider
pipx install aider-chat
export ANTHROPIC_API_KEY="sk-ant-..."
```

## Switching Backends

All backends share the same task format and core scripts. To switch:

1. Tasks are stored in `~/.ralph/active/`
2. Use any backend to run the same task:
   ```bash
   cd backends/cursor-agent && ./ralph-autonomous.sh my-task
   # or
   cd backends/copilot-cli && ./ralph-copilot.sh my-task
   # or
   cd backends/aider && ./ralph-aider.sh my-task
   ```

## Contributing

Each backend has its own maintainer and status:

- **cursor-agent**: Production, actively maintained
- **copilot-cli**: Experimental, needs testing
- **aider**: Production, actively maintained

## Questions?

- General Ralph questions → See `../core/docs/`
- Backend-specific → See each backend's README
- Corporate approval → See `copilot-cli/COPILOT_BACKEND.md`
