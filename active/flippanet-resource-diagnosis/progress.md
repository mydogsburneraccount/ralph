# Flippanet Resource Diagnosis - Progress Log

## Iteration 1 - 2026-01-21

### Diagnostics Collected

**Disk Layout:**
- NVMe (nvme0n1): 953GB, mounted at `/` - apps/containers
- HDD (sdb): 14.6TB, mounted at `/mnt/media` - media files
- Scheduler: `mq-deadline` for HDD

**I/O Stats (iostat) - CRITICAL FINDING:**
```
Device   r_await   w_await   %util   %iowait
sdb      75-97ms   46-63ms   83-87%  33-40%
```

**Interpretation:**
- HDD is **saturated** (>80% utilization)
- Read latency **75-97ms** is extremely high (should be <20ms)
- CPU spending **33-40% waiting on I/O**

**Container Stats:**
| Container | CPU | Memory | Block I/O |
|-----------|-----|--------|-----------|
| plex | 351% | 5.7GB/24GB | 2.26TB read / 129GB write |
| qbittorrent | 52% | 4.8GB/8GB | 554GB read / 716GB write |

**qBittorrent Settings:**
- DiskCacheSize: 512MB (too small)
- MaxActiveDownloads: 10
- MaxActiveUploads: 50 (high - causing I/O)
- MaxUploads: -1 (unlimited)
- GlobalMaxSeedingMinutes: 20160 (14 days)

**Memory/Swap:**
- Total: 62GB, Used: 6.6GB, Available: 56GB
- Swap: 8GB, Used: 1.9GB
- Swappiness: 60 (default)

### Bottleneck Identified

**ROOT CAUSE: HDD I/O saturation from concurrent read/write operations**

1. qBittorrent seeding (50 active uploads) causes heavy random reads from HDD
2. qBittorrent downloading causes writes to HDD
3. Plex transcoding requires sequential reads from same HDD
4. All three compete for limited HDD bandwidth (~150-200 MB/s max)
5. Result: 75-97ms read latency starves Plex playback

**Contributing Factors:**
- Small disk cache (512MB) forces more disk I/O
- High upload slot count (50) multiplies I/O operations
- No I/O priority differentiation (Plex = qBit priority)

### Remediation Options Researched

1. **Increase qBittorrent disk cache** - Not applicable for qBit v5 with libtorrent 2.0+ (cache is auto-managed by OS kernel)
2. **Limit active uploads** - ✅ IMPLEMENTED - Reduced from 50 to 15
3. **ionice for qBittorrent** - Not needed after reducing active torrents (blkio_config already limits to 35MB/s)
4. **Rate limit uploads during peak hours** - Alternative rate limits already configured (AlternativeGlobalUPSpeedLimit)
5. **Tautulli throttle script** - Future enhancement via [qbittorrent_throttle](https://github.com/uraid/qbittorrent_throttle)

**Sources:**
- [qBittorrent disk I/O issues](https://github.com/qbittorrent/qBittorrent/issues/7656)
- [libtorrent tuning manual](https://www.libtorrent.org/tuning.html)
- [qbittorrent_throttle script](https://github.com/uraid/qbittorrent_throttle)

---

## Iteration 1 - Fix Applied

### Changes Made

**qBittorrent config (`/config/qBittorrent/qBittorrent.conf`):**
```
Session\MaxActiveDownloads: 10 → 5
Session\MaxActiveTorrents: 100 → 30
Session\MaxActiveUploads: 50 → 15
```

**Backup created:** `docker-compose-portable.yml.backup-20260121-resource-diag`

### Verification Metrics

**Before Fix:**
| Metric | Value |
|--------|-------|
| r_await | 75-97ms |
| %util | 83-87% |
| %iowait | 33-40% |
| qBit memory | 4.8GB |

**After Fix:**
| Metric | Value |
|--------|-------|
| r_await | 4ms |
| %util | 12-14% |
| %iowait | ~2% |
| qBit memory | 220MB |

### Improvement Summary

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| HDD read latency | 75-97ms | 4ms | **95% reduction** |
| HDD utilization | 83-87% | 12-14% | **85% reduction** |
| CPU iowait | 33-40% | ~2% | **95% reduction** |
| qBit memory | 4.8GB | 220MB | **95% reduction** |

### Root Cause Confirmed

The HDD I/O saturation was caused by **too many concurrent torrent operations**:
- 50 active uploads + 10 active downloads = 60 concurrent random I/O operations
- Reduced to 15 uploads + 5 downloads = 20 concurrent operations
- Result: HDD can now serve both qBit and Plex without contention

### User Confirmation Needed

To fully verify the fix, user should test Plex playback during qBit activity and confirm buffering is resolved.
