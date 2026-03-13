# Task: Ralph-Loop Copilot Parity Analysis & Implementation

## Context

The ralph-loop plugin for Claude Code has been enhanced with:
- `--guardrails <file>` - Injects rules into system message each iteration
- `--progress <file>` - Logs iteration history, injects into context (last 50 lines)
- `--stuck-threshold <n>` - Warns after N iterations with no file changes
- Activity logging to `.claude/ralph-activity.log`
- Proper YAML escaping (M3 fix) and jq error handling (M1 fix)

**Source of truth for Claude Code implementation:**
- GitHub: `github.com/mydogsburneraccount/claude-plugins-official`
- Branch: `ralph-loop/progress-and-fixes`
- Local path: `/home/flippadip/.claude/plugins/marketplaces/claude-plugins-official/plugins/ralph-loop/`
- Key files: `scripts/setup-ralph-loop.sh`, `hooks/stop-hook.sh`

An earlier attempt exists to bring ralph-loop patterns to GitHub Copilot CLI + VS Code. This attempt is well-structured but untested and predates the enhanced plugin features.

**Copilot implementation location (THIS IS WHERE YOU WORK):**
- GitHub: `github.com/mydogsburneraccount/ralph`
- **Local path: `/mnt/c/Users/Ethan/Code/cursor_local_workspace/.ralph/`**
- Copilot backend: `backends/copilot-cli/`
- Key files: `ralph-copilot.sh` (554 lines), `DESIGN.md` (509 lines)

**IMPORTANT:** The ralph repo is located at `.ralph/` in the current workspace, NOT at `/mnt/c/Users/Ethan/Code/ralph/` (that old clone has been deleted). All work should be done in `/mnt/c/Users/Ethan/Code/cursor_local_workspace/.ralph/`.

## Objective

Bring the Copilot backend to feature parity where possible. Copilot lacks stop hooks, so the mechanism differs (external script vs internal hooks), but the core patterns (iteration tracking, guardrails injection, progress logging, stuck detection) should be achievable.

## Phase 1: Discovery

1. Read the Claude Code ralph-loop plugin (already cloned locally):
   - Path: `/home/flippadip/.claude/plugins/marketplaces/claude-plugins-official/plugins/ralph-loop/`
   - Read `scripts/setup-ralph-loop.sh` - initialization and flag parsing
   - Read `hooks/stop-hook.sh` - iteration logic, stuck detection, progress injection
   - Understand: How does each feature work?

2. Read the ralph repo (already cloned locally at `.ralph/`):
   - Path: `/mnt/c/Users/Ethan/Code/cursor_local_workspace/.ralph/`
   - Read `backends/claude-code/README.md` for feature summary
   - Read `backends/copilot-cli/DESIGN.md` for existing architecture
   - Read `backends/copilot-cli/ralph-copilot.sh` for current implementation
   - Read `backends/copilot-cli/RESEARCH_FINDINGS.md` for Copilot CLI constraints

3. Document what Copilot backend currently has vs what Claude Code has

## Phase 2: Gap Analysis

Create a comparison matrix:

| Feature | Claude Code (plugin) | Copilot (script) | Gap | Solvable? |
|---------|---------------------|------------------|-----|-----------|
| Iteration tracking | State file + stop hook | .iteration file + while loop | Different mechanism | N/A (different by design) |
| Same-prompt re-injection | Stop hook intercepts exit | Script rebuilds prompt each iteration | Different mechanism | N/A |
| Guardrails injection | --guardrails flag -> system message | Reads guardrails.md in prompt | ? | ? |
| Progress tracking | --progress flag -> file + injection | progress.md updated manually | ? | ? |
| Stuck detection | --stuck-threshold -> file hash comparison | STUCK_THRESHOLD + .last_criterion | ? | ? |
| Activity logging | .claude/ralph-activity.log | activity.log in task dir | ? | ? |
| Completion detection | promise tag parsing | Checkbox counting + promise | ? | ? |

Fill in the "?" cells with actual analysis.

## Phase 3: Implementation (Obvious Solutions)

For gaps marked "Solvable? = Yes":
- Implement the solution in `backends/copilot-cli/ralph-copilot.sh`
- Test syntax: `bash -n ralph-copilot.sh`
- Document changes in `backends/copilot-cli/CHANGELOG.md` (create if needed)

Likely candidates:
- Progress file injection into prompt (match --progress behavior)
- File hash-based stuck detection (match --stuck-threshold behavior)
- Guardrails content injection formatting (match injection format)
- Activity log format standardization

## Phase 4: Research & Recommendations (Complex Solutions)

For gaps marked "Solvable? = Maybe/Creative solution needed":

Research:
- VS Code extension APIs for automation
- Copilot's custom instructions and workspace features
- GitHub Actions or external orchestration
- Copilot CLI's ACP mode (experimental, see DESIGN.md)

Format recommendations as:

### Gap: [Feature]
**Problem:** [Why it's hard in Copilot]
**Options:**
1. [Solution A] - Effort: [Low/Med/High], Fidelity: [%]
2. [Solution B] - Effort: [Low/Med/High], Fidelity: [%]
**Recommendation:** [Which option and why]

## Phase 5: Deliverables

Create/update these files in the ralph repo at `/mnt/c/Users/Ethan/Code/cursor_local_workspace/.ralph/`:

1. `backends/copilot-cli/PARITY_ANALYSIS.md` - Gap matrix and findings
2. `backends/copilot-cli/ralph-copilot.sh` - Updated with implemented features
3. `backends/copilot-cli/CHANGELOG.md` - Document all changes
4. `backends/copilot-cli/RECOMMENDATIONS.md` - Research findings for complex gaps

Commit changes with message format:
```
feat(copilot-backend): [description]

[details]

Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>
```

## Completion Promise

Output `<promise>PARITY ANALYSIS COMPLETE</promise>` when:
- Gap analysis matrix is complete and documented
- All "obvious" solutions are implemented
- All "complex" gaps have researched recommendations
- All deliverable files exist with substantive content
- Changes are committed to the ralph repo

## Important Notes

- The Copilot backend is UNTESTED (requires active Copilot license) - focus on code quality, not runtime testing
- Do NOT modify the Claude Code plugin - it's the reference implementation
- Work exclusively in the `backends/copilot-cli/` directory of the ralph repo
- The mechanism WILL differ (external script vs hooks) - focus on feature parity, not implementation parity
