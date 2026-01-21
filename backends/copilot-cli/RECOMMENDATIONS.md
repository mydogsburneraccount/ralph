# Ralph-Loop Copilot CLI Recommendations

**Date**: 2026-01-21
**Author**: Claude (via Ralph Loop)
**Status**: Research Complete

---

## Overview

This document provides researched recommendations for the complex feature gaps identified in `PARITY_ANALYSIS.md` that cannot be solved with simple code changes.

---

## Gap: In-Session Context Continuity

**Problem:** Claude Code's stop hook mechanism keeps the same session alive across iterations, preserving full context (conversation history, tool results, working memory). The Copilot backend launches a new `copilot` process for each iteration, losing all session context.

**Why It's Hard:**
- Copilot CLI has no persistent session mode
- Each invocation is stateless
- No hook/callback mechanism to intercept exit

**Options:**

### Option 1: Enhanced Prompt Injection (Current Approach)
**Effort:** Low | **Fidelity:** 70%

Already implemented in v2.0.0. Inject last 50 lines of progress log and guardrails content into each prompt. This gives Copilot visibility into previous iterations but not the actual conversation or tool outputs.

**Pros:**
- Simple, already working
- No external dependencies
- Cross-platform

**Cons:**
- No memory of actual tool calls or reasoning
- Limited to 50 lines of progress
- Copilot must re-read all files each iteration

### Option 2: ACP Mode Session Persistence
**Effort:** High | **Fidelity:** 85%

Use Copilot's `--acp` (Agent Client Protocol) mode to maintain a long-running subprocess. The script would:
1. Start `copilot --acp` once
2. Send/receive JSON messages for each iteration
3. Keep the process alive between iterations

**Pros:**
- Single session, persistent context
- Structured JSON communication
- Full control over message flow

