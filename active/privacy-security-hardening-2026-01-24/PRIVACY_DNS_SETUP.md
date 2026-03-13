# Privacy-Focused DNS Configuration

> Part of Phase 6: Privacy Tool Installation
> Purpose: Replace ISP DNS with privacy-respecting alternatives

---

## Current Status

### Yggdrasil (Windows/WSL2)
- **Current DNS**: `10.255.255.254` (likely WSL2 internal resolver → Windows DNS)
- **Actual upstream**: Unknown (likely ISP or Windows default)
- **Privacy risk**: Medium (DNS queries visible to ISP)

### Flippanet (Ubuntu Server)
- **Current DNS**: `192.168.110.1` (router/gateway)
- **Actual upstream**: Likely ISP DNS servers
- **Privacy risk**: High (all DNS queries logged by ISP)

---

## Recommended DNS Providers (2026 Privacy Consensus)

### Option 1: Quad9 (Recommended for Security + Privacy)

**Servers:**
- Primary: `9.9.9.9`
- Secondary: `149.112.112.112`
- IPv6: `2620:fe::fe`, `2620:fe::9`

**Features:**
- Blocks malware/phishing domains
- No logging of IP addresses
- DNSSEC validation
- Based in Switzerland (strong privacy laws)
- Non-profit organization

**Best for**: Security-focused setup with malware blocking

### Option 2: Cloudflare 1.1.1.1

**Servers:**
- Primary: `1.1.1.1`
- Secondary: `1.0.0.1`
- IPv6: `2606:4700:4700::1111`, `2606:4700:4700::1001`

**Features:**
- Claims no logging (privacy policy)
- Very fast (often faster than Quad9)
- DNSSEC validation
- No malware filtering (pure DNS)

**Best for**: Speed-focused privacy

### Option 3: Mullvad DNS (For Mullvad VPN Users)

**Servers:**
- Standard: `194.242.2.2`
- AdBlock: `194.242.2.3` (blocks ads/trackers)
- IPv6: `2a07:e340::2`, `2a07:e340::3`

**Features:**
- Run by Mullvad VPN
- AdBlock version includes tracker blocking
- No logging
- DoH/DoT support

**Best for**: Mullvad VPN users wanting unified provider

---

## Implementation Plan

### Flippanet Configuration (Ubuntu 24.04)

**Method 1: systemd-resolved (Recommended)**

```bash
# SSH to flippanet
ssh -i ~/.ssh/flippanet flippadip@flippanet

# Edit resolved.conf
sudo nano /etc/systemd/resolved.conf

# Add these lines (uncomment and set):
[Resolve]
DNS=9.9.9.9 149.112.112.112
FallbackDNS=1.1.1.1 1.0.0.1
DNSSEC=yes
DNSOverTLS=opportunistic

# Restart systemd-resolved
sudo systemctl restart systemd-resolved

# Verify
resolvectl status
nslookup google.com
```

**Verification:**
```bash
# Should show Quad9 servers
resolvectl status | grep "DNS Servers"

# Test resolution
dig @9.9.9.9 google.com
```

**Method 2: Direct /etc/resolv.conf (If systemd-resolved disabled)**

```bash
# Make immutable to prevent overwrites
sudo chattr -i /etc/resolv.conf
sudo nano /etc/resolv.conf

# Replace contents with:
nameserver 9.9.9.9
nameserver 149.112.112.112
nameserver 1.1.1.1

# Make immutable
sudo chattr +i /etc/resolv.conf
```

---

### Yggdrasil (Windows/WSL2) Configuration

**Windows DNS Change (Affects WSL2):**

1. Open Settings → Network & Internet → Ethernet/Wi-Fi
2. Click adapter → Properties
3. Select "Internet Protocol Version 4 (TCP/IPv4)" → Properties
4. Select "Use the following DNS server addresses":
   - Preferred: `9.9.9.9`
   - Alternate: `149.112.112.112`
5. Click OK

