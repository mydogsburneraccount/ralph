# Task: Workspace Hardening & Agent Workflow Optimization

## Task Overview

**Goal**: Complete the remaining workspace infrastructure improvements identified during the 2026-02-16 plugin/workflow research session. Covers: debrief hook fix, compound-engineering idea extraction, custom subagents, hook infrastructure, and PostToolUse linting.

**Context**: A deep ecosystem research session (4 parallel opus subagents) identified blind spots in the current setup. The quick fixes (block-dangerous.sh wiring, MCP trimming, Black removal) were done immediately. This task covers the items that need dedicated sessions to implement properly.

**Success Indicator**: All phases pass their verification commands. The workspace has: a working non-blocking debrief nudge, a searchable `docs/solutions/` knowledge base, custom subagents, SessionStart context injection, PreCompact safety net, and targeted Python linting.

**Phase Dependencies**:
- Phase 1 (Stop hook) → must complete before Phase 5 (hook infrastructure) modifies the same settings file
- Phase 2 (knowledge base) → must complete before Phase 3 (deepen-plan references `docs/solutions/`)
- Phases 4 and 6 are independent — can run in any order

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

#### Task Creator Responsibilities (completed)

- [x] Read `CLAUDE.md`: Anti-Gaming Rules, Data Safety, Python First
- [x] Read `.claude/rules/documentation-maintenance.md`: Single source of truth architecture
- [x] Read `projects/MCP/AGENTS.md`: MCP evaluation workflow
- [x] Research conducted: 4 parallel opus subagents, sources documented in progress.md
- [x] Identify secrets/credentials needed: None required
- [x] List files to be created: Documented per phase
- [x] State verification plan: Command-verifiable criteria per phase

#### Ralph Worker Responsibilities (during execution)

- [x] Review creator's discovery evidence in progress.md
- [x] Verify `.claude/settings.local.json` has PreToolUse for block-dangerous.sh and no puppeteer/black
- [x] Verify `.claude/commands/debrief.md` exists and contains the 5-step workflow
- [x] Verify `ruff` is available: `ruff --version` succeeds
- [x] Verify `jq` is available: `jq --version` succeeds
- [x] Proceed to Phase 1 only after verification complete

---

### Phase 1: Fix Debrief Stop Hook

**Goal**: Replace the broken prompt-type Stop hook with a working non-blocking command-type hook.

**Problem**: The previous prompt-type Stop hook timed out on short sessions (15s limit) and produced malformed JSON, causing "JSON validation failed" errors. It also fired alongside ralph-loop's Stop hook, compounding the issue.

**Approach**: Use a command-type Stop hook. The script reads the hook input JSON from stdin (which includes a `transcript_path` field), checks transcript size as a heuristic for substantive work, and outputs a `systemMessage` nudge when warranted. Command-type hooks are deterministic and fast — no model call, no timeout risk.

**Hook input format** (what the script receives on stdin):
```json
{"session_id": "...", "transcript_path": "/path/to/transcript.txt", "cwd": "...", "hook_event_name": "Stop", "reason": "..."}
```

**Hook output format** (what the script must produce on stdout):
```json
{"decision": "approve", "systemMessage": "optional message for Claude"}
```

- [x]Create `_scripts/debrief-nudge.sh` (Python 3, not bash — for reliable JSON handling):
  - Read JSON from stdin using `json.load(sys.stdin)`
  - Extract `transcript_path` from the input JSON
  - If transcript file exists and is > 5000 bytes (heuristic for substantive work): output `{"decision": "approve", "systemMessage": "This session produced learnings worth capturing. Consider running /debrief before ending."}`
  - Otherwise: output `{"decision": "approve"}`
  - Always exit 0. Never output to stderr. Never block.
  - Handle all errors silently (missing file, bad JSON, etc.) — default to approve with no message
- [x]Add Stop hook to `.claude/settings.local.json` (the `"Stop": []` array is already present, replace it):
  ```json
  "Stop": [{"matcher": "*", "hooks": [{"type": "command", "command": "$CLAUDE_PROJECT_DIR/_scripts/debrief-nudge.sh", "timeout": 5}]}]
  ```
