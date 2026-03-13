# Progress: Workspace Hardening & Agent Workflow Optimization

## Phase 0: Verification Gate

### Task Creator Discovery (filled by task creator)

**Rules Read:**
- `CLAUDE.md` Anti-Gaming Rules: "Creating 5 files when 1 would suffice = FAILURE"
- `CLAUDE.md` Data Safety: "NEVER DELETE FILES - archive to `_archive/YYYY-MM-DD-description/` instead"
- `.claude/rules/documentation-maintenance.md`: Single source of truth architecture, after-action capture workflow
- `projects/MCP/AGENTS.md`: MCP evaluation workflow documented

**Research Conducted (2026-02-16):**
- Deep research across 4 parallel opus subagents covering: superpowers-lab, compound-engineering vs superpowers+debrief, Trail of Bits full ecosystem, and holistic ecosystem blind spot check
- Sources: official Claude Code docs, Trail of Bits repos, obra/superpowers ecosystem, community marketplaces, Reddit/HN/blog consensus
- Key finding: compound-engineering has 2 genuinely novel ideas (institutional knowledge loop + plan deepening) but 29 agents / 22 commands is bloated and conflicts with superpowers. Cherry-pick, don't adopt.

**Current State (snapshot at task creation):**
- `/debrief` command: working (`.claude/commands/debrief.md`)
- Stop hook: disabled (was timing out with JSON validation errors — prompt-type hooks have 15s timeout and produce malformed JSON on trivial sessions)
- `block-dangerous.sh`: wired up as PreToolUse hook (just fixed)
- `puppeteer` MCP: removed (redundant with Playwright plugin)
- `black` PostToolUse hook: removed (was running on entire project, wrong tool — user uses Ruff)
- Trail of Bits marketplace: added by user

**Plugins installed by user (verify at Phase 1):**
- hookify, pr-review-toolkit, modern-python, gh-cli, ask-questions-if-underspecified (Tier 1)
- differential-review, insecure-defaults, superpowers-lab (Tier 2)
- episodic-memory (from obra marketplace — may need marketplace add first)

**Secrets/Credentials:**
- None required for any phase of this task

**Files to Create:**
1. `TASK.md` — This task definition
2. `progress.md` — This file with discovery evidence

**Verification Plan:**
- Each phase has command-verifiable criteria
- No GUI interactions or manual steps except plugin installs (documented as manual steps)

---

## Execution Log (2026-02-16)

### Phase 0: Verification Gate — PASSED
- Discovery evidence reviewed in progress.md
- settings.local.json: PreToolUse has block-dangerous.sh, no puppeteer/black
- debrief.md: exists with 5-step workflow
- ruff 0.14.13 available
- jq 1.7 available

### Phase 1: Fix Debrief Stop Hook — COMPLETED
- Created `_scripts/debrief-nudge.sh` (Python 3 with `#!/usr/bin/env python3` shebang)
- Wired as command-type Stop hook in settings.local.json with 5s timeout
- Verifications: hook type is "command", nonexistent transcript returns approve, large transcript returns nudge message

### Phase 2: Searchable Knowledge Base — COMPLETED
- Created `docs/solutions/` with 5 subdirectories: infrastructure, debugging, configuration, workflow, integration
- Created `docs/solutions/README.md` with YAML frontmatter schema, field definitions, example, and querying instructions
- Updated `.claude/commands/debrief.md` with Step 4b for knowledge base entries
- Verifications: directories exist, README has content, debrief.md references Step 4b and docs/solutions

### Phase 3: Plan Deepening Command — COMPLETED
- Created `.claude/commands/deepen-plan.md` with frontmatter and 6-step instructions
- Instructs Claude to spawn 5 parallel opus subagents: Context7 researcher, Solutions researcher, Codebase pattern analyzer, Security reviewer, Dependency checker
- Reads plan from $ARGUMENTS, synthesizes findings into Research Findings section
- Verifications: file exists, >= 3 mentions of Task tool/subagent/parallel, $ARGUMENTS referenced

### Phase 4: Custom Subagents — COMPLETED
- Created `.claude/agents/flippanet-ops.md` with YAML frontmatter (Read, Grep, Glob, Bash tools)
- Includes full HARD STOP rules copied verbatim from projects/flippanet/AGENTS.md
- Includes SSH access, Vault tools, Docker stack awareness
- Created `.claude/agents/doc-reviewer.md` with YAML frontmatter (Read, Grep, Glob tools, read-only)
- Includes canonical files table, 6-step audit procedure, report format template
- Verifications: 2 agent files, flippanet-ops contains "flippanet" and "NEVER"

### Phase 5: Hook Infrastructure — COMPLETED
- Created `_scripts/session-start.sh` (bash): outputs git log, branch, in-progress Ralph tasks
- Created `_scripts/pre-compact-backup.sh` (bash): backs up transcript to _archive/compactions/
- Wired SessionStart (10s timeout) and PreCompact (30s timeout) hooks in settings.local.json
- Verifications: hook commands resolve correctly, both scripts exit 0

### Phase 6: PostToolUse Python Linting — COMPLETED
- Created `_scripts/ruff-hook.sh` (bash): runs ruff check --fix on .py files, silent on non-Python
- Appended to PostToolUse hooks array alongside CRLF fixer
- Verifications: ruff 0.14.13 installed, non-Python handled gracefully, PostToolUse has 2 hooks

### Files Created
1. `_scripts/debrief-nudge.sh` — Python 3 Stop hook script
2. `docs/solutions/README.md` — Knowledge base schema and instructions
3. `.claude/commands/deepen-plan.md` — Plan deepening slash command
4. `.claude/agents/flippanet-ops.md` — Flippanet diagnostics subagent
5. `.claude/agents/doc-reviewer.md` — Documentation audit subagent
6. `_scripts/session-start.sh` — SessionStart hook script
7. `_scripts/pre-compact-backup.sh` — PreCompact hook script
8. `_scripts/ruff-hook.sh` — PostToolUse Ruff linting hook

### Files Modified
1. `.claude/settings.local.json` — Added Stop, SessionStart, PreCompact hooks; appended ruff-hook to PostToolUse
2. `.claude/commands/debrief.md` — Added Step 4b for knowledge base entries

### Directories Created
1. `docs/solutions/` with subdirs: infrastructure, debugging, configuration, workflow, integration
2. `.claude/agents/`
