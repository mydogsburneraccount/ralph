# Ralph Task: VS Code + Copilot Corporate Mac Setup

## Overview

Set up VS Code with GitHub Copilot on a corporate Mac to achieve the closest experience to Claude Code, using Copilot as the AI model backend.

**Target**: Corporate Mac with VS Code and GitHub Copilot license
**Goal**: Agentic coding experience comparable to Claude Code

---

## Ralph Loop Command

```bash
/ralph-loop "Execute the VS Code + Copilot corporate Mac setup task.

Read .ralph/tasks/vscode-copilot-corporate-mac.md for full instructions.
Work through each phase, verifying completion via commands where possible.
Document findings in .ralph/tasks/vscode-copilot-setup-results.md as you go.
Reference .ralph/guardrails.md for learned lessons.

Output <promise>COPILOT SETUP COMPLETE</promise> when all verifiable phases done." --completion-promise "COPILOT SETUP COMPLETE" --max-iterations 15
```

---

## Phase 1: Prerequisites Verification

**Run on corporate Mac:**

```bash
# Verify VS Code installed
code --version

# Verify GitHub CLI installed (for auth)
gh --version

# Verify Copilot CLI installed
copilot --version || echo "Need to install copilot-cli"

# Check GitHub authentication
gh auth status
```

**If missing, install:**
```bash
# VS Code (if not installed)
brew install --cask visual-studio-code

# GitHub CLI
brew install gh

# Copilot CLI (agentic terminal tool)
npm install -g @github/copilot
# OR
brew install copilot-cli
```

---

## Phase 2: VS Code Copilot Extension Setup

**Install/Update Extensions:**
```bash
# Install GitHub Copilot extension
code --install-extension GitHub.copilot

# Install GitHub Copilot Chat extension
code --install-extension GitHub.copilot-chat

# Verify installed
code --list-extensions | grep -i copilot
```

**Expected output:**
```
GitHub.copilot
GitHub.copilot-chat
```

---

## Phase 3: Enable Agent Mode

**VS Code settings.json additions:**

```json
{
  "chat.agent.enabled": true,
  "github.copilot.chat.agent.runTasks": true,
  "github.copilot.chat.agent.autoFix": true,
  "github.copilot.editor.enableAutoCompletions": true,
  "github.copilot.enable": {
    "*": true
  }
}
```

**Verify via command:**
```bash
# Check if settings exist (macOS path)
grep -l "chat.agent.enabled" ~/Library/Application\ Support/Code/User/settings.json && echo "Agent mode configured"
```

**Manual verification:**
1. Open VS Code
2. Open Chat view: `Cmd+Shift+I`
3. Verify "Agent" appears in mode selector dropdown
4. Verify "Plan", "Ask", "Edit" modes also available

---

## Phase 4: Copilot CLI Authentication

```bash
# Authenticate copilot-cli with corporate GitHub
copilot /login

# Verify authentication
copilot /whoami

# Check available models
copilot /model
```

**Expected models (2026):**
- Claude Sonnet 4.5 (default, best quality)
- Claude 4
- GPT-5
- gpt-4.1, gpt-5-mini, gpt-4o (free tier)

---

## Phase 5: Project-Level Configuration

**Create `.github/copilot-instructions.md`:**

This file provides project context to Copilot (like CLAUDE.md for Claude Code).

```markdown
# Copilot Project Instructions

## Project Overview
[Describe project here]

## Code Style
- [Language-specific conventions]
- [Formatting preferences]

## Architecture
- [Key patterns]
- [Directory structure]

## Testing
- [Test framework]
- [How to run tests]

## Important Files
- [Key configuration files]
- [Entry points]
```

**Verify:**
```bash
test -f .github/copilot-instructions.md && echo "Project instructions configured"
```

---

## Phase 6: MCP Server Setup (Optional - Enhanced Capabilities)

**For Claude Code-like MCP integration via Copilot:**

```bash
# Install copilot-mcp-server bridge
npx -y @trishchuk/copilot-mcp-server
```

**Configure in VS Code MCP settings:**
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

