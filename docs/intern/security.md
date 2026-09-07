# Security map and intern contribution guide

Focus: **attack surface you can actually see in this OSS tree**, plus honest gaps where Motopia source is missing.

## Threat model (keep it small)

Assume:

- **LAN attacker** — untrusted device on Ethernet or Wi-Fi (including guest).
- **WAN / GPON attacker** — whoever sits on the ISP side (compromised OLT, malicious OMCI, TR-069).
- **Local admin** — someone with the gateway password (phishing, default creds, CSRF).
- **Supply chain / image** — unsigned or weakly signed firmware, leftover debug tools.

We are **not** trying to “jailbreak the ISP” as a goal. We **are** trying to make the open userspace harder to abuse and to document residual risk.

## Surfaces, with paths

### 1. TLS and host keys (in-tree, high value)

`axis/broadcom/targets/fs.src/etc/init.d/ssl.sh`

At boot, if no key exists, the box:

- Mixes `/proc/nvram/BaseMacAddr` into `/dev/random`
- Generates a **self-signed RSA-2048** cert valid **36500 days**
- Subject is a placeholder (`CN=example.com`, `ST=Denial`)
- Stores the key in `/data` or NVRAM (`pspctl`)
- Converts the key for **Dropbear**

Intern questions:

- Is the key world-readable at any step?
- Does seeding from the MAC make the key predictable on first boot?
- Should we stop converting the same key for SSH and HTTPS?

OpenSSL **1.1.1b** (26 Feb 2019) is what this product builds:

`userspace/public/libs/libssl/include/openssl/opensslv.h`

The makefile (`userspace/public/libs/libssl/makefile` and overlay `axis/lib/libssl/makefile`) uses `OPENSSL_SMALL_FOOTPRINT` and turns **off** DSA/ECDSA/ECDH/engine/DSO (and more). That shrinks attack surface **and** can block modern cipher suites. Any “upgrade OpenSSL” ticket must re-check Motopia `linux-arm-motopia` config in `Configurations/1000-motopia-targets.conf`.

### 2. Web UI / HTTP (mostly missing source)

Profile:

- Broadcom: `BUILD_HTTPD_none=y`
- Arris: `CONFIG_MOTOPIA_MUHTTPD=y`, `CONFIG_MOTOPIA_WEBUI=y`, `CONFIG_MOTOPIA_HTTPS=y`, `CONFIG_MOTOPIA_WEBUI_FRONTIER=y`

Makefile targets exist (`webui`, muhttpd) after `bcm.patch`. **Application source is typically not in this drop.** Do not invent stub apps.

What you *can* do without that source:

- Audit CGI helpers that **are** here: `userspace/gpl/apps/haserl-0.9.35/` (built with `-DMOTOPIA -DUSE_LUA`) and `lua-5.3.4`
- Audit `userspace/public/include/cms_pwd.h` (`cmsUtil_pwEncrypt`) even though CMS httpd is off — other binaries may still link it
- Document missing-source as a **blocker** for XSS/CSRF work, not as an excuse to skip TLS/init

### 3. SSH / inetd / telnet (mixed)

- Broadcom `BUILD_SSHD` / `BUILD_TELNETD` / BusyBox telnet: **off**
- Dropbear **2016.74** is a make target: `userspace/gpl/apps/dropbear-2016.74` — **directory often absent**. Version number alone is a CVE goldmine if the binary is on the image; confirm with a built rootfs (`targets/NVG578LX_AX/fs.install/`) after a successful compile
- Arris **inetd** **is** here: `axis/arris/gpl/inetd/` — reads `/etc/inetd.conf` (Motopia also mentions `/etc/config/inetd.conf`). Audit for debug listeners left enabled

### 4. Firewall, NAT, guest Wi-Fi (in-tree)

| Piece | Path |
| --- | --- |
| iptables | `userspace/gpl/apps/iptables/` + `iptables-1.4.16.3-arris.patch` (Motopia match/targets) |
| ebtables | `userspace/gpl/apps/ebtables/` |
| arptables | `axis/arris/gpl/arptables/` |
| ipset | `userspace/gpl/apps/ipset/` (`CONFIG_MOTOPIA_IP_SET=y`) |
| conntrack | `userspace/gpl/apps/conntrack/` |
| Guest SSID / ebtables exceptions | `axis/arris/prop/user/mfg-utils/wlcfg_rctl/qevt_client.c` (guest SSID from SmartDB, super-admin-access ebtables holes) |

Classic intern bugs: guest clients reaching management IP; IPv6 bypassing IPv4 filter; helper modules (`FTP`/`SIP` ALGs) punching unexpected holes. Profile enables several NAT ALGs — list them from `NVG578LX_AX` before changing them.

### 5. GPON / OMCI (ISP control plane)

Drivers: `bcmdrivers/broadcom/char/gpon/impl6/` (`bcm_omci.c`, PLOAM, etc.).

Profile: `BUILD_OMCI=y`, `BUILD_OMCI_TR69_DUAL_STACK=y`, **`# BUILD_OMCI_AUTH is not set`**.

You will not “fix OMCI” in a weekend. You **can**:

- Write a clear residual-risk note: LAN hardening does not stop a malicious OLT
- Ensure debug shells (`gpon_stack_shell.c` is listed in CommScope OSS notes) are not reachable from LAN
- Never log GPON passwords (`BRCM_GPON_PASSWORD` in profile) in PRs

### 6. Docker

