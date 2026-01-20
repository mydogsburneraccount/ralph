# GitHub Copilot CLI Research Findings

**Iteration**: 1
**Date**: 2026-01-17
**Status**: Research Complete

---

## Executive Summary

**Major Discovery**: The old `gh copilot` extension (suggest/explain only) was **deprecated October 25, 2025** and replaced by a new **agentic** GitHub Copilot CLI (`copilot-cli`). This new tool is significantly more capable for autonomous workflows.

### Key Findings

| Aspect | Old gh-copilot | New copilot-cli |
|--------|----------------|-----------------|
| Status | Deprecated (Oct 2025) | Active, v0.0.384 |
| Capabilities | suggest, explain only | Full agentic assistant |
| Models | Unknown | Claude Sonnet 4.5, Claude 4, GPT-5 |
| Autonomous | No | Yes (same harness as coding agent) |
| MCP Support | No | Yes (built-in + custom) |
| Programmatic API | No | `--acp` mode (Agent Client Protocol) |

---

## GitHub Copilot CLI Details

### Installation

```bash
# npm (cross-platform)
npm install -g @github/copilot

# Homebrew (macOS/Linux)
brew install copilot-cli

# WinGet (Windows)
winget install GitHub.Copilot

# Install script (macOS/Linux)
curl -fsSL https://gh.io/copilot-install | bash
```

### Available Models (as of v0.0.384)