---

## Phase 7: Workflow Configuration

### Agent Mode Workflow (VS Code)

1. **Start Agent Mode**: `Cmd+Shift+I` → Select "Agent"
2. **Describe task**: Natural language request
3. **Review plan**: Agent shows planned changes
4. **Approve/modify**: Accept or adjust
5. **Monitor**: Watch agent execute, course-correct if needed

### Terminal Workflow (Copilot CLI)

```bash
# Interactive mode
copilot

# Direct prompt
echo "Explain this error: [paste error]" | copilot

# With specific model
COPILOT_MODEL=gpt-4.1 copilot  # Free tier
```

### Batch/Automation Mode (ACP)

```bash
# Programmatic control mode
copilot --acp
```

---

## Phase 8: Verification Tests

**Test 1: Agent Mode Works**
```bash
# In VS Code Chat (Agent mode):
# Prompt: "Create a hello.js file that prints 'Hello from Copilot Agent'"
# Verify file created
test -f hello.js && node hello.js
```

**Test 2: Copilot CLI Works**
```bash
echo "What is 2+2?" | copilot
```

**Test 3: Project Instructions Loaded**
```bash
# In VS Code Chat:
# Prompt: "What are the project instructions for this workspace?"
# Should reference .github/copilot-instructions.md content
```

---

## Comparison: Claude Code vs VS Code + Copilot

| Feature | Claude Code | VS Code + Copilot |
|---------|-------------|-------------------|
| Agent Mode | ✅ Native | ✅ Agent mode |
| Terminal CLI | ✅ claude | ✅ copilot |
| MCP Support | ✅ Native | ✅ Via bridge |
| Project Instructions | CLAUDE.md | .github/copilot-instructions.md |
| Model | Claude Opus 4.5 | Claude Sonnet 4.5 (via Copilot) |
| Autonomous Loops | ✅ ralph-loop | ⚠️ Manual or ACP mode |
| Corporate Approved | ⚠️ Depends | ✅ Usually |
| Edit Mode | ✅ | ✅ Edit mode |
| Plan Mode | ✅ | ✅ Plan mode |

---

## Known Limitations

| Limitation | Workaround |
|------------|------------|
| No native ralph-loop | Use ACP mode for automation |
| Context window smaller | Keep prompts focused |
| Premium request limits | Use free tier models (gpt-4.1) |
| No CLAUDE.md | Use .github/copilot-instructions.md |

---

## Cost Optimization

**Premium Request Limits (2026):**
| Plan | Requests/Month |
|------|----------------|
| Copilot Free | 0 |
| Copilot Pro | 300 |
| Copilot Pro+ | 1,500 |

**Free Tier Models (0x multiplier):**
- gpt-4.1
- gpt-5-mini
- gpt-4o

Use free tier for routine tasks, premium for complex work.

---

## Success Criteria Checklist

- [ ] VS Code installed: `code --version` succeeds
- [ ] Copilot extensions installed: `code --list-extensions | grep copilot` shows both
- [ ] Agent mode enabled: settings.json has `chat.agent.enabled: true`
- [ ] Copilot CLI installed: `copilot --version` succeeds
- [ ] CLI authenticated: `copilot /whoami` shows corporate account
- [ ] Project instructions exist: `.github/copilot-instructions.md` created
- [ ] Agent mode functional: Can create files via Agent mode
- [ ] CLI functional: Can get responses from `echo "test" | copilot`

---

## References

- [VS Code Agent Mode](https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode)
- [VS Code Agents Overview](https://code.visualstudio.com/docs/copilot/agents/overview)
- [Copilot CLI Docs](https://docs.github.com/copilot/concepts/agents/about-copilot-cli)
- [Unified Agent Experience](https://code.visualstudio.com/blogs/2025/11/03/unified-agent-experience)
- [copilot-mcp-server](https://github.com/x51xxx/copilot-mcp-server)
- [Archived Research](./../_archive/2026-01-19-ralph-legacy-infrastructure/backends/copilot-cli/RESEARCH_FINDINGS.md)
