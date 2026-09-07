# Build vs deploy on a real NVG578

Short answer: **building a `.w` file in this environment is feasible. Putting that file on a Ziply (or other ISP) gateway and getting a working product is not, with the public tree we have.** Interns should treat hardware flash as a later, high-risk experiment, not the default way to test a patch.

This is a feasibility map, not a flash cookbook. Do not write unsigned images onto a household gateway that you cannot recover.

## Two different jobs

| Job | Feasible? | What we actually know |
| --- | --- | --- |
| **Compile** host tools + kernel + image wrapper | **Yes**, with the Ubuntu 24.04 extras in `scripts/` (or vendor Ubuntu 20.04 notes). A full `NVG578LX_AX` run here produced `bcmNVG578LX_AX_nand_*_puresqubi.w` (~45 MB) under `targets/NVG578LX_AX/`. | Hours, fragile Perl/GCC/i386 host. See intern README. |
| **Produce a complete product rootfs** (BusyBox, Motopia UI, Wi-Fi, OMCI, dropbear, …) | **No, not from this OSS drop.** After that “successful” image build, `fs.install` had **17 files** (openssl, lua, libc, libssl, pcre, zlib, json-c, a PMD blob). **No BusyBox binary, no `muhttpd`, no `dropbear`, no sysmgr.** Profile still has `BUILD_BUSYBOX=dynamic` and `CONFIG_MOTOPIA_WEBUI=y` — Makefile targets ≠ installed apps. | Matches missing Motopia / Dropbear **source**. |
| **Flash via the LAN web UI** as an end user | **Unlikely for a self-build.** Profile has `CONFIG_MOTOPIA_FIRMWARE_USER_UPDATE=y` **and** `CONFIG_MOTOPIA_SIGNED_IMAGE=y`. The UI (when present on an ISP image) is meant to take a **vendor/ISP-signed** package, not a random Broadcom `.w`. CommScope/SURFboard community answer: the **provider** flashes firmware. | We do not have Motopia’s signer or production keys. |
| **Flash via CFE / UART** on a recycled box | **Unknown, high brick risk.** Broadcom CFE on a serial console is the usual last-resort path on this SoC family. There is **no public write-up of a successful self-flash** of this OSS `.w` onto NVG578LX/HLX. NAND is **pureUBI / squash-UBI**; images exist for **128 KB and 256 KB** erase blocks — the wrong one will not boot. `*_cferom_*` images include the bootloader; a bad write there is a brick without a programmer. | Do not try this on a gateway that is still someone’s internet. |
| **Keep working as Ziply GPON ONT** after a custom image | **Very low.** Even a perfect boot still has to authenticate to the OLT (GPON password / serial). ISP ACS/OMCI can push the **stock** image back, or the fiber session simply never comes up. | LAN-only “router mode” on Ethernet is a different, still-unproven goal. |
| **OpenWrt / generic Linux** | **Not available** for this SKU. Same SourceForge thread asked; vendor support said the ISP flashes the box. No port exists in this repo. | |

Checked against a local extract/build on **2026-09-07**. Re-check `fs.install` after your own build before you believe you have a flashable product.

## What is actually on the public internet

Searched **2026-09-07**: SourceForge Arris projects, GitHub code/repos, Vantiva regulatory/OSS, OpenWrt device lists, Archive.org, Ziply help pages, and strings like `bcmNVG578LX_AX_nand`, `9.5.0h4d134`, `nvg578.9.5.0h4.tar.gz`.

