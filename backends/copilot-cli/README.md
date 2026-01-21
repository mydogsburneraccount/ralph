# GitHub Copilot CLI Backend

Uses GitHub Copilot CLI for autonomous development in corporate environments.

**Version**: 3.0.0-untested | **Status**: Implementation complete, runtime testing required

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
- Docker (optional, for sandbox mode)

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

# With programmatic mode (-p flag)
./ralph-copilot.sh my-task -p

# With Docker sandbox (recommended for --allow-all-tools)
./ralph-copilot.sh my-task --docker

# With custom agent profile
./ralph-copilot.sh my-task --agent=ralph

# Specify model
RALPH_COPILOT_MODEL=claude-sonnet ./ralph-copilot.sh my-task
```

## Docker Sandbox (v3.0 Feature)

Run Copilot safely with `--allow-all-tools` inside an isolated container:

```bash
# Build the sandbox image
docker build -t ralph-copilot-sandbox .

# Run with Docker sandbox
./ralph-copilot.sh my-task --docker

# Or use docker-compose directly
docker compose run --rm ralph-copilot-yolo
```

The Docker sandbox limits blast radius while enabling full tool access.

## Custom Agent Profile (v3.0 Feature)

Install the Ralph agent profile for Copilot:

```bash
# User-level (all projects)
mkdir -p ~/.copilot/agents
cp ralph.agent.md ~/.copilot/agents/

# Repository-level
mkdir -p .github/agents
cp ralph.agent.md .github/agents/
```

Then use with:
```bash
./ralph-copilot.sh my-task --agent=ralph
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

# v3.0 options
RALPH_COPILOT_USE_DOCKER=true      # Run inside Docker sandbox
RALPH_COPILOT_DOCKER_IMAGE=<img>   # Custom Docker image name
RALPH_COPILOT_DENY_TOOLS=<list>    # Comma-separated tools to deny
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