**Or via PowerShell (Admin):**
```powershell
# Get network adapter name
Get-NetAdapter

# Set DNS (replace "Ethernet" with your adapter name)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("9.9.9.9","149.112.112.112","1.1.1.1")

# Verify
Get-DnsClientServerAddress
```

**WSL2-Specific Configuration:**

Create/edit `/etc/wsl.conf` in WSL2:
```bash
sudo nano /etc/wsl.conf

# Add:
[network]
generateResolvConf = false
```

Then manually set `/etc/resolv.conf`:
```bash
sudo rm /etc/resolv.conf
sudo nano /etc/resolv.conf

# Add:
nameserver 9.9.9.9
nameserver 149.112.112.112
nameserver 1.1.1.1
```

Restart WSL2:
```powershell
# In Windows PowerShell
wsl --shutdown
```

---

## Docker Container DNS

### Update docker-compose.yml for privacy DNS

Add to services that need custom DNS:

```yaml
services:
  example-service:
    # ... other config
    dns:
      - 9.9.9.9
      - 149.112.112.112
```

**Note**: Gluetun (VPN container) handles its own DNS via VPN provider. Don't override.

---

## DNS-over-HTTPS (DoH) / DNS-over-TLS (DoT)

### For Maximum Privacy (Encrypted DNS Queries)

**Quad9 DoH:**
- URL: `https://dns.quad9.net/dns-query`

**Cloudflare DoH:**
- URL: `https://cloudflare-dns.com/dns-query`

**Implementation:**

1. **Firefox/Tor Browser/Mullvad Browser:**
   - Settings → Privacy & Security → DNS over HTTPS
   - Select "Max Protection"
   - Choose Cloudflare or Custom (Quad9 URL)

2. **System-wide (Linux):**
   ```bash
   # Install dnscrypt-proxy
   sudo apt install dnscrypt-proxy

   # Configure for Quad9 DoH
   sudo nano /etc/dnscrypt-proxy/dnscrypt-proxy.toml
   # Set server_names = ['quad9-doh']

   sudo systemctl enable dnscrypt-proxy
   sudo systemctl start dnscrypt-proxy
   ```

---

## Testing & Verification

### DNS Leak Test

Visit these sites (after DNS change):
- https://dnsleaktest.com
- https://www.dnsleak.com
- https://ipleak.net

**Expected results:**
- Should show Quad9 or Cloudflare servers
- Should NOT show ISP DNS servers

### Command-Line Tests

```bash
# Test resolution using new DNS
nslookup google.com 9.9.9.9

# Check what DNS server is actually used
dig +short myip.opendns.com @resolver1.opendns.com

# DNSSEC validation test
dig +dnssec google.com
```

---

## Rollback

### Flippanet
```bash
# Restore to default
sudo nano /etc/systemd/resolved.conf
# Comment out DNS= lines or set DNS=

sudo systemctl restart systemd-resolved
```

### Yggdrasil (Windows)
1. Network adapter properties → TCP/IPv4
2. Select "Obtain DNS server address automatically"
3. OK

---

## Security Considerations

### Benefits
- ✅ ISP cannot see DNS queries
- ✅ Malware/phishing protection (Quad9)
- ✅ DNSSEC validation prevents DNS spoofing
- ✅ No logging of queries (privacy)

### Limitations
- ⚠️ DNS provider can still see queries (trust Quad9/Cloudflare vs ISP)
- ⚠️ DNS-over-HTTPS adds latency (minimal)
- ⚠️ Gluetun VPN traffic already encrypted (DNS change for non-VPN traffic only)

### Best Practice
- Use Quad9 for general privacy + security
- Use DoH/DoT for encrypted DNS queries
- VPN traffic (Gluetun) already handles DNS privately

---

## Implementation Status

- [ ] Configure Quad9 DNS on flippanet
- [ ] Configure Quad9 DNS on yggdrasil (Windows)
- [ ] Test DNS leak prevention
- [ ] Enable DoH in browsers (when installed)
- [ ] Verify DNSSEC validation working
- [ ] Document configuration in operational guide

---

**Next**: Proceed with DNS configuration or await user approval.