`CONFIG_MOTOPIA_DOCKER=y` pulls in cgroups, user namespaces, overlayfs, veth, IPVS via `91arris.conf`. CMS headers mention Docker **18.03.1-ce**. If the daemon is on the image, it is a serious LAN-to-root path. First task: **prove whether dockerd is in `fs.install`**, then argue for disabling the profile flag on Ziply images if unused.

### 7. Outdated libraries you can name in a CVE pass

The product release is **9.5.0h4** (OSS tarball 2022-08-10, Broadcom SDK **5.02L.07p2**). Day-to-day GPON/Wi-Fi/NAT still matches this SKU; **bundled GPL/crypto/kernel are years behind upstream**. Full inventory, ISP vs OSS caveat, and named missing CVEs: **[versions.md](versions.md)**.

Confirm versions in-tree (or on a built rootfs) before filing anything public. Short list:

| Component | Typical version here | Notes |
| --- | --- | --- |
| OpenSSL | 1.1.1b | EOL; last public 1.1.1 was 1.1.1w |
| PCRE | 8.32 | `userspace/gpl/libs/pcre-8.32/` |
| Linux | 4.1.52 | Broadcom fork; 4.1 EOL since 2018 |
| BusyBox | 1.30.1 | Under `userspace/gpl/apps/busybox/` |
| dnsmasq | 2.79 | Predates DNSpoq (2.83) and later DNSSEC limits |
| zlib | 1.2.7 | Predates CVE-2018-25032 / CVE-2022-37434 |
| Dropbear | 2016.74 | Make target; directory often **absent** — confirm on image |
| iptables | 1.6.2 + Arris patch | Patch filename still says 1.4.16.3 |

Kernel and Wi-Fi blobs (`bcmdrivers/broadcom/net/wl/`) are **not** intern starter upgrades. Missing a CVE in NVD ≠ proven remote-root; see [versions.md#reachability-not-every-cve-is-on-the-box](versions.md#reachability-not-every-cve-is-on-the-box).

### 8. Debug and leftover attack surface

This profile enables **tcpdump**, **iperf3**, **stress**, **sysstat**, high `BCM_DEFAULT_CONSOLE_LOGLEVEL`, `BUILD_DEBUG_TOOLS=y`. Great for bring-up; bad for a shipped CPE. A valid intern project is a **production vs debug** profile split (document which flags to flip, test that NAT/Wi-Fi still work).

`# CMS_BYPASS_LOGIN is not set` is good — do not enable it.

## What you should not touch first

- `rdp/` Runner firmware and generated `.w` images
- Wi-Fi firmware blobs under `bcmdrivers/broadcom/net/wl/`
- `toolchains/` and `/opt/toolchains`
- Inventing Motopia `webui/` from scratch
- Secure-boot keys under `targets/keys/` if present
- “Upgrade the kernel to 6.x” as a first ticket

## Starter tickets (pick one)

Each ticket should end in: **repro notes**, **files touched**, **how you tested** (even if only compile + read of generated `fs.install`).

1. **Inventory the image, don’t guess.** After a build (or from `fs.install` if present), list setuid bits, listening init scripts, `dropbear`, `muhttpd`, `docker`. Write `docs/intern/findings/image-inventory.md`.
2. **`ssl.sh` hardening.** Tighter permissions, don’t reuse HTTPS key for SSH if dropbear is present, shorter default validity, don’t use a joke DN in production. Keep it boot-safe if `/data` is missing.
3. **inetd config audit.** Trace default `inetd.conf` in `targets/fs.src` / Arris overlays. Propose disabling unused services.
4. **Guest isolation.** Read `qevt_client.c` guest/ebtables paths. Document intended vs actual isolation; add a regression checklist (guest cannot hit `192.168.x.1:443` unless a named feature is on).
5. **OpenSSL 1.1.1b CVE mapping.** Start from [versions.md](versions.md). Spreadsheet: CVE id, whether Motopia compile flags mean we are unaffected, leftover risk (e.g. TLS 1.0). Write `docs/intern/findings/openssl-cve-map.md`. No silent “upgrade” without a build.
6. **OMCI auth flag.** Research what `BUILD_OMCI_AUTH` needs; if it cannot be enabled without ISP support, document why and which LAN mitigations still matter.
7. **Docker off for Ziply.** If `fs.install` has no docker runtime, flip `CONFIG_MOTOPIA_DOCKER` and record kernel option deltas from `91arris.conf`.
8. **PCRE / dnsmasq version bump (GPL only).** Smallest upstream patch that still builds with Motopia `CFLAGS`. Watch autoconf: Broadcom exports `-Werror=uninitialized`, which once caused `#define const` in PCRE `config.h` and broke C++.

Before opening a PR, walk [pr-checklist.md](pr-checklist.md). Persist SDK edits under [patches/](../../patches/README.md), not only inside the generated tree.

## How to test security changes

- **Compile test:** `scripts/build-nvg578.sh NVG578LX_AX` if present (long), otherwise vendor `./build NVG578LX_AX` from `nvg578.9.5.0h4/`. For library-only work, `make` in that subdirectory after one full extract.
- **Rootfs inspect:** `find targets/NVG578LX_AX/fs.install -perm /4000` and `grep -R dropbear fs.install/etc`
- **Do not** run exploit PoCs against networks you do not own
- If you add a firewall rule, test: WAN ping off, LAN DHCP on, guest isolation, IPv6

## Talking about bugs

Use: component, version, flag, path, expected vs actual.

Avoid: “this router is pwned,” untested CVE claims, and publishing ISP-specific credentials.
