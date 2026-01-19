# Ralph Task Templates

This directory contains reusable Ralph task templates for `ralph-loop`.

## How to Use

Each `.md` file contains:
1. Task overview and context
2. The `/ralph-loop` command to run it
3. Phased success criteria
4. Verification commands

### Running a Task

```bash
# Copy the /ralph-loop command from the task file and run it
/ralph-loop "Execute task X. Read .ralph/tasks/X.md for instructions..." --max-iterations N
```

## Available Tasks

| Task | Description | Status |
|------|-------------|--------|
| `vscode-copilot-corporate-mac.md` | Set up VS Code + Copilot on corporate Mac | Ready |

## Creating New Tasks

Follow this structure:
1. Clear overview
2. `/ralph-loop` command block
3. Phased criteria (verifiable via commands)
4. Success checklist
5. References

See existing tasks for examples.