- [x]Verification: `jq '.hooks.Stop[0].hooks[0].type' .claude/settings.local.json` returns `"command"`
- [x]Verification: `echo '{"transcript_path": "/tmp/nonexistent"}' | python3 _scripts/debrief-nudge.sh | jq -e '.decision == "approve"'` exits 0
- [x]Verification: Create a temp file > 5000 bytes, then `echo "{\"transcript_path\": \"$tmpfile\"}" | python3 _scripts/debrief-nudge.sh | jq -e '.systemMessage'` returns the nudge message

---

### Phase 2: Searchable Knowledge Base (Compound-Engineering Idea #1)

**Goal**: Extend `/debrief` to also write to a searchable `docs/solutions/` directory with categorized YAML frontmatter, creating an institutional knowledge loop that future planning sessions can query.

**Why**: Currently `/debrief` writes to AGENTS.md (good for agent onboarding context) but the knowledge isn't categorized or searchable during future planning. The institutional knowledge loop means past solutions get auto-discovered when planning related work.

- [x]Create `docs/solutions/` directory with subdirectories:
  - `infrastructure/`, `debugging/`, `configuration/`, `workflow/`, `integration/`
- [x]Create `docs/solutions/README.md` defining the YAML frontmatter schema and providing a concrete example:
  ```yaml
  ---
  title: "Vault prompt-type Stop hook causes JSON validation errors"
  date: 2026-02-16
  project: workspace
  category: debugging
  tags: [hooks, stop-hook, json, timeout]
  problem: "Prompt-type Stop hooks time out on short sessions and produce malformed JSON"
  root_cause: "15s timeout insufficient for model to generate valid JSON; trivial sessions have no context to evaluate"
  symptoms: ["'JSON validation failed' on session end", "'ran 2 stop hooks' in output"]
  ---

  ## Solution
  Use command-type hooks instead of prompt-type for Stop events...
  ```
