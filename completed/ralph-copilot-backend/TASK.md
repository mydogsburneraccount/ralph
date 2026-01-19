---
dependencies:
  system:
    - gh              # GitHub CLI for documentation research
  check_commands:
    - gh --version
    # Note: gh copilot extension requires active Copilot license
    # This task focuses on research and design, not live testing
---

# Ralph Task: Corporate-Friendly Copilot Backend

## Task Overview

**Goal**: Research and implement GitHub Copilot integration for Ralph as a corporate-compliant alternative to Aider/Anthropic API.

**Context**:

- Corporate environment has GitHub Copilot contract (GPT, Gemini access; Claude pending)
- Cannot use personal Anthropic API keys (data leakage, compliance concerns)
- Need CLI-based Ralph backend that works on corporate laptops
- Must maintain autonomous capabilities in restricted environments

**Why This Matters**:

- Enables Ralph on corporate machines without compliance issues
- Uses existing approved contracts (GitHub Copilot)
- No new security approvals needed
- Maintains autonomous capabilities for CLI-only environments

**Success Indicator**: Research-based design document for `ralph-copilot.sh` implementation, with clear documentation for corporate users who have Copilot licenses. Implementation and testing deferred to corporate MacBook with active license.

---

## Success Criteria

### Phase 1: Discovery & Research

#### GitHub Copilot CLI Integration

- [x] Research GitHub Copilot CLI capabilities
  - [x] Check `gh copilot` commands and API (discovered old gh-copilot deprecated Oct 2025, replaced by copilot-cli)
  - [x] Verify if it supports autonomous/batch operations (YES - new copilot-cli is full agentic, supports --acp mode)
  - [x] Test token limits and context windows (Claude 4.5 default = 200K context, auto-compaction at thresholds)
  - [x] Document model selection (Claude Sonnet 4.5 default, Claude 4, GPT-5 available)

- [x] Community & Official Resources
  - [x] Search GitHub Docs for Copilot CLI usage patterns (found terminal-ai-toolkit, official docs)
  - [x] Check GitHub Community discussions on automation (reviewed copilot-cli issues/discussions)
  - [x] Look for existing Copilot + automation integrations (found copilot-mcp-server!)
  - [x] Review GitHub Copilot Enterprise features (org controls, audit logging, knowledge bases)
  - [x] Check if MCP server exists for Copilot (YES: @trishchuk/copilot-mcp-server)

- [x] Security & Compliance Considerations
  - [x] Document data retention policies (prompts not retained for training, Enterprise controls)
  - [x] Verify GitHub Enterprise audit logging (90+ days, API access available)
  - [x] Check if code stays within GitHub/Microsoft infrastructure (YES - GitHub is proxy)
  - [x] Compare to Aider security model (added comparison table in RESEARCH_FINDINGS.md)
  - [x] Document corporate approval requirements (added checklist template)

### Phase 2: Technical Feasibility Assessment (Documentation-Based)

#### GitHub Copilot CLI Research