**Cons:**
- ACP mode is experimental (issue #989 reports bugs)
- Requires significant implementation work
- Protocol documentation is sparse

**Research Needed:**
- Test ACP mode stability on corporate MacBook
- Document actual message protocol
- Evaluate context window limits

### Option 3: External Memory Store
**Effort:** Medium | **Fidelity:** 60%

Maintain external context in a structured format (JSON, SQLite) that gets serialized into each prompt.

```bash
# .ralph/memory/copilot-session.json
{
  "iterations": [...],
  "decisions": [...],
  "files_modified": [...],
  "errors_encountered": [...]
}
```

**Pros:**
- Full control over what's persisted
- Can compress/summarize older context
- Survives process crashes

**Cons:**
- Manual memory management
- Prompt size limits
- No actual conversation continuity

**Recommendation:** Start with Option 1 (already implemented). If testing reveals context issues, invest in Option 2 (ACP mode) when the protocol stabilizes.

---

## Gap: Transcript Access for Promise Detection

**Problem:** Claude Code's stop hook receives the full transcript path via JSON, enabling precise `<promise>` tag extraction from the actual assistant output. Copilot backend must capture stdout, which may be mixed with other output.

**Why It's Hard:**
- Copilot CLI writes to stdout/stderr without clear message boundaries
- No official API to get raw model output
- Output may include progress indicators, approvals, etc.

**Options:**

### Option 1: stdout Capture with tee (Current Approach)
**Effort:** Low | **Fidelity:** 80%

```bash
output=$(run_copilot_cli "$prompt" | tee /dev/tty)
detect_promise "$output" "$COMPLETION_PROMISE"
```

**Pros:**
- Simple implementation
- Already working
- Shows output to user in real-time

**Cons:**
- May capture non-model output (progress spinners, etc.)
- Could miss promise if output buffered oddly
- tee may not work in all environments

### Option 2: ACP Mode Structured Responses
**Effort:** High | **Fidelity:** 95%

ACP mode returns JSON-structured responses with clear message boundaries.

```json
{
  "type": "assistant_message",
  "content": "...<promise>DONE</promise>..."
}
```

**Pros:**
- Clean message extraction
- No mixing with progress output
- Exact parity with Claude Code

**Cons:**
- Requires ACP implementation
- Protocol may change

### Option 3: Output File Parsing
**Effort:** Medium | **Fidelity:** 75%

Direct Copilot output to a file, then parse:

```bash
copilot --model "$MODEL" < prompt.txt > output.txt 2>&1
grep -oP '<promise>.*?</promise>' output.txt
```

**Pros:**
- Reliable capture
- Can post-process at leisure

**Cons:**
- No real-time output to user
- Extra file I/O
- User loses visibility

**Recommendation:** Option 1 is sufficient for most cases. The perl regex in `detect_promise()` handles multiline matches. If issues arise, combine with Option 3 (dual output to file + tty).

---

## Gap: Stop Hook Mechanism

**Problem:** Claude Code uses native stop hooks that intercept session exit at the CLI level. Copilot CLI has no equivalent mechanism.

**Why It's Hard:**
- Stop hooks require deep CLI integration
- External scripts cannot intercept Copilot's internal exit

**Analysis:**

This is a fundamental architectural difference, not a gap to be closed:

| Aspect | Claude Code | Copilot CLI |
|--------|-------------|-------------|
| Loop control | Internal (hooks) | External (while loop) |
| Process lifetime | Single process | Multiple processes |
| Exit interception | Yes | No |
| Ctrl+C behavior | Blocked (hook) | Stops loop |

**Recommendation:** Accept the architectural difference. The external while-loop pattern is the correct approach for Copilot CLI. Focus on information transfer between iterations (progress, guardrails) rather than trying to replicate the hook mechanism.

---

## Gap: VS Code Extension Integration

**Problem:** Many corporate environments use VS Code with Copilot extension. The CLI backend doesn't integrate with VS Code's workspace context.

**Options:**

### Option 1: Standalone CLI (Current)
**Effort:** None | **Fidelity:** N/A

Keep CLI separate from VS Code. Use `.github/copilot-instructions.md` for shared instructions.

**Pros:**
- Works in any terminal
- No VS Code dependency
- Portable

**Cons:**
- No VS Code workspace integration
- Can't use VS Code's Copilot features

### Option 2: VS Code Task Integration
**Effort:** Low | **Fidelity:** 60%

Create `.vscode/tasks.json` that runs `ralph-copilot.sh`:

```json
{
  "version": "2.0.0",
  "tasks": [{
    "label": "Ralph: Run Task",
    "type": "shell",
    "command": "./ralph-copilot.sh",
    "args": ["${input:taskName}"],
    "problemMatcher": []
  }]
}
```

**Pros:**
- Quick F5/Ctrl+Shift+P access
- Integrated terminal output
- Works with existing script

**Cons:**
- Still CLI under the hood
- No deep Copilot Chat integration

### Option 3: VS Code Extension Development
**Effort:** Very High | **Fidelity:** 90%

Create a custom VS Code extension that:
- Uses Copilot Chat API
- Manages Ralph tasks
- Shows progress in sidebar

**Pros:**
- Native VS Code experience
- Full Copilot integration
- Rich UI

**Cons:**
- Major development effort
- Needs VS Code Extension API expertise
- May conflict with official Copilot extension

**Recommendation:** Option 2 provides good value with minimal effort. Consider Option 3 only if Ralph becomes widely adopted internally.

---

## Gap: MCP Server Bridge

**Problem:** Claude Code has native MCP support. Copilot CLI also supports MCP but through different configuration.

**Options:**

### Option 1: Use copilot-mcp-server
**Effort:** Low | **Fidelity:** 80%

The `@trishchuk/copilot-mcp-server` npm package bridges Copilot to MCP:

```bash
npx -y @trishchuk/copilot-mcp-server
```

**Pros:**
- Already exists
- Enables MCP tool access
- Community maintained

**Cons:**
- Third-party dependency
- May have compatibility issues

### Option 2: Custom Ralph MCP Server
**Effort:** High | **Fidelity:** 95%

Build an MCP server that exposes Ralph tasks as tools:

```json
{
  "tools": [{
    "name": "get_next_criterion",
    "description": "Get the next unchecked criterion from TASK.md"
  }, {
    "name": "mark_criterion_complete",
    "description": "Check off a criterion in TASK.md"
  }]
}
```

**Pros:**
- Deep Ralph integration
- Works with any MCP-compatible client
- Portable across backends

**Cons:**
- Significant development
- Needs MCP server expertise

**Recommendation:** Start with Option 1 if MCP integration is needed. Consider Option 2 as a separate project for the Ralph ecosystem.

---

## Gap: Model Selection Parity

**Problem:** Claude Code's ralph-loop doesn't specify models (uses session default). Copilot backend explicitly selects models.

**Analysis:**

This isn't a gap but a feature. The Copilot backend's model selection is more explicit and useful:

```bash
RALPH_COPILOT_MODEL=claude-sonnet ./ralph-copilot.sh my-task  # Premium
RALPH_COPILOT_MODEL=gpt-4o ./ralph-copilot.sh my-task        # Free tier
```

**Benefits of current approach:**
- Cost control (free vs premium)
- Quota awareness
- Model-specific optimization

**Recommendation:** Keep current model selection. This is a Copilot-specific feature that adds value.

---

## Summary: Recommended Priorities

### Immediate (No Changes Needed)
- Progress injection ✅ (implemented)
- Guardrails injection ✅ (implemented)
- Promise detection ✅ (implemented)
- Hash-based stuck detection ✅ (implemented)
- CLI flag parity ✅ (implemented)

### Near-Term (If Issues Arise)
1. Test ACP mode stability when Copilot license available
2. Add VS Code task integration for convenience
3. Consider dual output capture if promise detection unreliable

### Future (Separate Projects)
1. VS Code extension for rich Ralph experience
2. Custom Ralph MCP server for tool-based task management
3. ACP mode full implementation when protocol stabilizes

---

## Appendix: Copilot CLI Research Resources

| Resource | URL | Purpose |
|----------|-----|---------|
| Copilot CLI Repo | github.com/github/copilot-cli | Official source |
| ACP Issues | github.com/github/copilot-cli/issues?q=acp | Protocol bugs |
| copilot-mcp-server | github.com/x51xxx/copilot-mcp-server | MCP bridge |
| terminal-ai-toolkit | github.com/BNLNPPS/terminal-ai-toolkit | CLI guides |
| Issue #989 | Tool ID inconsistencies in ACP | Key limitation |
| Issue #979 | Non-interactive context | Automation limits |
| Issue #947 | Auto-compact config | Long conversations |