- [x]Update `.claude/commands/debrief.md` — insert a "Step 4b" between current Step 4 and Step 5:
  - **Step 4b: Knowledge Base Entry** — If the learning is experiential (what worked/didn't) or procedural (multi-step process), also create a solution doc at `docs/solutions/[category]/YYYY-MM-DD-short-description.md` with the YAML frontmatter schema from `docs/solutions/README.md`. Factual-only items (ports, paths, configs) stay in AGENTS.md only — they don't need the solution doc format.
- [x]Verification: `test -d docs/solutions/infrastructure && test -d docs/solutions/debugging && echo "dirs exist"` returns "dirs exist"
- [x]Verification: `head -1 docs/solutions/README.md` returns a non-empty line
- [x]Verification: `grep -c "Step 4b\|docs/solutions" .claude/commands/debrief.md` returns >= 2

---

### Phase 3: Plan Deepening Command (Compound-Engineering Idea #2)

**Goal**: Create a `/deepen-plan` command that runs targeted parallel research subagents on an existing plan file to catch blind spots before execution.

**Why**: Before executing a plan, 5 focused research subagents can surface framework docs, past learnings, security implications, and codebase patterns that the plan author missed.

**Important**: This is a `.claude/commands/` markdown file — it contains **instructions for Claude**, not executable code. Write it as imperative instructions that Claude follows when the user runs `/deepen-plan <path-to-plan>`.

- [x]Create `.claude/commands/deepen-plan.md` with frontmatter:
  ```yaml
  ---
  description: Enhance an existing plan with parallel research. Provide the plan file path as an argument.
  ---
  ```
  Body instructs Claude to:
  1. Read the plan file at `$ARGUMENTS`
  2. Spawn 5 parallel subagents via the Task tool (all with `model: "opus"`):
     - **Context7 researcher**: Resolve and query documentation for any libraries/frameworks mentioned in the plan
     - **Solutions researcher**: Search `docs/solutions/` (using Grep tool) for past learnings matching the plan's domain
     - **Codebase pattern analyzer**: Find existing code patterns related to the plan (Glob + Grep for similar implementations)
     - **Security reviewer**: Identify security implications of the planned changes (credential handling, network exposure, permissions)
     - **Dependency checker**: Verify that tools, packages, and paths assumed by the plan actually exist
  3. Wait for all subagents to complete
  4. Synthesize findings into the plan file as a new "## Research Findings" section with subsections per subagent
  5. Flag any findings that contradict or complicate the plan
- [x]Verification: `test -f .claude/commands/deepen-plan.md && echo "exists"` returns "exists"
- [x]Verification: `grep -c "Task tool\|subagent\|parallel" .claude/commands/deepen-plan.md` returns >= 3
- [x]Verification: `grep "ARGUMENTS" .claude/commands/deepen-plan.md` returns a match (confirms it accepts input)

---

### Phase 4: Custom Subagents

**Goal**: Create `.claude/agents/` with project-specific subagents that can be invoked via the Task tool.

**Agent file format** (YAML frontmatter + markdown body):
```yaml
---
name: agent-name
description: When this agent should be used (third-person, with trigger phrases)
tools: [Read, Grep, Glob, Bash]
model: opus
---

System prompt / instructions for the agent...
```

- [x]Create `.claude/agents/flippanet-ops.md`:
  - **tools**: `[Read, Grep, Glob, Bash]` (no Write/Edit — this agent investigates, doesn't modify)
  - **description**: Third-person with triggers: "This agent should be used when diagnosing flippanet server issues, checking Docker container status, verifying Vault seal state, or investigating service health. Use for any SSH-based flippanet operations."
  - **System prompt must include**:
    - SSH access: `ssh flippanet` (uses `~/.ssh/flippanet` key)
    - Vault tools: `flippanet-vault-read`, `flippanet-vault-unseal`, `flippanet-sudo` (at `~/.local/bin/`)
    - The complete HARD STOP rules from `projects/flippanet/AGENTS.md` (copy the "What Agents Must NEVER Do" section verbatim — this is the one place duplication is justified because subagents don't read AGENTS.md automatically)
    - Docker stack awareness: services are managed via docker-compose in `~/flippanet/`
- [x]Create `.claude/agents/doc-reviewer.md`:
  - **tools**: `[Read, Grep, Glob]` (read-only)
  - **description**: "This agent should be used when reviewing documentation accuracy, checking for stale paths in AGENTS.md files, auditing canonical file freshness, or verifying that documented commands still work."
  - **System prompt must include**:
    - List of canonical files to check (from `.claude/rules/documentation-maintenance.md`)
    - Check each documented path with Glob to verify it exists
    - Check each documented command/script reference to verify the file exists
    - Report: stale paths, outdated instructions, missing "Maintaining This File" sections, undocumented new directories
- [x]Verification: `ls .claude/agents/*.md | wc -l` returns >= 2
- [x]Verification: `grep -l "flippanet" .claude/agents/*.md` returns a file
- [x]Verification: `grep -l "NEVER" .claude/agents/flippanet-ops.md` returns a match (confirms HARD STOP rules are included)

---

### Phase 5: Hook Infrastructure (SessionStart + PreCompact)

**Goal**: Add SessionStart and PreCompact hooks for dynamic context injection and context-loss safety.

**Prerequisite**: Phase 1 must be complete (both phases modify `.claude/settings.local.json` hooks).

**Hook output behavior for SessionStart**: stdout from a SessionStart command hook is included in the session context as a system message. This is how dynamic context gets injected — the script prints to stdout, and Claude sees it.

- [x]Create `_scripts/session-start.sh` (bash, executable):
  - Output recent git log: `git log --oneline -5 2>/dev/null || true`
  - Output current branch: `git branch --show-current 2>/dev/null || true`
  - Output in-progress Ralph tasks: scan `.ralph/tasks/*/progress.md` for files containing unchecked `- [ ]` items, list the task directory names
  - All commands must use `|| true` to prevent hook failure on errors
  - Total output should be concise (< 20 lines) to minimize context consumption
- [x]Create `_scripts/pre-compact-backup.sh` (bash, executable):
  - Read `transcript_path` from stdin JSON: `transcript_path=$(jq -r '.transcript_path // ""')`
  - If transcript file exists: `cp "$transcript_path" "$CLAUDE_PROJECT_DIR/_archive/compactions/$(date +%Y-%m-%d-%H-%M).txt" 2>/dev/null || true`
  - Create `_archive/compactions/` directory if it doesn't exist: `mkdir -p "$CLAUDE_PROJECT_DIR/_archive/compactions/"`
  - Always exit 0
- [x]Add both hooks to `.claude/settings.local.json` hooks object:
  ```json
  "SessionStart": [{"matcher": "*", "hooks": [{"type": "command", "command": "$CLAUDE_PROJECT_DIR/_scripts/session-start.sh", "timeout": 10}]}],
  "PreCompact": [{"matcher": "*", "hooks": [{"type": "command", "command": "$CLAUDE_PROJECT_DIR/_scripts/pre-compact-backup.sh", "timeout": 30}]}]
  ```
- [x]Verification: `jq '.hooks.SessionStart[0].hooks[0].command' .claude/settings.local.json` returns a string containing "session-start.sh"
- [x]Verification: `jq '.hooks.PreCompact[0].hooks[0].command' .claude/settings.local.json` returns a string containing "pre-compact-backup.sh"
- [x]Verification: `echo '{}' | bash _scripts/session-start.sh; echo "exit:$?"` shows output and ends with `exit:0`
- [x]Verification: `echo '{"transcript_path":"/dev/null"}' | bash _scripts/pre-compact-backup.sh; echo "exit:$?"` ends with `exit:0`

---

### Phase 6: PostToolUse Python Linting

**Goal**: Replace the removed Black hook with targeted Ruff linting on the specific changed file.

- [x]Create `_scripts/ruff-hook.sh` (bash, executable):
  - Read hook input JSON from stdin
  - Extract file path: `file_path=$(jq -r '.tool_input.file_path // ""')`
  - If `file_path` ends in `.py` AND `ruff` command exists: run `ruff check --fix "$file_path" 2>/dev/null || true`
  - If not Python or ruff not available: exit 0 silently
  - Never output to stdout (PostToolUse stdout appears in transcript — linter noise is unwanted)
- [x]Add to PostToolUse hooks in `.claude/settings.local.json` (append to existing CRLF hook's array):
  ```json
  {"type": "command", "command": "$CLAUDE_PROJECT_DIR/_scripts/ruff-hook.sh"}
  ```
- [x]Verification: `ruff --version` succeeds (ruff is installed)
- [x]Verification: `echo '{"tool_input":{"file_path":"test.txt"}}' | bash _scripts/ruff-hook.sh; echo "exit:$?"` ends with `exit:0` (non-Python file handled gracefully)
- [x]Verification: `jq '.hooks.PostToolUse[0].hooks | length' .claude/settings.local.json` returns >= 2

---

## Manual Steps Required

### 1. Plugin Installation (completed by user 2026-02-16)

All plugins installed. Ralph worker should verify with `/plugin list` or by checking the skills list at session start.

### 2. StatusLine Setup (optional, out of scope for this task)

```bash
# Can be done independently — not blocking any phase:
claude config set statusLine '{"command": "path/to/statusline.sh"}'
```

---

## Rollback Plan

If individual phases cause issues, rollback is per-phase (not all-or-nothing):

| Phase | Rollback |
|-------|----------|
| 1 | Set `"Stop": []` in settings.local.json, delete `_scripts/debrief-nudge.sh` |
| 2 | Archive `docs/solutions/` to `_archive/`, revert debrief.md: `git checkout -- .claude/commands/debrief.md` |
| 3 | Delete `.claude/commands/deepen-plan.md` |
| 4 | Delete `.claude/agents/` directory |
| 5 | Remove SessionStart/PreCompact from settings.local.json hooks, delete the two scripts |
| 6 | Remove ruff-hook entry from PostToolUse array in settings.local.json, delete `_scripts/ruff-hook.sh` |

---

## Notes

- All scripts should be Python 3 (per CLAUDE.md "Python First") unless bash is significantly simpler (phases 5-6 are fine as bash since they're just glue)
- All scripts must handle CRLF — the PostToolUse CRLF hook auto-fixes written files, but verify shebangs work on WSL
- PostToolUse hook scripts should NOT write to stdout unless the output is useful for Claude to see in the transcript
- Stop/SessionStart hook scripts SHOULD write to stdout — that's how their output reaches Claude
- Read the Claude Code hooks documentation via Context7 at the start of implementation for any field name uncertainties

## Context for Future Agents

This task was born from a comprehensive ecosystem research session that identified gaps in the workspace's agent workflow infrastructure. The user values professional, scalable solutions and explicitly rejected "stopgap solutions that maintain the status quo of constant rework."

Key principles:
1. Standalone `.claude/` configuration over plugins for personal workspace tools (plugins are for distribution)
2. Command-type hooks over prompt-type hooks for reliability (prompt hooks time out and produce malformed JSON)
3. Cherry-pick ideas from compound-engineering rather than adopting the whole plugin (context cost too high, conflicts with superpowers)
4. Every hook script must be deterministic, fast, and never block the session
5. Python 3 for scripts unless bash is significantly simpler for the task
