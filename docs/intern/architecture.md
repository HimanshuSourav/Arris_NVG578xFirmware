# Architecture and source layout

This page is the map. Keep it open while you browse the tree.

## Product shape

```
  fiber (GPON) ──► NVG578LX ──► LAN Ethernet (incl. 2.5G)
                      │
                      ├── Wi-Fi 6 (802.11ax), guest / mesh flags in profile
                      ├── Voice
                      └── Management: local web UI (Motopia) + OMCI/TR-069 from ISP
```

Linux on the box is **4.1.52** (Broadcom-patched). Userspace is a mix of BusyBox, GPL daemons, Broadcom libraries, and Arris Motopia (partially missing in this release). The public drop is firmware **9.5.0h4** on SDK **5.02L.07p2** — still the right generation for this SKU’s GPON/Wi-Fi 6 role; the bundled libraries are far behind upstream. Details: [versions.md](versions.md).

## Repository vs firmware tree

| Location | In git? | Role |
| --- | --- | --- |
| `README.md`, `scripts/`, `docs/` | Yes | How we fetch, build, and document |
| `nvg578.9.5.0h4/` | **No** (gitignored) | Official OSS drop after `scripts/fetch-source.sh` |
| `axis/broadcom/` inside that drop | Regenerated | Broadcom SDK + Arris patch + **build output** |

Work as if **durable source** is: git repo + `nvg578.9.5.0h4/{build,bcm963xx,axis/arris,axis/include,axis/lib,axis/user}` and **generated** is everything under `axis/broadcom/` after extract.

## Top-level of `nvg578.9.5.0h4/`

```
nvg578.9.5.0h4/
├── build                 # Vendor entry: extract SDK, patch, make
├── install_toolchain     # Must run as root once (ARC + ARM + aarch64)
├── README                # Ubuntu 20.04 host notes (we also support 24.04 via scripts/)
├── toolchains/           # Prebuilt compilers (do not edit)
├── bcm963xx/             # Consumer tarball + bcm.patch (do not edit the .tar.gz)
└── axis/                 # Arris/CommScope overlay (survives extract)
    ├── arris/            # Small GPL (inetd, arptables) + mfg-utils
    ├── include/motopia/  # Shared Motopia headers
    ├── lib/libssl/       # OpenSSL overlay (Motopia-tuned)
    ├── user/             # wget, udev, …
    ├── prop/             # Proprietary extras (e.g. widedhcpv6 helpers)
    └── broadcom/         # CREATED by build: SDK + objects + images
```

## Build pipeline

`scripts/build-nvg578.sh` does the same logical steps as vendor `./build`, without wiping a tree that already exists, and with two host-tool workarounds (Perl 5.22.1, GNU89 inline for squashfs).

Vendor `./build` (simplified):

1. `export AXIS_ROOT=$TOP_DIR/axis`
2. **Delete** `axis/broadcom`
3. Unpack `bcm963xx_5.02L.07p2_consumer_release.tar.gz` (inner file is `bcm963xx_5.02L.07p2_consumer.tar.gz`)
4. Unpack the inner tarball **into** `axis/broadcom`
5. `patch -p1 < bcm963xx/bcm.patch`
6. `make PROFILE=NVG578LX_AX WIFI_AX=1`

`bcm.patch` is large (~thousands of files). It is not “Arris branding only.” It:

- Restores Broadcom sources that the public tarball ships empty or stubbed (GPON/OMCI, RDP, many drivers)
- Adds Motopia **Makefile targets** (`webui`, `dropbear`, `libmotopia`, …)
- Injects `-DMOTOPIA` and `-I$(AXIS_ROOT)/...` into some drivers

**Arris C that actually lives in this drop** is mostly under `axis/arris/`, not a full copy of Motopia apps.

### After extract: Broadcom SDK (`axis/broadcom/`)

| Path | What it is |
| --- | --- |
| `build/Makefile` | Top-level make (kernel, userspace, image) |
| `make.common` | Includes the **profile file** for `$(PROFILE)` |
| `kernel/linux-4.1/` | Linux kernel |
| `bcmdrivers/` | SoC drivers (enet, GPON, Wi-Fi host, DPI, …) |
| `userspace/public/` | Broadcom-public libs (`cms_*`, `libssl`, …) |
| `userspace/gpl/` | GPL apps/libs (BusyBox, iptables, dnsmasq, PCRE, …) |
| `userspace/private/` | Proprietary Broadcom — often incomplete in OSS |
| `hostTools/` | PC-side tools: squashfs, image packer, `gendefconfig` |
| `rdp/` | Runner datapath (hardware offload) — treat as specialized |
| `targets/NVG578LX_AX/` | **This SKU**: profile, staged rootfs, `.w` images |
| `targets/fs.src/` | Rootfs skeleton (init scripts, `/etc`) |

Kernel `.config` is **generated**, not hand-edited as the source of truth. `hostTools/scripts/gendefconfig` concatenates `gendefconfig.d/*.conf`. Arris mappings live in `gendefconfig.d/91arris.conf` (Docker cgroups, VLAN netfilter, Motopia kernel options).

## Profile: the feature switchboard

