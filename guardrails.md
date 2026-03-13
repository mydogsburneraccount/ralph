# Ralph Guardrails (Signs)

> **The Learning System**
>
> When the agent makes mistakes or encounters failures, it documents them here as "Signs".
> Each future iteration reads this file FIRST, before doing any work.
> This prevents repeated mistakes and improves over time.

---

## How Signs Work

A "Sign" is a documented lesson learned. Format:

```markdown
### Sign: [Short description of the rule]
- **Trigger**: When should this rule be applied
- **Instruction**: What to do instead
- **Added after**: Which iteration/what failure caused this
```

**Example Sign**:

```markdown
### Sign: Check imports before adding
- **Trigger**: Before adding any import statement
- **Instruction**: First grep the file to check if import already exists
- **Added after**: Iteration 3 - duplicate import caused build failure
```

---

## Active Signs

### Sign: Test before committing
- **Trigger**: After creating any executable code or test file
- **Instruction**: Run the code/test to verify it works before committing to git
- **Added after**: Iteration 1 - Best practice established during workflow validation

### Sign: Use simple assertions for simple tests
- **Trigger**: When writing tests for straightforward functionality
- **Instruction**: Don't overcomplicate - use basic assertions and clear success/failure messages
- **Added after**: Iteration 1 - Simplicity validation during hello.test.js creation

### Sign: Recreate containers after image updates
- **Trigger**: When deploying a new Docker image version
- **Instruction**: Use `docker compose down` + `docker compose up -d` to recreate container, not just `restart`. Restart reuses the old image ID cached in the container config.
- **Added after**: Iteration 1 (Listenarr fix) - Container kept using old image until recreated

### Sign: Find the actual code path being executed
- **Trigger**: When applying a bug fix but not seeing expected results
- **Instruction**: Search the codebase for the actual method being called (e.g., adapter methods, not just service methods). Log messages help identify which code path is active.
- **Added after**: Iteration 1 (Listenarr fix) - Fixed wrong method initially (DownloadService instead of QbittorrentAdapter)

### Sign: Use agent-builder for Docker builds
- **Trigger**: Building any Docker image
- **Instruction**: Run `docker buildx use agent-builder` first, then use `--cache-from` and `--cache-to` flags with `$HOME/.docker-cache/[project]` for 90%+ faster rebuilds. Or use `_scripts/docker_build_cached.py`.
- **Added after**: Iteration 2 - Docker optimization achieved 95.4% speedup on Listenarr builds

### Sign: Verify healthcheck tools exist in container
- **Trigger**: Adding healthcheck to a new container service
- **Instruction**: Check what tools are available inside the container before using curl/wget. Minimal Python images often lack curl. Use Python urllib as fallback: `["CMD-SHELL", "python3 -c \"import urllib.request; urllib.request.urlopen(\\\"http://127.0.0.1:PORT\\\")\""]`
- **Added after**: Iteration 1 (kapowarr-integration) - curl not found in mrcas/kapowarr image, had to use Python healthcheck

### Sign: Log failures before retrying
- **Trigger**: When a prompt or task fails
- **Instruction**: Before retrying, log the failure using the template in `_agent_knowledge/workflows/error-logging-system.md`. Identify the error category and root cause. Patterns emerge from logged failures.
- **Added after**: Workflow patterns task - implementing error logging system from u/agenticlab1's guide

### Sign: Use container names for Docker network comms, LAN IP for VPN-isolated services
- **Trigger**: When configuring inter-container communication on flippanet
- **Instruction**: Services on `flippanet_network` reach each other by container name (e.g., `http://radarr:7878`). qBittorrent runs on the gluetun VPN network and must be reached via the host's LAN IP (verify with `ip addr`), NOT container name or Tailscale hostname. Never use Tailscale MagicDNS names for container-to-container comms.
- **Added after**: media2-arr-stack-fix task — MagicDNS breakage caused by using Tailscale hostnames instead of Docker network names

### Sign: Pull live config from flippanet, not workspace copies
- **Trigger**: When working with flippanet docker-compose or config files
- **Instruction**: The workspace copies under `projects/flippanet/` may be stale. Always `scp` or `ssh cat` the live files from `~/flippanet/` on the server before making assumptions about current state.
- **Added after**: media2-arr-stack-fix task — workspace compose file was out of date with actual server state

### Sign: Use arr app APIs, not config file edits
- **Trigger**: When modifying arr app settings (root folders, download clients, indexers)
- **Instruction**: Use the REST API (e.g., `POST /api/v3/rootfolder`) instead of editing config.xml or database files. Direct file edits can corrupt the app database and require a restart. API changes take effect immediately.
- **Added after**: media2-arr-stack-fix task — best practice for arr stack automation

### Sign: GPG passphrase blocks autonomous Vault access
- **Trigger**: When trying to retrieve secrets from Vault on flippanet
- **Instruction**: `get-secret.sh` requires GPG passphrase interactively. Fallback: read API keys directly from app config files with `docker exec <app> cat /config/config.xml | grep -i apikey`. Do NOT loop waiting for GPG access.
- **Added after**: media2-arr-stack-fix task — agents cannot enter GPG passphrase

---

## How to Add Signs

As the agent, when you encounter a failure:

1. Analyze what went wrong
2. Add a new Sign to this file with clear trigger and instruction
3. Commit this file to git
4. Future iterations will follow these signs

As the user, you can manually add signs to guide the agent's behavior.

---

## Categories of Signs

### Code Quality
- Import management
- Variable naming
- Code structure

### Testing
- Test execution order
- Test data management
- Mock/stub patterns

### Git Workflow
- Commit frequency
- Commit message format
- When to push

### Performance
- File reading strategies
- Resource usage
- Optimization approaches

---

*Signs will appear here as work progresses*