| Artifact | Publicly downloadable? | Where |
| --- | --- | --- |
| GPL/OSS tarball `nvg578.9.5.0h4.tar.gz` (~797 MB) | **Yes — this is the only drop** | [SourceForge files](https://sourceforge.net/projects/nvg578.arris/files/) (2022-08-10). Same project’s README. No second version folder. |
| This GitHub repo | README + (in PRs) intern docs / build scripts | [HimanshuSourav/Arris_NVG578xFirmware](https://github.com/HimanshuSourav/Arris_NVG578xFirmware). GitHub search found **no other** NVG578 firmware repos and **no** `bcmNVG578LX_AX_nand` binaries in public code. The 760 MB tree is **not** on GitHub (100 MB file limit). |
| Flashable ISP image (`.w` / signed Motopia package / `9.5.0h4d134_YouFibre`) | **Not found** | Ziply says [they manage firmware](https://ziplyfiber.com/helpcenter/categories/internet/troubleshooting/router-specifications); they do not publish a download. SURFboard support: the **ISP flashes** these boxes. |
| Motopia `webui` / `muhttpd` / Dropbear **source** | **Not found** | Not in the SourceForge tarball; not in another public git tree we could name. |
| OpenWrt (or similar) for NVG578LX/HLX | **No** | Not a supported device. Related Arris NVG threads (e.g. NVG468MQ) hit the same Broadcom/Wi-Fi blob wall. |
| Later corresponding source from the current vendor | **Request only, not a public files tab** | [Vantiva regulatory / OSS](https://www.vantiva.com/regulatory-information/) lists **NVG578LX1** in the product dropdown and says source is free **on request**: `contact-ch.opensource@vantiva.com`. That is GPL corresponding source, not a promise of Motopia or a signed flash image. |

Do not treat random firmware dumps on forums as official or safe. If you need source for the **binary on a specific box**, ask Vantiva (and/or Ziply) for that **version string** — this 2022 tarball is not guaranteed to match.

## Why a `.w` file is not “the Ziply firmware”

Vendor README says a successful build lands:

`bcmNVG578LX_AX_nand_cferom_fs_image_128_puresqubi.w`  
or `bcmNVG578LX_AX_nand_fs_image_128_puresqubi.w`

That is a **Broadcom image wrapper** (this tree’s `.w` is a UBI image). It is **not** proven bit-identical to `9.5.0h4d134_YouFibre` or any Ziply build.

In this workspace the dated `squbi_rootfs*pureubi.img` files were still **2022-06-30** (from the OSS drop) while the `.w` wrappers were rebuilt **2026-09-07**. Staged `fs.install` never became a full rootfs. So “the build succeeded” here means **the image packer ran**, not “we reproduced the shipped userspace.”

Hardware names also diverge: **NVG578LX / LX1 / HLX** vs this profile **`NVG578LX_AX`**. Wrong SKU or wrong NAND geometry is a classic brick.

## Signing and boot (why the UI will likely refuse you)

From `targets/NVG578LX_AX/NVG578LX_AX`:

- `SECURE_BOOT_ARCH=GEN3`, `BTRM_BOOT_ONLY=y`
- `# BUILD_SECURE_BOOT is not set` in **this OSS profile**
- `CONFIG_MOTOPIA_SIGNED_IMAGE=y`

Production units can have **OTP / bootrom** policy that this consumer profile does not emulate. The tree ships **demo** GEN3 keys under `targets/keys/demo/GEN3/` — those are not the factory keys fused into Ziply hardware.

Treat unsigned or demo-signed images as **rejected by a real box** until someone with serial logs proves otherwise. Do not try to “fix” that by disabling verification in docs or PRs.

## If you still want a hardware experiment (later)

Preconditions, not steps:

1. Box is **yours**, not in service, and you accept landfill risk.
2. You can open it or already have **UART** to CFE, plus a **known-good dump** of the current NAND (dual image / recovery bank if present).
3. You know **erase-block size** (128 vs 256) and SKU.
4. You inspected **your** `fs.install` and the packed squash/UBI: BusyBox present, init present, Wi-Fi firmware blobs present. If those are missing, **do not flash**.
5. Prefer `nand_fs_image` over `nand_cferom_fs_image` until you have recovery — cferom overwrites the bootloader.
6. After any boot: ISP fiber may stay down; that can be expected.

Until those are true, test patches by **compiling** and **reading `fs.install`**, not by deploying.

## What *is* realistic for an intern

High value, no iron:

- CVE mapping and init/firewall patches persisted in `patches/` ([versions.md](versions.md), [security.md](security.md)).
- Prove whether `dropbear` / `docker` / `muhttpd` exist on a **dumped ISP rootfs** you are allowed to inspect (starter ticket 1), not on this incomplete OSS `fs.install`.
- Host-side build reliability (`scripts/`).

Low value until source exists:

- “Flash my hardening image to the living-room ONT.”
- Replacing Motopia with a from-scratch web UI so the OSS image is a daily driver.

## Related

- [README.md](README.md) — fetch and build
- [architecture.md](architecture.md) — what `./build` wipes; profile flags
- [versions.md](versions.md) — 9.5.0h4 vs ISP builds; why SourceForge is not an update feed
