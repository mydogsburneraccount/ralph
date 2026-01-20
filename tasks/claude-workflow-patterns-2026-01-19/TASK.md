# Task: Claude Workflow Patterns Implementation

## Task Overview

**Goal**: Implement 6 workflow patterns from u/agenticlab1's "2000 Hours Coding With LLMs" guide across three contexts: Claude Code direct sessions, Cursor IDE, and Ralph loop tasks.

**Context**: Based on Reddit post describing battle-tested patterns for LLM-assisted development. Core philosophy: "Any issue in LLM generated code is solely due to YOU. Errors are traceable to improper prompting or improper context engineering."

**Success Indicator**: All 6 patterns documented and configured with verification commands passing.

---

## The 6 Patterns

| # | Pattern | Key Benefit |
|---|---------|-------------|
| 1 | Error Logging System | Reconstruct hidden input-output loop, categorize failures |
| 2 | /Commands as Local Apps | Reusable workflows with SaaS power |
| 3 | Hooks for Deterministic Safety | Flow state without fear |
| 4 | Context Hygiene | Manual compaction control, context % tracking |
| 5 | Subagent Control | Force Opus subagents, orchestrator pattern |
| 6 | Reprompter System | Voice -> clarifying questions -> XML prompt |

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

#### Task Creator Responsibilities (completed)

- [x] Read `.cursorrules` completely: Anti-Gaming Rules quoted in progress.md
- [x] Read `.ralph/guardrails.md`: Learning system documented
- [x] Read source material (images): 6 patterns extracted
- [x] Identify secrets/credentials needed: None required
- [x] List files to be created: MAX 3 with justification
- [x] State verification plan: Commands specified

#### Ralph Worker Responsibilities (during execution)

- [ ] Review creator's discovery evidence in progress.md
- [ ] Verify target config file locations exist
- [ ] Add corrections or additional context if needed
- [ ] Proceed to Phase 1 only after verification complete

---

### Phase 1: Error Logging System

**Goal**: Create systematic error tracking for LLM session failures.

- [ ] Create `_agent_knowledge/workflows/error-logging-system.md` with:
  - Template for logging failed prompts with exact context
  - Categorization taxonomy (prompt error, context rot, wrong tool, etc.)
  - Pattern analysis checklist
- [ ] Add Sign to `.ralph/guardrails.md`:
  - Trigger: "When a prompt or task fails"
  - Instruction: "Log to error-logging-system before retrying"
- [ ] Verification: `grep -l "error-logging-system" _agent_knowledge/workflows/` returns file

---

### Phase 2: Slash Commands Enhancement

**Goal**: Document and potentially expand slash command capabilities.

- [ ] Audit existing skills in workspace (check `.claude/` or equivalent)
- [ ] Create `_agent_knowledge/workflows/slash-commands-guide.md` documenting:
  - Current available commands
  - How to create new slash commands
  - Pattern for "Claude as a Service" workflows
- [ ] Verification: `grep -c "slash command" _agent_knowledge/workflows/slash-commands-guide.md` > 3

---

### Phase 3: Hooks and Safety Configuration

**Goal**: Configure hooks for safe autonomous operation.

- [ ] Research Claude Code hooks configuration (search docs or existing config)
- [ ] Document hooks setup in `_agent_knowledge/tools/claude-code-hooks.md`:
  - How to enable dangerously-skip-permissions
  - Protective hook examples (prevent destructive commands)
  - Balance for flow state
- [ ] Add to CLAUDE.md or .cursorrules: Hook configuration recommendations
- [ ] Verification: `grep -i "hook" _agent_knowledge/tools/claude-code-hooks.md` returns matches

---

### Phase 4: Context Hygiene and Subagent Control

**Goal**: Implement context management and subagent forcing.

- [ ] Add to CLAUDE.md:
  - "Always launch opus subagents" instruction
  - Context hygiene reminders (manual compaction preference)
  - Double-escape time travel mention
- [ ] Add to `.cursorrules`:
  - Subagent usage guidance
  - Context percentage awareness instruction
- [ ] Create `_agent_knowledge/workflows/context-hygiene.md`:
  - Disable autocompact instructions
  - Context % monitoring
  - Manual compaction triggers
  - "Lost in the middle" awareness
- [ ] Verification: `grep -i "subagent\|opus" CLAUDE.md` returns matches

---

### Phase 5: Reprompter System Documentation

**Goal**: Document the reprompter workflow pattern.

- [ ] Create `_agent_knowledge/workflows/reprompter-system.md`:
  - Voice dictation -> clarifying questions -> XML structured prompt
  - Example workflow
  - Integration with existing tools
- [ ] Verification: `grep -c "XML\|voice" _agent_knowledge/workflows/reprompter-system.md` > 2

---

## Manual Steps Required

### 1. Claude Code Settings (User action)

```bash
# These settings are applied via Claude Code CLI or config
# User needs to verify their Claude Code installation supports:
# - Hooks configuration
# - Subagent model selection
# - Autocompact toggle
```

### 2. Cursor IDE Settings (User action)

```
# User should review Cursor settings for:
# - MCP server configuration
# - Agent model selection
# - Context window management
```

---

## Rollback Plan

If this task causes issues:

```bash
# All changes are additive documentation files
# Rollback: archive the new files to _archive/2026-01-19-workflow-patterns/
mkdir -p _archive/2026-01-19-workflow-patterns/
mv _agent_knowledge/workflows/error-logging-system.md _archive/2026-01-19-workflow-patterns/
mv _agent_knowledge/workflows/slash-commands-guide.md _archive/2026-01-19-workflow-patterns/
# etc.
```

---

## Notes

- Local RAG MCP server had initialization issues during task creation - may need restart
- All patterns are documentation-based - no code changes required
- Some patterns (hooks, autocompact) may require Claude Code CLI features that need verification
- Focus on documentation that works across Claude Code, Cursor, and Ralph contexts

---

## Context for Future Agents

This task implements workflow discipline patterns from a practitioner with 2000+ hours of LLM-assisted coding experience. The core insight is that LLM errors are almost always traceable to context engineering failures, not model limitations.

Key considerations:

1. Error logging creates accountability and pattern recognition
2. Slash commands turn repetitive workflows into reusable services
3. Hooks enable autonomous operation without fear of destructive actions
4. Context hygiene prevents the "lost in the middle" degradation
5. Forcing Opus subagents improves quality for knowledge tasks
6. Reprompter converts sloppy voice input into high-quality prompts

Work incrementally through phases. Test each phase before moving to next.
