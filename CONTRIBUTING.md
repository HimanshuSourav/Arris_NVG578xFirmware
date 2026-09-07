# Contributing

This repository is a project to fetch, build, and harden the public CommScope/Arris NVG578LX firmware (Ziply GPON gateway). Most useful work is **security**: shrinking attack surface, fixing in-tree GPL/init/TLS issues, and documenting residual risk where Motopia source is missing.

If you are new, start with **[docs/intern/README.md](docs/intern/README.md)** (architecture, then the security map). This page is the “how we land a change” companion.

## Before you write code

1. Fetch the SourceForge tree. It is **not** in git (GitHub’s 100 MB file limit). Use `./scripts/fetch-source.sh` if that script exists; otherwise download `nvg578.9.5.0h4.tar.gz` from [SourceForge](https://sourceforge.net/projects/nvg578.arris/) and extract it at the repo root as `nvg578.9.5.0h4/`.
2. Read [docs/intern/architecture.md](docs/intern/architecture.md) until the three facts make sense: `./build` wipes `axis/broadcom/`, Motopia apps are often missing, Broadcom CMS httpd is off.
3. Pick a [starter ticket](docs/intern/security.md#starter-tickets) or an equivalent small, in-tree change. Do not start with kernel upgrades, Runner (`rdp/`), or a from-scratch web UI.

## What belongs in git

| Put in git | Do not put in git |
| --- | --- |
| Docs, `scripts/`, `patches/`, this file | `nvg578.9.5.0h4.tar.gz` and `nvg578.9.5.0h4/` |
| Small overlay files if we later add a tracked overlay | Built `.w` images, `cscope.out`, `tags` |
| Notes under `docs/intern/findings/` with **no secrets** | Keys, ISP credentials, customer dumps, GPON passwords |

Edits under `nvg578.9.5.0h4/axis/broadcom/` **do not survive** the next vendor `./build` extract. Persist them as a patch under `patches/` (see [patches/README.md](patches/README.md)) or as a change to a durable path (`axis/arris/`, `scripts/`).

## Change types we want

- **Hardening** of in-tree init, inetd, firewall, guest isolation, OpenSSL *config* (not a silent major upgrade).
- **Profile / build flags** that remove unused surface (Docker, debug tools) with evidence from a built `fs.install`.
- **CVE mapping** that names version + compile flags + whether we are actually affected.
- **Docs** that correct the map (paths, flags, missing source).

## Change types we reject or delay

- Disabling TLS verification, turning HTTP-only back on, or enabling `CMS_BYPASS_LOGIN`.
- Invented Motopia `webui` / `muhttpd` stubs so the tree “looks complete.”
- Exploit PoCs against networks you do not own.
- Committing the 760 MB firmware tree “so clones are easier.”

## How to make a change (firmware)

1. Extract once so `nvg578.9.5.0h4/axis/broadcom/` exists (vendor `./build` or `scripts/build-nvg578.sh`).
2. Edit the smallest durable location (see the table in architecture.md).
3. Rebuild what you can: subdirectory `make` after one full extract, or a full image if you changed init/rootfs.
4. Inspect `targets/NVG578LX_AX/fs.install` (setuid, listeners, whether `dropbear`/`docker` are actually present).
5. Capture a `patches/*.patch` if the edit was inside the generated SDK.
6. Write the PR using [docs/intern/pr-checklist.md](docs/intern/pr-checklist.md).

Host/build-environment fixes belong in `scripts/`, not in a one-off note on your laptop.

## Pull requests

- One concern per PR (one flag family, one init script, one library bump).
- Title should name the **component** (`ssl.sh`, inetd, dnsmasq, profile Docker).
- Body must include: expected vs actual, paths, how you tested, residual risk.
- If Motopia source is missing for the bug you wanted, say so and land the in-tree part (or a findings note) instead of a fake fix.

## Safety

Do not flash experimental images on a household gateway without a recovery plan. Do not commit secrets. Do not weaken isolation “to make a demo work.”
