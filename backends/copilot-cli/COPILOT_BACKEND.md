# GitHub Copilot Backend for Ralph

**Status**: UNTESTED - Requires active GitHub Copilot license
**Version**: 1.0.0

---

## Overview

`ralph-copilot.sh` is a corporate-friendly alternative to `ralph-aider.sh` for running Ralph autonomous loops. It uses GitHub Copilot CLI instead of Aider + Anthropic API, making it suitable for corporate environments where personal AI API keys are not allowed.

### When to Use Copilot Backend

| Scenario | Recommended Backend |
|----------|---------------------|
| Corporate laptop with Copilot license | **ralph-copilot.sh** |
| Personal machine with Anthropic API key | ralph-aider.sh |
| Development machine with Cursor | Cursor agent (native) |
| Offline/air-gapped environment | Not supported |

---

## Setup Instructions

### Prerequisites

1. **Active GitHub Copilot subscription** (via corporate or personal account)
2. **GitHub CLI** (`gh`) or **Copilot CLI** (`copilot`)
3. **Corporate GitHub authentication** (if using corporate account)

### Installation

#### Option 1: New Copilot CLI (Recommended)

```bash
# npm (cross-platform)
npm install -g @github/copilot

# Homebrew (macOS/Linux)
brew install copilot-cli

# WinGet (Windows)
winget install GitHub.Copilot

# Install script (macOS/Linux)
curl -fsSL https://gh.io/copilot-install | bash

# Verify installation
copilot --version
```

#### Option 2: GitHub CLI Extension (Deprecated)

```bash
# Install gh copilot extension
gh extension install github/gh-copilot

# Verify
gh copilot --help
```

### Authentication

```bash
# For new copilot-cli
copilot /login

# For gh copilot extension
gh auth login
# Select GitHub.com
# Use browser authentication
# Grant copilot permissions
```

### Verify Access

```bash
# Test basic functionality
echo "Hello, are you working?" | copilot

# Check available models
copilot /model
```

---

## Usage

### Basic Usage

```bash
# Run on a Ralph task
./ralph-copilot.sh my-task-name

# Example
./ralph-copilot.sh ralph-enhancement
```

### Environment Variables

| Variable | Values | Default | Description |
|----------|--------|---------|-------------|
| `RALPH_COPILOT_MODEL` | claude-sonnet, claude, gpt | claude-sonnet | Model to use |
| `RALPH_COPILOT_FALLBACK` | true, false | false | Fall back to CLI mode if ACP fails |
| `RALPH_COPILOT_AUTO_APPROVE` | true, false | true | Auto-approve safe operations |
| `RALPH_COPILOT_USE_ACP` | true, false | false | Use experimental ACP mode |

### Model Options

**Premium Models** (count against quota):
- `claude-sonnet` - Claude Sonnet 4.5 (default, best quality)
- `claude` - Claude 4
- `gpt` - GPT-5

**Free Tier Models** (0x multiplier):
- `gpt-4.1`
- `gpt-5-mini`
- `gpt-4o`

### Examples

```bash
# Use Claude 4 instead of default
RALPH_COPILOT_MODEL=claude ./ralph-copilot.sh my-task

# Use free tier model
RALPH_COPILOT_MODEL=gpt-4.1 ./ralph-copilot.sh my-task

# Enable experimental ACP mode
RALPH_COPILOT_USE_ACP=true ./ralph-copilot.sh my-task

# Enable fallback to CLI if ACP fails
RALPH_COPILOT_USE_ACP=true RALPH_COPILOT_FALLBACK=true ./ralph-copilot.sh my-task
```

---

## Security Considerations

### Data Flow

```
Developer Terminal → Copilot CLI → GitHub API → AI Models
                                        ↓
                               GitHub/Microsoft Infrastructure
```

**Key Points**:
- All requests go through GitHub/Microsoft infrastructure
- No direct connection to third-party AI providers
- GitHub acts as proxy to underlying models
- Same data path as IDE Copilot

### Compared to Aider + Anthropic API

| Aspect | Copilot CLI | Aider + Anthropic |
|--------|-------------|-------------------|
| **Data Destination** | GitHub/Microsoft | Anthropic (external) |
| **API Key Management** | GitHub OAuth/PAT | Personal API key |
| **Audit Logging** | Built-in (Enterprise) | DIY implementation |
| **Corporate Control** | Org-level policies | None |
| **Compliance Certs** | SOC2, ISO 27001 | Anthropic's certs |
| **Billing** | Copilot subscription | Usage-based API |

