# Ralph Task: Build and Deploy Fixed Listenarr Docker Image

## Task Overview

**Goal**: Build a custom Listenarr Docker image with the qBittorrent category filtering bug fixed, and deploy it to flippanet.

**⚠️ Important Architecture Notes**:

- **This machine (yggdrasil)**: Windows development machine - used ONLY for building the Docker image
- **flippanet**: Remote Linux server (accessed via SSH) - this is where Listenarr currently runs in production
- **DO NOT** run docker-compose on yggdrasil - Listenarr only runs on flippanet
- The build happens on yggdrasil, then we transfer the image to flippanet and replace the running container there

**Context**:

- Bug confirmed in `listenarr.api/Services/DownloadService.cs` line 2783
- Missing `?category=` parameter on `/api/v2/torrents/info` API call
- GitHub issue filed: <https://github.com/therobbiedavis/Listenarr/issues/310>
- Current Listenarr on flippanet: `ghcr.io/therobbiedavis/listenarr:canary` (v0.2.47.0)
- This fix will replace that container with our custom-built image

**Test Command**:

```bash
ssh -i ~/.ssh/flippanet flippadip@flippanet "docker logs listenarr 2>&1 | grep 'Before filtering' | head -5"
```

**Success Indicator**: Log should show fewer than 10 queue items (only audiobooks category) instead of 30+ items (all torrents)

---

## Success Criteria

### Phase 1: Local Build Environment Setup (ON YGGDRASIL)

**Location: This Windows machine (yggdrasil) ONLY**

- [x] Clone Listenarr repo to local machine: `cd C:\Users\Ethan\Code && git clone https://github.com/therobbiedavis/Listenarr.git listenarr-fix`
- [x] Verify .NET 8 SDK is available or install it (Docker build includes .NET 8 SDK internally)
- [x] Confirm Docker Desktop is running on yggdrasil
- [x] Navigate to working directory: `cd C:\Users\Ethan\Code\listenarr-fix`

### Phase 2: Apply the Fix (ON YGGDRASIL)

**Location: C:\Users\Ethan\Code\listenarr-fix on this Windows machine**

- [x] Locate `listenarr.api/Services/DownloadService.cs` in cloned repo
- [x] Find line 2783: `var torrentsResponse = await httpClient.GetAsync($"{baseUrl}/api/v2/torrents/info");`
- [x] Add category parameter extraction before line 2783:

  ```csharp
  var category = client.Settings.TryGetValue("category", out var categoryObj) ? categoryObj?.ToString() : null;
  var categoryParam = !string.IsNullOrEmpty(category) ? $"?category={Uri.EscapeDataString(category)}" : "";
  ```

- [x] Modify line 2783 to: `var torrentsResponse = await httpClient.GetAsync($"{baseUrl}/api/v2/torrents/info{categoryParam}");`
- [x] Verify syntax is correct (no compilation errors)
- [x] Commit change locally: `git commit -m "fix: add category filter to qBittorrent queue fetching"`

### Phase 3: Build Docker Image (ON YGGDRASIL)

**Location: C:\Users\Ethan\Code\listenarr-fix on this Windows machine**

- [x] Build Docker image: `docker build -t listenarr:fixed-category-v1 .`
- [x] Verify image built successfully
- [x] Tag image for deployment: `docker tag listenarr:fixed-category-v1 listenarr:fixed-category`
- [x] Test image locally on yggdrasil (optional): Run container and verify it starts

### Phase 4: Transfer to flippanet (REMOTE SERVER)

**Location: Transfer from yggdrasil → flippanet (remote Linux server via SSH)**

- [x] Save Docker image to tar on yggdrasil: `docker save listenarr:fixed-category > listenarr-fixed.tar`
- [x] Copy tar to flippanet: `scp -i ~/.ssh/flippanet listenarr-fixed.tar flippadip@flippanet:~/`
- [x] SSH to flippanet: `ssh -i ~/.ssh/flippanet flippadip@flippanet`
- [x] On flippanet, load image: `docker load < ~/listenarr-fixed.tar`
- [x] Verify image loaded: `docker images | grep listenarr`
- [x] Clean up tar file on both machines

### Phase 5: Update docker-compose and Deploy (ON FLIPPANET)

**Location: SSH session on flippanet (remote Linux server) - ALL commands run there**

- [x] Ensure you're SSH'd to flippanet: `ssh -i ~/.ssh/flippanet flippadip@flippanet`
- [x] Navigate to docker-compose directory: `cd ~/flippanet`
- [x] Backup current docker-compose: `cp ~/flippanet/docker-compose-portable.yml ~/flippanet/docker-compose-portable.yml.backup-$(date +%Y%m%d)`
- [x] Edit `~/flippanet/docker-compose-portable.yml`
- [x] Change listenarr image from `ghcr.io/therobbiedavis/listenarr:canary` to `listenarr:fixed-category`
- [x] Stop current Listenarr: `docker compose -f docker-compose-portable.yml down listenarr`
- [x] Start with new image: `docker compose -f docker-compose-portable.yml up -d listenarr`
- [x] Verify container started: `docker ps | grep listenarr`

### Phase 6: Verification (ON FLIPPANET)

**Location: SSH session on flippanet - monitoring the replaced container**

- [ ] Wait 30 seconds for Listenarr to initialize
- [ ] Check logs for "Before filtering" messages
- [ ] Verify queue item count is low (< 10) instead of high (30+)
- [ ] Test search functionality in Listenarr UI - verify it's not slow/hanging
- [ ] Verify existing audiobook downloads still show up correctly
- [ ] Test adding new audiobook - verify category is still set correctly
- [ ] Monitor for 5 minutes to ensure no crashes or errors

### Phase 7: Documentation

- [ ] Update local docker-compose copy with the image change
- [ ] Document the custom image in project notes
- [ ] Create rollback procedure document
- [ ] Update GitHub issue comment with "deployed custom fix, testing in production"
- [ ] Add note to `.ralph/guardrails.md` about maintaining custom Docker image

---

## Rollback Plan (If Needed)

If the fix causes issues:

```bash
# On flippanet
cd ~/flippanet
docker-compose down listenarr
# Restore backup
cp docker-compose-portable.yml.backup-YYYYMMDD docker-compose-portable.yml
docker-compose up -d listenarr
```

---

## Notes

- **Build time**: Docker build will take 5-10 minutes (C# compilation)
- **Image size**: ~500MB (same as official image)
- **Transfer time**: ~2-3 minutes over SSH to flippanet
- **Maintenance**: Will need to reapply fix if we want to pull upstream updates later
- **Testing**: Can test locally on yggdrasil first before deploying to flippanet
