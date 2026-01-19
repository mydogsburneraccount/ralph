# Ralph Knowledge Base

> Reference materials for the Ralph Wiggum technique with Claude Code

This directory contains **learned knowledge** from previous Ralph work. The actual loop mechanism is now handled by the **ralph-loop plugin** for Claude Code.

## Quick Start

```bash
# Start a Ralph loop (runs in current session)
/ralph-loop "Your task description. Output <promise>DONE</promise> when complete." --max-iterations 20

# Cancel an active loop
/cancel-ralph
```

## How Ralph Works Now

The ralph-loop plugin uses a **stop hook** to intercept Claude's exit attempts:

1. You run `/ralph-loop "prompt"` once
2. Claude works on the task, modifying files
3. Claude tries to exit
4. Stop hook intercepts, feeds the SAME prompt back
5. Claude sees its previous work in files/git
6. Repeats until `<promise>` detected or max iterations

**Key insight**: The loop is "self-referential" because Claude sees its own work in files, not because output feeds back as input.

## Directory Contents

```
.ralph/
├── guardrails.md        # Signs: learned lessons from failures (READ THIS)
├── core/docs/           # Reference documentation
│   ├── ANTIPATTERNS.md  # CRITICAL: What NOT to do in prompts
│   ├── RALPH_RULES.md   # Task writing principles
│   └── ...
└── completed/           # Historical task records
```

## Writing Good Ralph Prompts

### The Golden Rule

> Can this criterion be verified by running a command?
> - YES → Valid
> - NO → Document it as a manual step instead

### Required Elements

1. **Clear completion criteria** - What "done" looks like
2. **Promise marker** - `Output <promise>DONE</promise> when complete`
3. **Iteration limit** - Always use `--max-iterations`

### Example Prompts

**Simple:**
```
/ralph-loop "Fix the failing tests in auth.ts. Run npm test after each change. Output <promise>TESTS PASS</promise> when all tests green." --max-iterations 15
```

**Complex:**
```
/ralph-loop "Implement user authentication:

Phase 1: Add JWT middleware
Phase 2: Create login/logout endpoints
Phase 3: Add tests (>80% coverage)
Phase 4: Update README with API docs

Reference guardrails at .ralph/guardrails.md.
Run tests after each phase.
Output <promise>AUTH COMPLETE</promise> when all phases done." --max-iterations 30
```

## Guardrails (Signs)

Before starting any Ralph task, read `.ralph/guardrails.md`. It contains "Signs" - lessons learned from previous failures:

```markdown
### Sign: Recreate containers after image updates
- **Trigger**: When deploying a new Docker image version
- **Instruction**: Use `docker compose down` + `up -d`, not just `restart`
- **Added after**: Iteration 1 - Container kept using old cached image
```

**Add new Signs when you encounter failures** - they prevent repeating mistakes.

## Safety

- **Always set `--max-iterations`** - Loops can be expensive ($50-100+ for 50 iterations on large codebases)
- **Use sandboxing** - Ralph runs with full permissions
- **Monitor token usage** - Each iteration consumes context

## References

- [Original technique](https://ghuntley.com/ralph/) - Geoffrey Huntley
- [Ralph Orchestrator](https://github.com/mikeyobrien/ralph-orchestrator) - Multi-backend implementation
- [Antipatterns](./core/docs/ANTIPATTERNS.md) - What NOT to do

---

**Note**: Legacy backends (cursor-agent, copilot-cli, aider) archived to `_archive/2026-01-19-ralph-legacy-infrastructure/`. Claude Code with ralph-loop plugin replaces all of them.