- **Claude Sonnet 4.5** (default)
- **Claude Sonnet 4**
- **GPT-5**
- GPT-5.2-Codex (in interactive mode, not ACP mode yet)
- Gemini 3 Pro Preview (requested in #1012)

### Key Features

1. **Agentic Capabilities**: Can plan and execute complex multi-step tasks
2. **MCP Support**: Ships with GitHub MCP server, supports custom MCP servers
3. **Preview Mode**: Shows all actions before execution (user must approve)
4. **GitHub Integration**: Access repos, issues, PRs via natural language
5. **Model Selection**: `/model` slash command to switch models

### Configuration

- `copilot config` - Configuration commands
- `.github/copilot-instructions.md` - Project-level instructions
- Custom agents via `agent.md` files

---

## Automation Capabilities Assessment

### Promising: Agent Client Protocol (`--acp`)

Found in issue #989: The CLI supports `copilot --acp` mode for programmatic integration.

```
copilot --acp
```

This mode:
- Allows external clients to interact with Copilot
- Uses structured tool call IDs
- Supports permission request flows
- Currently supports Claude Sonnet 4.5, Claude Sonnet 4, GPT-5 (per #1012)

**Limitation**: Issue #989 reports tool ID inconsistencies in permission requests.

### Issue: Non-Interactive Mode Limitations

Issue #979 reports "Context data not available in non-interactive mode" - suggests non-interactive mode exists but may have reduced capabilities.

### Requested But Not Yet Implemented

| Feature | Issue | Status |
|---------|-------|--------|
| Plan mode (`copilot plan`) | #934 | Open - Feature Request |
| Prompt files (.prompt.md) | #1004 | Open - Feature Request |
| Serve mode (web interface) | #977 | Open - Feature Request |
| Auto-compact disable | #947 | Open - Feature Request |

---

## Security & Compliance Considerations

### Data Flow Architecture

```
Developer Terminal → Copilot CLI → GitHub API (api.githubcopilot.com) → AI Models
                                                    ↓
                                         GitHub/Microsoft Infrastructure
```

**Key Points**:
- All requests go to GitHub/Microsoft infrastructure
- No direct connection to third-party AI providers (OpenAI, Anthropic)
- GitHub acts as proxy to underlying model providers
- Code stays within GitHub/Microsoft network boundary

### Data Retention Policies

| Aspect | Policy |
|--------|--------|
| **Prompt Data** | Not retained for training (Enterprise) |
| **Suggestions** | Not stored permanently |
| **Telemetry** | Configurable at org level |
| **Audit Logs** | 90+ days retention (Enterprise) |

**Enterprise Controls**:
- Opt out of telemetry collection
- Disable suggestion storage
- Custom data residency (some regions)
- Content exclusions for sensitive repos

### GitHub Enterprise Audit Logging

**What's Logged**:
- Copilot feature usage events
- Model selection changes
- Authentication events
- Organization policy changes

**Access**: 
- Admin → Settings → Audit Log
- API: `gh api /orgs/{org}/audit-log?phrase=action:copilot`

### Infrastructure Compliance

| Standard | Status |
|----------|--------|
| SOC 2 Type II | ✅ Certified |
| ISO 27001 | ✅ Certified |
| GDPR | ✅ Compliant |
| HIPAA | ⚠️ BAA available for Enterprise |
| FedRAMP | ⚠️ GitHub.gov only |

### Security Comparison: Copilot CLI vs Aider

| Aspect | Copilot CLI | Aider + Anthropic |
|--------|-------------|-------------------|
| **Data Destination** | GitHub/Microsoft | Anthropic (external) |
| **API Key Management** | GitHub OAuth/PAT | Personal API key |
| **Audit Logging** | Built-in (Enterprise) | DIY implementation |
| **Data Retention** | GitHub policies | Anthropic policies |
| **Corporate Control** | Org-level policies | None |
| **Compliance Certs** | SOC2, ISO, etc. | Anthropic's certs |
| **Code Exposure** | To Microsoft/GitHub | To Anthropic |
| **Billing** | Copilot subscription | Usage-based API |

**Aider Security Considerations**:
- Sends code directly to API provider (Anthropic, OpenAI)
- API keys stored locally or in environment
- No enterprise audit logging
- User responsible for data handling compliance
- No organizational policy controls

**Copilot CLI Advantages**:
- Uses existing approved corporate relationship
- Centralized policy management
- Enterprise audit trail
- No personal API key exposure
- Same security posture as IDE Copilot

### Corporate Approval Requirements

#### If Copilot Already Approved
- **No new approvals needed** for CLI
- Uses same GitHub authentication
- Same data flow as IDE Copilot
- Communicate with IT about new interface (CLI vs IDE)

#### If New Approval Needed
1. **IT Security Review**:
   - Data flow documentation (GitHub infrastructure)
   - Compliance certifications (SOC2, ISO)
   - Audit logging capabilities
   
2. **Legal/Compliance**:
   - GitHub Enterprise agreement covers CLI
   - Data processing agreement (DPA) review
   - Data residency requirements check
   
3. **Manager Approval**:
   - Cost: Included in Copilot subscription
   - Use case: Development productivity
   - Risk: Low (same as IDE Copilot)

#### Approval Checklist Template

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

### Authentication Options

1. **OAuth (recommended)**: 
   ```bash
   gh auth login --web
   ```
   - Uses corporate SSO if configured
   - No secrets stored locally
   - Token managed by gh CLI

2. **Fine-grained PAT**:
   - Create at: https://github.com/settings/personal-access-tokens/new
   - Required permission: "Copilot Requests"
   - Set via `GH_TOKEN` or `GITHUB_TOKEN` env var
   - More traceable for audit purposes

### Enterprise Policy Controls

| Setting | Location | Effect |
|---------|----------|--------|
| Enable/Disable CLI | Org Copilot settings | Block CLI entirely |
| Model restrictions | Org policy | Limit available models |
| Audit retention | Enterprise settings | Log retention period |
| Content exclusions | Repo settings | Exclude sensitive repos |

---

## Comparison Matrix (Updated)

| Feature | Cursor Agent | Aider+Anthropic | Copilot CLI |
|---------|--------------|-----------------|-------------|
| Corporate Approved | ✅ If Cursor OK | ❌ Personal API | ✅ Contract |
| CLI-Only | ❌ Needs Cursor | ✅ Pure CLI | ✅ Pure CLI |
| Data Leaves Network | ⚠️ To Cursor | ❌ To Anthropic | ✅ To GitHub |
| Cost | Cursor license | $$ API usage | Copilot license |
| Model Quality | Excellent | Excellent | **Excellent** (Claude 4.5) |
| Autonomous Capable | ✅ Proven | ✅ Proven | ✅ **YES - Agentic** |
| Setup Complexity | Low | Low | Low |
| MCP Support | ✅ | ❌ | ✅ |
| Programmatic API | ❌ | ✅ | ✅ (--acp) |

---

## Research Questions Answered

### GitHub Copilot CLI

1. **Can it run in fully automated mode?**
   - Partially. `--acp` mode enables programmatic control.
   - Non-interactive mode exists but may have context limitations (#979).
   - No explicit "headless batch" mode documented yet.

2. **Context window size?**
   - Uses Claude Sonnet 4.5 by default - 200K context window.
   - Auto-compaction triggers at token thresholds (configurable requested in #947).

3. **Does it support file editing?**
   - YES - full agentic capabilities including code editing, refactoring.
   - Preview before execution (user approval required).

4. **Rate limits?**
   - Premium requests quota applies (per prompt).
   - Enterprise/org-level quotas configurable.

5. **Model selection?**
   - YES - `/model` command in interactive mode.
   - ACP mode limited to Claude 4.5, Claude 4, GPT-5 currently.

6. **Passing task context?**
   - `.github/copilot-instructions.md` for project instructions.
   - Prompt files feature requested (#1004) but not yet implemented.
   - Can read files and understand codebase context.

### Corporate Security

1. **Does it send code to GitHub servers?** - YES, same as Copilot IDE.
2. **Data retention?** - Per GitHub Copilot policies, enterprise controls available.
3. **Audit logging?** - YES, GitHub Enterprise audit logs.
4. **Compliance?** - Same as existing Copilot (SOC2, etc.).
5. **Approval process?** - If Copilot already approved, no new approvals needed.

---

## Ralph Integration Design Considerations

### Approach A: Direct CLI Wrapping

```bash
# Simple approach - pipe task to copilot
echo "Read TASK.md and complete the next unchecked criterion" | copilot
```

**Pros**: Simple, uses existing CLI
**Cons**: May have context limitations in non-interactive mode

### Approach B: ACP Mode Integration

```python
# Use --acp mode for programmatic control
import subprocess
import json

proc = subprocess.Popen(
    ['copilot', '--acp'],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE
)
# Send/receive structured messages
```

**Pros**: Full programmatic control, structured responses
**Cons**: More complex, ACP mode still evolving (issue #989)

### Approach C: MCP Server Bridge

Create an MCP server that wraps Ralph tasks, letting Copilot CLI access them natively.

**Pros**: Native integration, extensible
**Cons**: Requires MCP server development

---

## Testing Checklist (For Corp MacBook)

### Prerequisites
- [ ] Active Copilot subscription
- [ ] Corporate GitHub authentication
- [ ] `copilot-cli` installed (`npm install -g @github/copilot`)

### Basic Functionality
- [ ] `copilot` launches successfully
- [ ] `/login` authenticates with corp account
- [ ] `/model` shows available models
- [ ] Basic prompt gets response

### Agentic Capabilities
- [ ] Can read and edit files
- [ ] Can execute shell commands (with approval)
- [ ] Can plan multi-step tasks
- [ ] Understands codebase context

### Automation Testing
- [ ] Test `copilot --acp` mode
- [ ] Test piping prompts via stdin
- [ ] Test non-interactive execution
- [ ] Measure response times and quality

### Ralph Integration
- [ ] Can pass TASK.md content effectively
- [ ] Can iterate on criteria
- [ ] Quality compared to Cursor agent

---

## Recommendations

### Immediate (This Task)

1. ✅ Research complete - new Copilot CLI is viable for autonomous workflows
2. Design `ralph-copilot.sh` based on ACP mode
3. Create testing guide for corp MacBook validation

### For Corp MacBook Testing

1. Install and authenticate copilot-cli
2. Test ACP mode with simple tasks first
3. Validate context handling for TASK.md
4. Compare quality to Cursor agent on same tasks

### Long-term

1. Monitor copilot-cli development (rapid iteration - daily releases)
2. Watch for plan mode (#934) implementation
3. Consider MCP server integration for deeper Ralph integration

---

## Community & Official Resources

### MCP Servers for Copilot Integration

#### @trishchuk/copilot-mcp-server
- **Repo**: https://github.com/x51xxx/copilot-mcp-server
- **npm**: `@trishchuk/copilot-mcp-server`
- **Purpose**: MCP server bridging Claude/Cursor to GitHub Copilot CLI

**Key Features**:
- Non-interactive automation
- Safe tool execution with permissions
- Batch processing capabilities
- Streams progress updates
- Works with standard MCP clients

**Installation**:
```bash
npx -y @trishchuk/copilot-mcp-server
```

**Configuration** (for Claude Desktop):
```json
{
  "mcpServers": {
    "copilot-cli": {
      "command": "npx",
      "args": ["-y", "@trishchuk/copilot-mcp-server"],
      "env": {
        "COPILOT_MODEL": "claude-sonnet-4.5"
      }
    }
  }
}
```

### Comprehensive Guides

#### terminal-ai-toolkit
- **Repo**: https://github.com/BNLNPPS/terminal-ai-toolkit
- **Purpose**: Curated scripts and guides for terminal AI tools

**Key Insights**:
- Documents GitHub Copilot API endpoint: `https://api.githubcopilot.com`
- Model multipliers: Some models (gpt-4.1, gpt-5-mini, gpt-4o) have **0x multiplier** (don't count toward premium quota)
- Provides copilot-usage.sh script for quota checking
- Documents authentication options (OAuth, PAT)

#### github-copilot-instructions
- **Repo**: https://github.com/NKFahrni/github-copilot-instructions
- **Purpose**: Enterprise instruction sets for Copilot

**Includes**:
- Git workflow instructions
- Angular development guidelines
- C#/.NET development guidelines
- Azure Functions patterns
- Technology-specific best practices

### Enterprise Features

| Feature | Availability |
|---------|--------------|
| Org-level enable/disable | GitHub Copilot org settings |
| Audit logging | GitHub Enterprise |
| Custom knowledge bases | Copilot Enterprise |
| Policy controls | Organization settings |
| Model restrictions | Admin configurable |

### Cost Optimization

**Model Multipliers** (from terminal-ai-toolkit):
- **0x multiplier** (free): `gpt-4.1`, `gpt-5-mini`, `gpt-4o`
- Standard multiplier: Claude Sonnet 4.5, Claude 4, GPT-5

**Premium Request Limits**:
| Plan | Requests/Month |
|------|----------------|
| Copilot Free | 0 |
| Copilot Pro | 300 |
| Copilot Pro+ | 1,500 |

---

## References

- [GitHub Copilot CLI Repo](https://github.com/github/copilot-cli)
- [Official Documentation](https://docs.github.com/copilot/concepts/agents/about-copilot-cli)
- [npm Package](https://www.npmjs.com/package/@github/copilot)
- [Old gh-copilot (deprecated)](https://github.com/github/gh-copilot)
- [copilot-mcp-server](https://github.com/x51xxx/copilot-mcp-server)
- [terminal-ai-toolkit](https://github.com/BNLNPPS/terminal-ai-toolkit)
- [github-copilot-instructions](https://github.com/NKFahrni/github-copilot-instructions)

---

## Appendix: Key Issues to Watch

| Issue | Title | Relevance |
|-------|-------|-----------|
| #979 | Context data in non-interactive mode | Automation |
| #989 | ACP tool ID bug | Programmatic integration |
| #934 | Plan mode | Spec-driven workflows |
| #1004 | Prompt files | Task context injection |
| #947 | Auto-compact config | Long conversations |
| #1012 | More models in ACP | Model selection |