Authoritative flags:

`nvg578.9.5.0h4/axis/broadcom/targets/NVG578LX_AX/NVG578LX_AX`

`make.common` includes that file. Search it; do not memorize it.

Patterns:

- `BUILD_*` — Broadcom userspace packages (`BUILD_IPTABLES=dynamic`, `# BUILD_HTTPD is not set`)
- `BRCM_*` — Broadcom kernel/driver options
- `CONFIG_MOTOPIA_*` — Arris product features

Examples that matter for security (this SKU):

| Flag | In this profile | Implication |
| --- | --- | --- |
| `BUILD_HTTPD_none=y` | Broadcom web server **off** | Do not hunt `httpd` for the LAN UI |
| `CONFIG_MOTOPIA_MUHTTPD=y` / `WEBUI=y` / `HTTPS=y` | Arris UI **on** | Real UI is Motopia; source may be missing |
| `# BUILD_SSHD is not set` / `# BUILD_TELNETD is not set` | Broadcom SSH/telnet **off** | Dropbear is the Motopia SSH path |
| `BUILD_OMCI=y`, `# BUILD_OMCI_AUTH is not set` | OMCI **on**, auth **off** | ISP-side management with no OMCI auth in this config |
| `CONFIG_MOTOPIA_DOCKER=y` | Docker **on** | Extra kernel attack surface (namespaces, overlay, IPVS) |
| `BUILD_WLHSPOT=y` | Guest/hotspot framework **on** | Isolation bugs are high impact |
| `BUILD_DISABLE_EXEC_STACK=y`, `BRCM_USER_SSP=y` | Some hardening **on** | Do not disable these “to make it build” |
| `# BUILD_HASHED_PASSWORDS is not set` | Broadcom hashed-password option **off** | Check how Motopia actually stores secrets |

`WIFI_AX=1` on the make command line enables Wi-Fi 6 bits for this board.

## Control plane vs data plane (mental model)

```
                    ┌─────────────────────────────────────┐
  LAN / Wi-Fi  ──►  │  Linux netfilter, ebtables, iptables │  ◄── guest isolation, NAT
                    │  Broadcom Runner (RDP) offload       │
                    └─────────────────────────────────────┘
                                      │
                    ┌─────────────────┴───────────────────┐
                    │  Motopia: sysmgr, smartdb, muhttpd, │
                    │  wl80211, wanmgmt, TR-069 CLI       │
                    │  (many apps not in this OSS tree)   │
                    └─────────────────────────────────────┘
                                      │
  Fiber  ──►  GPON driver + OMCI  ────┘  ISP can manage the box
```

If a bug is “admin password on the web UI,” you are in Motopia/web/smartdb (maybe not in-tree). If a bug is “guest clients can ARP the LAN,” you may be in ebtables / `qevt_client.c` / iptables Arris extensions — **those are in-tree.**

## How Arris code is wired in

There is no single `cp -a axis/arris axis/broadcom`. Wiring is:

1. **`AXIS_ROOT`** — headers such as `bcmdrivers/.../enet/.../Makefile` adding `-I$(AXIS_ROOT)/arris/include/shared`
2. **`bcm.patch`** — Makefile targets and `-DMOTOPIA`
3. **Profile `CONFIG_MOTOPIA_*`** — compiled in or out
4. **`arris_prereqs` in `build/Makefile`** — builds zlib + OpenSSL before much of userspace
5. **Files that already sit under `axis/arris/`** — compiled when corresponding make targets run (`inetd`, arptables, mfg-utils)

## What to edit when you have a real patch

| Kind of change | Persist it in |
| --- | --- |
| Host/build environment | `scripts/` in git |
| Arris GPL (`inetd`, arptables) | `axis/arris/` (in the tarball; we do not vendor it in git yet — copy the file into a git-tracked overlay or document a patch series) |
| SDK files that come from the tarball | A **new** patch applied after `bcm.patch` (preferred) or an addition to `scripts/build-nvg578.sh` |
| Profile flags | The profile file **after extract**, then capture a patch; or document `make menuconfig` if that is the team process |
| Generated `.w` images | Never commit. A packer success is not a complete Motopia rootfs — see [deploy.md](deploy.md). |

Until we add a git-tracked overlay for `nvg578.9.5.0h4/`, treat intern PRs as: **docs + scripts + a `patches/` directory of quilt/git patches** applied after extract. See [patches/README.md](../../patches/README.md). Do not commit the 760 MB tree.

## First files to open (hands-on)

After extract, in this order:

1. `nvg578.9.5.0h4/build` — 70 lines; you now understand extract/patch/make
2. `axis/broadcom/targets/NVG578LX_AX/NVG578LX_AX` — search the flags table above
3. `axis/broadcom/targets/fs.src/etc/init.d/ssl.sh` — how TLS keys are created at boot
4. `axis/broadcom/userspace/public/libs/libssl/makefile` — which algorithms are compiled
5. `axis/arris/gpl/inetd/inetd.c` — super-server for optional network daemons
6. `axis/broadcom/hostTools/scripts/gendefconfig.d/91arris.conf` — profile → kernel `.config`
