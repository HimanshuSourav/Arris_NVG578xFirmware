# Intern guide — NVG578 firmware (security-focused)

Welcome. This folder is the onboarding path for someone who has not worked on ISP home gateways before. Read it in order. The goal after a week is not to know every file; it is to know **where to look**, **what you can change**, and **how security work actually lands** in this tree.

## What you will be working on

The [NVG578LX](https://sourceforge.net/projects/nvg578.arris/) is a CommScope/Arris GPON home gateway (fiber ONT + Wi-Fi 6 router + voice). This repository is a project to **fetch the public open-source release, build flashable images, and change behavior** — especially hardening.

The GitHub repo does **not** contain the firmware tree. GitHub rejects files over 100 MB. You fetch the ~760 MB SourceForge tarball first (see [Getting the source](#getting-the-source)).

## Reading order (do this)

| Day | Read | Then do |
| --- | --- | --- |
| 1 | This page + [architecture.md](architecture.md) | Fetch the tarball, list `nvg578.9.5.0h4/`, find `build` and `bcm.patch` |
| 2 | [architecture.md](architecture.md) build pipeline | Open `targets/NVG578LX_AX/NVG578LX_AX` and search `CONFIG_MOTOPIA_` / `BUILD_HTTPD` / `BUILD_OMCI` |
| 3 | [security.md](security.md) + [versions.md](versions.md) | Trace `ssl.sh`, OpenSSL makefile, Arris `inetd`; note 9.5.0h4 vs in-tree library ages |
| 4 | [CONTRIBUTING.md](../../CONTRIBUTING.md) + [pr-checklist.md](pr-checklist.md) + [deploy.md](deploy.md) (incl. [upload/flash checks](deploy.md#firmware-upload-and-flashing-checks) and [serial](deploy.md#should-i-open-the-box-for-a-serial-port-education)) | Pick a starter ticket; **do not** open the in-service ONT to flash |

## Getting the source

The firmware tree is gitignored. Fetch it once, then browse.

If `scripts/fetch-source.sh` exists in this clone (build-helper change):

```bash
./scripts/fetch-source.sh
./scripts/setup-host.sh          # once per machine
./scripts/build-nvg578.sh NVG578LX_AX   # optional; long
```

Otherwise download `nvg578.9.5.0h4.tar.gz` from [SourceForge](https://sourceforge.net/projects/nvg578.arris/files/nvg578.9.5.0h4.tar.gz/download), extract it at the repo root as `nvg578.9.5.0h4/`, then follow the vendor `README` inside that directory (`./install_toolchain`, `./build NVG578LX_AX`).

You do **not** need a successful image to start reading code. After one successful extract (even a failed later compile), `nvg578.9.5.0h4/axis/broadcom/` exists and is the SDK to study.

Vendor images, if the build finishes, land in:

`nvg578.9.5.0h4/axis/broadcom/targets/NVG578LX_AX/`

Example names: `bcmNVG578LX_AX_nand_cferom_fs_image_128_puresqubi.w`

## Three facts that save weeks of confusion

1. **`./build` deletes `axis/broadcom/` and recreates it** from tarballs + `bcm.patch`. Edits under `axis/broadcom/` vanish on the next full extract unless you also persist them (patch, overlay, or `scripts/build-nvg578.sh`).
2. **“Motopia” is Arris/CommScope’s userspace layer** (web UI, config DB, HTTPS daemon, TR-069). The **build system references it**; much of that **application source is not in this public drop**. You can still do real security work on GPL userspace, OpenSSL config, init scripts, firewall tools, and profile flags that *are* here.
3. **Broadcom CMS httpd/SSH/telnet are off** in this product profile. Arris equivalents (`CONFIG_MOTOPIA_MUHTTPD`, `CONFIG_MOTOPIA_WEBUI`, dropbear) are **on** — but dropbear/webui trees may be missing from the OSS tarball. Always check the filesystem, not only Makefile targets.

## Glossary (learn these names)

| Term | Meaning |
| --- | --- |
| **GPON** | Fiber access (ISP uplink). The box is an ONT/gateway, not a generic Wi-Fi AP. |
| **OMCI** | ISP management protocol over the PON. Can change config without the LAN web UI. |
| **Motopia** | Arris/CommScope product software on top of Broadcom’s SDK. |
| **CMS** | Broadcom Configuration Management System. Largely unused here (`# BUILD_BRCM_CMS is not set`). |
| **SmartDB / SDB** | Arris config database (`CONFIG_MOTOPIA_SMARTDB=y`). Keys look like `phy.wl80211[2].ssid[N].ssid-name`. |
| **Profile** | Feature flags for one product SKU. Ours is `NVG578LX_AX`. |
| **bcm.patch** | Huge diff applied after extracting the Broadcom consumer tarball. Restores proprietary SDK files *and* Motopia build hooks. |
| **RDP / Runner** | Broadcom hardware packet engine. Treat as a blob unless you are specifically assigned to it. |
| **CFE** | Broadcom bootloader (cferom in image names). |

## Safety (non-negotiable)

- Do not flash an experimental image on a production household gateway. Opening a **spare you own** to *watch* UART boot logs can be educational; opening the in-service ONT or programming flash is not the intern path. See [deploy.md](deploy.md#should-i-open-the-box-for-a-serial-port-education).
- Do not commit keys, ISP credentials, or customer dumps.
- Do not “fix” TLS by disabling verification or turning HTTP-only back on.
- Changes that weaken isolation (guest Wi-Fi, firewall, Docker) need a written threat note in the PR.

## Where to ask for help

Point to a **path + flag + what you observed**, for example:

> `targets/NVG578LX_AX/NVG578LX_AX` has `# BUILD_OMCI_AUTH is not set` while `BUILD_OMCI=y`. Is that expected for Ziply units?

That is more useful than “the firmware looks insecure.”

## Related pages

| Page | Use it for |
| --- | --- |
| [architecture.md](architecture.md) | Tree, build pipeline, profile flags, what to edit |
| [security.md](security.md) | Threat model, surfaces, starter tickets |
| [versions.md](versions.md) | 9.5.0h4 identity, why only one OSS dump, library ages, missing CVE fixes |
| [deploy.md](deploy.md) | Build vs flash; **what firmware upload actually checks** (CRC/chip id, not Motopia signature) |
| [pr-checklist.md](pr-checklist.md) | Before you open a firmware PR |
| [findings/](findings/) | Evidence notes (no secrets) |
| [CONTRIBUTING.md](../../CONTRIBUTING.md) | What we merge |
| [patches/README.md](../../patches/README.md) | How SDK edits survive the next extract |
