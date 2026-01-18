# GitHub Copilot CLI Backend

Uses GitHub Copilot CLI for autonomous development in corporate environments.

## When to Use This Backend

✅ **Best for:**
- Corporate development environments
- Teams with GitHub Copilot licenses
- Security/compliance-conscious organizations
- CLI-only or SSH environments

❌ **Not ideal for:**
- Personal projects without Copilot license
- Environments without GitHub Copilot access

## Prerequisites

- Active **GitHub Copilot license** (Individual, Business, or Enterprise)
- GitHub CLI (`gh`) installed and authenticated
- `@github/copilot` npm package OR new `copilot` CLI

## Setup

```bash
# 1. Install GitHub CLI
# Ubuntu/Debian:
sudo apt-get install gh

# Mac:
brew install gh

# 2. Authenticate
gh auth login

# 3. Install Copilot CLI
npm install -g @github/copilot

# OR install new copilot CLI
# npm: npm install -g copilot-cli
# brew: brew install github/copilot/copilot
# winget: winget install GitHub.Copilot

# 4. Verify
copilot --version
# or
gh copilot --help
```

## Usage

```bash
# Create a task
../../core/scripts/ralph-task-manager.sh create my-task

# Edit the task
nano ~/.ralph/active/my-task/TASK.md

# Run with Copilot backend
./ralph-copilot.sh my-task

# Specify model
RALPH_COPILOT_MODEL=claude ./ralph-copilot.sh my-task
RALPH_COPILOT_MODEL=gpt ./ralph-copilot.sh my-task
```

## Environment Variables

```bash
# Model selection
RALPH_COPILOT_MODEL=claude-sonnet  # Claude Sonnet 4.5 (default)
RALPH_COPILOT_MODEL=claude         # Claude 4
RALPH_COPILOT_MODEL=gpt            # GPT-5

# Advanced options
RALPH_COPILOT_FALLBACK=false       # Disable model fallback
RALPH_COPILOT_AUTO_APPROVE=true    # Auto-approve safe operations
RALPH_COPILOT_USE_ACP=false        # Use ACP mode (experimental)
```

## Corporate Compliance

### Security Features

✅ **Data stays in GitHub/Microsoft infrastructure**
✅ **Enterprise audit logging** available (90+ days)
✅ **No training on your code** (prompts not retained)
✅ **Uses existing corporate contract**
✅ **IT/Legal pre-approved** (if Copilot already approved)

### Approval Checklist

Before using in corporate environment:

- [ ] Verify GitHub Copilot is approved for your org
- [ ] Check if CLI usage is explicitly allowed
- [ ] Review data retention policies
- [ ] Confirm audit logging is enabled
- [ ] Get manager awareness/approval
- [ ] Test with non-sensitive code first

See `COPILOT_BACKEND.md` for full compliance documentation.

## Testing

**⚠️ IMPORTANT**: This backend is **UNTESTED** and requires validation on a machine with an active Copilot license.

Testing guide: `COPILOT_TESTING.md`

### Testing Phases

1. **Installation Validation**: Verify copilot CLI works
2. **Basic Commands**: Test suggest/explain
3. **Single Iteration**: Run one loop iteration
4. **Multi-Iteration**: Test autonomous behavior
5. **Error Handling**: Test failures and recovery
6. **Premium Tracking**: Verify quota monitoring
7. **Full Task**: Complete real task end-to-end

## Documentation

- `COPILOT_BACKEND.md` - Complete setup and usage guide
- `COPILOT_TESTING.md` - Testing procedures
- `RESEARCH_FINDINGS.md` - Research on Copilot CLI capabilities
- `DESIGN.md` - Implementation design decisions

## Known Limitations

- Requires active Copilot license to run
- New copilot CLI (post Oct 2025) may have bugs
- ACP mode is experimental
- Some models may use "premium requests" quota

See GitHub issues: #979, #989, #934, #1004

## Notes

- This backend was designed through research and documentation
- Untested on machines with Copilot licenses
- Corporate MacBook testing recommended
- Report issues for future improvements

---

**Status**: Research & Design Complete, Testing Required
**Maintained**: Active
**Version**: 1.0 (Untested)
**Last Updated**: 2026-01-17