- [x] Review `gh copilot` documentation on GitHub (deprecated Oct 2025, replaced by copilot-cli)
- [x] Research GitHub Copilot CLI examples and use cases (terminal-ai-toolkit, copilot-mcp-server)
- [x] Find community examples of Copilot automation (@trishchuk/copilot-mcp-server)
- [x] Document command structure and capabilities from docs (in RESEARCH_FINDINGS.md)
- [x] Identify limitations from documentation/discussions (#979, #989, #934, #1004)
- [x] Compare documented capabilities vs Aider/cursor-agent (comparison matrix in research doc)
- [x] Note what would need to be tested on corp MacBook (testing checklist in research doc)

**Note**: Live testing requires active Copilot license (available on corp MacBook).
This phase focuses on research and design from available documentation.

### Phase 3: Implementation Options Comparison ✅

**COMPLETED** - Updated comparison matrix based on research:

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

See RESEARCH_FINDINGS.md for detailed comparison including security aspects.

### Phase 4: Design ralph-copilot.sh

Based on discovery, design the implementation:

- [x] Choose integration approach:
  - Option A: `gh copilot suggest` for code generation
  - Option B: `gh copilot` API if available ← **SELECTED: ACP mode (--acp)**
  - Option C: Hybrid with Ollama fallback → Future: MCP server bridge

- [x] Design prompt strategy:
  - How to pass TASK.md context → Dynamic prompt template
  - How to handle file editing → Native Copilot agentic capabilities
  - How to verify changes → grep + git log verification
  - Loop detection and iteration limits → STUCK_THRESHOLD = 3

- [x] Error handling:
  - Rate limit handling → Exponential backoff, max 5 min
  - Network failures → 3 retries with 5/15/30s delays
  - Model unavailability → Fail fast (optional fallback)
  - Fallback behavior → CLI wrapping if ACP unstable

- [x] Document in design doc:
  - Architecture decisions → DESIGN.md
  - Security considerations → Permission model, audit logging
  - Corporate approval checklist → Pre-deployment checklist
  - Known limitations → Issues #979, #989, #934, #1004

### Phase 5: Implement Design Prototype (Code Only, No Testing)

- [x] Create `ralph-copilot.sh` in `.ralph/scripts/`
- [x] Implement basic loop structure (based on ralph-aider.sh)
- [x] Add Copilot CLI integration (untested, based on docs)
- [x] Add error handling patterns
- [x] Add cost tracking placeholder (if applicable)
- [x] Document testing steps for corp MacBook
- [x] Mark clearly as "UNTESTED - Requires Copilot License"

**Note**: This creates the implementation framework. Actual testing happens on corp MacBook.

### Phase 6: Documentation & Testing Guide

- [x] Create COPILOT_BACKEND.md with:
  - Setup instructions (for users with licenses)
  - Corporate approval checklist
  - Security considerations
  - Comparison to other backends
  - Testing checklist for corp MacBook

- [x] Create COPILOT_TESTING.md with:
  - Prerequisites (active license, corp GitHub account)
  - Step-by-step testing guide for corp MacBook
  - Expected behaviors and validation steps
  - Troubleshooting common issues

- [x] Update QUICKREF.md with new backend option
- [x] Update ralph-enhancement TASK.md to note Copilot option

---

## Testing Strategy (Deferred to Corp MacBook)

**Current Machine (WSL/Personal)**:

- ❌ No Copilot license
- ✅ Can research and design
- ✅ Can write implementation code
- ✅ Can create documentation
- ❌ Cannot test `gh copilot` commands

**Corp MacBook**:

- ✅ Has Copilot license
- ✅ Corporate GitHub authentication
- ✅ Can test all `gh copilot` commands
- ✅ Can validate autonomous loop behavior
- ✅ Can measure performance and quality

**This Task's Scope**:
Focus on research, design, and implementation framework. Create comprehensive testing guide for corp MacBook validation.

---

## Research Questions to Answer

### GitHub Copilot CLI

1. Can `gh copilot` run in fully automated mode (no human prompts)?
2. What's the context window size compared to Claude?
3. Does it support file editing or just suggestions?
4. Are there rate limits on CLI usage?
5. Can we select specific models (GPT-4 vs GPT-3.5)?
6. Is there a way to pass entire task context at once?

### Corporate Security

1. Does using Copilot CLI send code to GitHub servers?
2. What's the data retention policy for Copilot requests?
3. Is there audit logging for enterprise accounts?
4. Does it comply with SOC2/HIPAA/etc?
5. What approval process is needed (IT, Legal, InfoSec)?

---

## Manual Steps Required

### 1. Install GitHub CLI (if not present)

```bash
# Ubuntu/Debian
sudo apt-get install gh

# Or with ralph helper
ralph-install-dependency system gh

# Verify
gh --version
```

### 2. Authenticate with Corporate GitHub

```bash
# Login with corporate account
gh auth login

# Select GitHub.com
# Use browser authentication
# Grant copilot permissions
```

### 3. Install Copilot Extension

```bash
# Install copilot CLI extension
gh extension install github/gh-copilot

# Verify
gh copilot --help
```

### 4. Test Copilot Access

```bash
# Test basic functionality
gh copilot suggest "write a hello world in python"

# Check if Claude is available (if corp has access)
# May need specific flags or model selection
```

### 5. Check Corporate Policies

Before implementing, verify with:

- [ ] IT Security team approval
- [ ] Legal/Compliance review if needed
- [ ] Manager awareness
- [ ] Data classification review for code being processed

---

## Deliverables

1. **Research Report**: Findings on Copilot CLI capabilities and limitations
2. **Security Assessment**: Corporate compliance analysis and recommendations
3. **Design Document**: Architecture for ralph-copilot.sh
4. **Prototype Implementation**: Working ralph-copilot.sh (if feasible)
5. **Documentation**: Setup guides and security considerations

---

## Success Metrics

- [x] Comprehensive research on Copilot CLI capabilities (doc-based) ✅ RESEARCH_FINDINGS.md
- [x] Documented security comparison (Copilot vs Aider) ✅ RESEARCH_FINDINGS.md, COPILOT_BACKEND.md
- [x] Corporate approval path identified ✅ COPILOT_BACKEND.md
- [x] Design document with architecture decisions ✅ DESIGN.md
- [x] Prototype implementation (untested, requires license) ✅ ralph-copilot.sh
- [x] Testing guide for corp MacBook validation ✅ COPILOT_TESTING.md
- [x] Clear documentation of what works without license vs with license ✅ COPILOT_BACKEND.md

---

## Notes

- **Research-focused task** - No Copilot license on this machine
- **Implementation is speculative** - Based on docs, not live testing
- **Testing deferred** - Will validate on corp MacBook with active license
- **Documentation critical** - Must be clear for corp MacBook testing
- **Ask experts** - Community research is key without live testing access

---

## Workarounds for License Limitation

### What We Can Do Without License

✅ **Research & Documentation:**

- Read GitHub Copilot CLI documentation
- Study community examples and discussions
- Review GitHub Copilot Enterprise features
- Document command structures and patterns
- Design implementation architecture

✅ **Code Implementation:**

- Write ralph-copilot.sh based on research
- Copy patterns from ralph-aider.sh
- Implement error handling
- Add logging and cost tracking
- Create testing framework

✅ **Planning:**

- Create testing guide for corp MacBook
- Document corporate approval process
- Compare backends on paper
- Design autonomous loop structure

❌ **What Requires License:**

- Running `gh copilot` commands
- Testing actual AI responses
- Measuring response quality
- Validating autonomous loop behavior
- Performance benchmarking

### Testing Phase (Corp MacBook)

When you're on corp MacBook with Copilot license:

1. Run through COPILOT_TESTING.md checklist
2. Validate all `gh copilot` commands work
3. Test ralph-copilot.sh with simple task
4. Measure quality vs cursor-agent
5. Document any issues or improvements needed
6. Update implementation based on real testing

**This approach:** Research and build now, test and validate later on licensed machine.

---

## Context for Future Agents

This task explores corporate-friendly alternatives to Aider+Anthropic API for Ralph autonomous loops. The goal is enabling Ralph in restricted corporate environments while maintaining security and compliance. Focus on:

1. **Feasibility** - Can Copilot CLI actually run autonomous loops?
2. **Security** - Will corporate InfoSec approve this?
3. **Practical** - Is it better than just using Cursor?
4. **Documented** - Clear guidance for future corporate Ralph users

Research thoroughly before implementing. GitHub Copilot is already approved by the corporate team, so this should be a straightforward compliance path compared to external AI APIs.
