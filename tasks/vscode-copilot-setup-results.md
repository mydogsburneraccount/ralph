# VS Code + Copilot Corporate Mac Setup Results

**Date**: 2026-01-19
**Environment**: WSL2/Ubuntu on Windows (Yggdrasil)
**Status**: CANNOT COMPLETE FROM THIS MACHINE

---

## Environment Mismatch

This task requires execution on a **corporate Mac**, but the current environment is:
- **OS**: Ubuntu 24.04.3 LTS (WSL2)
- **Host**: Windows (Yggdrasil)
- **Issue**: Cannot run macOS-specific commands or access Mac VS Code settings

---

## What Was Prepared (Ready for Transfer)

### 1. Setup Script for Mac

A bash script has been created at:
```
.ralph/tasks/mac-copilot-setup.sh
```

Transfer this to the Mac and run:
```bash
chmod +x mac-copilot-setup.sh
./mac-copilot-setup.sh
```

### 2. Project Instructions Template

**Found existing** `.github/copilot-instructions.md` with multi-PR workflow guidance (274 lines).
This can serve as a starting point - add workspace context sections as needed.

### 3. VS Code Settings JSON

Ready-to-use settings for agent mode.

---

## Phases Status

| Phase | Description | Status | Notes |
|-------|-------------|--------|-------|
| 1 | Prerequisites Verification | ⏳ Pending | Requires Mac |
| 2 | VS Code Extension Setup | ⏳ Pending | Requires Mac |
| 3 | Enable Agent Mode | ⏳ Pending | Requires Mac |
| 4 | Copilot CLI Authentication | ⏳ Pending | Requires Mac + corporate auth |
| 5 | Project Configuration | ✅ Prepared | Template created |
| 6 | MCP Server Setup | ⏳ Pending | Optional, requires Mac |
| 7 | Workflow Configuration | ✅ Documented | In task file |
| 8 | Verification Tests | ⏳ Pending | Requires Mac |

---

## Next Steps (On Corporate Mac)

1. **Transfer files** from this workspace to Mac:
   ```bash
   # From Mac, pull these files:
   scp user@windows:.ralph/tasks/mac-copilot-setup.sh ~/
   scp -r user@windows:.github ~/project/.github/
   ```

2. **Run setup script**:
   ```bash
   cd ~/
   chmod +x mac-copilot-setup.sh
   ./mac-copilot-setup.sh
   ```

3. **Complete manual steps**:
   - Authenticate Copilot CLI with corporate credentials
   - Verify Agent mode in VS Code UI

4. **Run verification tests** from Phase 8 of the task file

---

## Prepared Assets

### mac-copilot-setup.sh
Location: `.ralph/tasks/mac-copilot-setup.sh`

### copilot-instructions.md template
Location: `.github/copilot-instructions.md`

### VS Code settings additions
Location: Embedded in setup script

---

## Completion Criteria

This task can be marked complete when run **on the Mac** and:
- [ ] `code --version` succeeds
- [ ] `code --list-extensions | grep copilot` shows both extensions
- [ ] `copilot --version` succeeds
- [ ] `copilot /whoami` shows corporate account
- [ ] Agent mode visible in VS Code Chat