### Enterprise Features

| Feature | Availability |
|---------|--------------|
| Org-level enable/disable | GitHub Copilot org settings |
| Audit logging | GitHub Enterprise |
| Custom knowledge bases | Copilot Enterprise |
| Policy controls | Organization settings |
| Model restrictions | Admin configurable |

---

## Corporate Approval Checklist

If your organization already has GitHub Copilot approved for IDE use, **no additional approval should be needed** for CLI use - it's the same infrastructure and data flow.

### If New Approval is Needed

Use this checklist when requesting approval:

```markdown
## GitHub Copilot CLI Approval Request

### Tool Information
- Name: GitHub Copilot CLI
- Vendor: GitHub/Microsoft
- Version: v0.0.384+
- Cost: Included in existing Copilot subscription

### Data Handling
- [x] Data processed by GitHub/Microsoft only
- [x] Enterprise audit logging available
- [x] No personal API keys required
- [x] Org-level policy controls available

### Security
- [x] SOC 2 Type II certified
- [x] ISO 27001 certified
- [x] Uses existing GitHub authentication
- [x] Same security model as IDE Copilot

### Compliance
- [x] GDPR compliant
- [x] Enterprise data retention controls
- [x] Audit log export available

### Risk Assessment
- Overall Risk: LOW
- Justification: Same infrastructure as already-approved IDE Copilot
```

### Who to Contact

1. **IT Security**: For data flow review
2. **Legal/Compliance**: For DPA review (if needed)
3. **Manager**: For use case approval

---

## Comparison to Other Backends

| Feature | Cursor Agent | ralph-aider.sh | ralph-copilot.sh |
|---------|--------------|----------------|------------------|
| **Corporate Approved** | ✅ If Cursor OK | ❌ Personal API | ✅ Contract |
| **CLI-Only** | ❌ Needs Cursor | ✅ Pure CLI | ✅ Pure CLI |
| **Data Flow** | To Cursor | To Anthropic | To GitHub |
| **Cost** | Cursor license | API usage ($) | Copilot license |
| **Model Quality** | Excellent | Excellent | Excellent |
| **Autonomous** | ✅ Proven | ✅ Proven | ⚠️ UNTESTED |
| **MCP Support** | ✅ | ❌ | ✅ |
| **Programmatic API** | ❌ | ✅ | ✅ (--acp) |

---

## Testing Requirements

This script is **UNTESTED** because it requires an active Copilot license that is not available on the development machine.

**To validate this script**:
1. Use a machine with active GitHub Copilot subscription
2. Follow the testing guide in `COPILOT_TESTING.md`
3. Report findings and update this documentation

---

## Logs and Tracking

### Activity Log

```bash
cat .ralph/active/<task>/activity.log
```

### Premium Request Tracking

```bash
cat .ralph/active/<task>/premium_requests.log
```

### View Commits

```bash
git log --oneline --grep='ralph(<task>):'
```

---

## Known Limitations

| Limitation | Issue | Workaround |
|------------|-------|------------|
| ACP mode bugs | #989 | Use CLI mode (default) |
| Non-interactive context | #979 | Pass full context in prompt |
| No plan mode | #934 | Manual criterion parsing |
| No prompt files | #1004 | Use project instructions |
| Auto-compaction | #947 | Keep iterations focused |

---

## Troubleshooting

### "Copilot CLI not found"

```bash
# Install with npm
npm install -g @github/copilot

# Or with brew
brew install copilot-cli
```

### "Not authenticated"

```bash
# Authenticate
copilot /login

# Or for gh extension
gh auth login
```

### "Rate limit exceeded"

The script has built-in retry logic with exponential backoff. If persistent:
- Switch to a free tier model: `RALPH_COPILOT_MODEL=gpt-4.1`
- Wait for quota reset
- Check your premium request count: `cat premium_requests.log`

### "Stuck on same criterion"

The script detects when it's stuck (3 attempts on same criterion). If this happens:
- Check the guardrails file for the lesson learned
- Manually investigate the criterion
- Consider simplifying the criterion

---

## References

- [GitHub Copilot CLI Documentation](https://docs.github.com/copilot/concepts/agents/about-copilot-cli)
- [Copilot CLI Repository](https://github.com/github/copilot-cli)
- [Ralph Research Findings](../active/ralph-copilot-backend/RESEARCH_FINDINGS.md)
- [Ralph Design Document](../active/ralph-copilot-backend/DESIGN.md)
