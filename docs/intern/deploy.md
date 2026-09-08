# Build vs deploy on a real NVG578

Short answer: **building a `.w` file in this environment is feasible. Putting that file on a Ziply (or other ISP) gateway and getting a working product is not, with the public tree we have.** Interns should treat hardware flash as a later, high-risk experiment, not the default way to test a patch.

This is a feasibility map, not a flash cookbook. Do not write unsigned images onto a household gateway that you cannot recover.

If you only need “is flashing in this code, and what does upload check?” skip to [Firmware upload and flashing checks](#firmware-upload-and-flashing-checks).

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

## Firmware upload and flashing checks

**Yes, flashing code exists — but it is the Broadcom SDK path, not the Ziply web UI.** The LAN “upload firmware” page and Motopia’s signed-package check are **not in this OSS drop.** What *is* here is CRC / chip-id / size validation, a CLI burner stub, and kernel NOR helpers that **refuse NAND**.

Checked against the extracted tree on **2026-09-08**. This section describes what the code **checks**. It is not instructions for flashing or for bypassing checks.

### Two different upload paths

| Path | In this tree? | What it is |
| --- | --- | --- |
| Motopia LAN UI (`muhttpd` + webui “firmware update”) | **No** (source missing) | What an end user would use. Profile turns it on (`CONFIG_MOTOPIA_WEBUI=y`, `CONFIG_MOTOPIA_MUHTTPD=y`, `CONFIG_MOTOPIA_FIRMWARE_USER_UPDATE=y`) and wants a **signed** image (`CONFIG_MOTOPIA_SIGNED_IMAGE=y`). **No `.c` implements those flags.** |
| Motopia `sysmgr` firmware manager | **No** | `image.c` says Motopia keeps Broadcom image helpers for `public/apps/sysmgr/fwmgr.c`. That file is **not present**. BusyBox init still mentions `/sbin/fwmgr`. |
| Broadcom CMS httpd upload | **Off** | `# BUILD_HTTPD is not set` / `BUILD_HTTPD_none=y`. Do not hunt Broadcom’s web server for the product UI. |
| Broadcom `cmsImg_validateImage` / `cmsImg_writeImage` | **Yes** | Userspace format detect + CRC/chip-id. Used if Motopia (or another app) calls it. |
| CLI `bcm_flasher <file>` | **Yes** (thin) | Streams a file to NAND via `imgif_*`. Parser is a stub. The real NAND library is **missing**. |
| Kernel `BOARD_IOCTL_FLASH_WRITE` | **Yes** | CFE / filesystem / whole-image ioctls. On this SoC, **NAND whole-image write is disabled** in the kernel. |

Product NAND layout is **pureUBI / squash-UBI** (`BRCM_FLASH_NAND_LAYOUT_PUREUBI`, `BRCM_FLASH_NAND_ROOTFS_SQUBI`). Whole `.w` writes are supposed to go through **userspace** (`writeImageToNand` in `bcm_flashutil`), not through the kernel NOR writer.

### What `cmsImg_validateImage` checks

File (after extract):

`nvg578.9.5.0h4/axis/broadcom/userspace/public/libs/cms_util/image.c`

Call chain: `cmsImg_writeImage` → **validate** → `cmsImg_writeValidatedImage` → `flashImage`.

The validator classifies the buffer. Anything that does not match is `CMS_IMAGE_FORMAT_INVALID` (rejected).

1. **Null pointer** — invalid.
2. **Looks like a CMS XML config** (first 64 bytes start with `<?xml version` and contain `<DslCpeConfig`) — only fully validated if `BRCM_CMS_BUILD` is on. This product profile does **not** use Broadcom CMS as the config store, so this branch is not the Ziply path.
3. **Broadcom tagged image** — first 256 bytes are a `FILE_TAG` (`bcmTag.h`) and `verifyBroadcomFileTag(..., fullImageB=1)` succeeds. Then the file must fit **flash size + tag size**. Format = `CMS_IMAGE_FORMAT_BROADCOM`.
4. **Else: whole-flash `.w`** — last 20 bytes (`TOKEN_LEN`) hold a CRC. CRC32 of everything before that must match, and the file must fit flash size. Format = `CMS_IMAGE_FORMAT_FLASH`.

That last case is the usual Broadcom `.w` wrapper (the files under `targets/NVG578LX_AX/`).

### What `verifyBroadcomFileTag` checks (tagged images)

Same file, plus the tag layout in `shared/opensource/include/bcm963xx/bcmTag.h`.

| Check | Passes if |
| --- | --- |
| Header CRC | CRC32 of the first `TAG_LEN - TOKEN_LEN` (256 − 20) bytes equals `tagValidationToken` |
| Tag version | ASCII version equals `BCM_TAG_VER` (**`"7"`**) |
| Chip ID | Hex ASCII `chipId` matches the running SoC (`devCtl_getChipId`) **or** the compile-time `BRCM_CHIP_HEX` |
| Declared payload length | `totalImageLen` is not larger than `imageLen - TAG_LEN` |
| Payload CRC | CRC32 of the bytes after the tag equals `imageValidationToken` |

The tag also has `boardId`, `signiture_1` / `signiture_2` (company/version **text**), and `imageVersion`. **`verifyBroadcomFileTag` does not compare `boardId`.** The “signature” fields are not a cryptographic signature; the comments say the tokens are CRC (with room for MD5/SHA later). **This is not Motopia signed-image verification.**

### What happens after a valid image (write)

`flashImage` in the same `image.c`:

- **`CMS_IMAGE_FORMAT_FLASH` (whole `.w`)**: if NOR, kernel ioctl `BOARD_IOCTL_FLASH_WRITE` / `BCM_IMAGE_WHOLE` (length minus the trailing 20-byte token). If NAND, `writeImageToNand(...)`. That function lives in **`bcm_flashutil`**, which is **not in this drop** (`userspace/public/libs/` has `cms_util`, not `bcm_flashutil`). EMMC is explicitly “not implemented.”
- **`CMS_IMAGE_FORMAT_BROADCOM`**: parse CFE / rootfs / kernel addresses and lengths from the tag and ioctl those pieces separately.

Motopia `#ifdef MOTOPIA` in `cmsImg_writeValidatedImageEx`: after a successful write, **never reboot**; `CMS_IMAGE_WR_OPT_NO_REBOOT` is reused to pick OLD vs NEW boot image (`setBootImageState`). There is a NAND helper `flashMotopiaNVG5x9Image` **only** for `NVG589` / `NVG599` — **not compiled for NVG578**.

### CLI `bcm_flasher`

`userspace/public/apps/bcm_flasher/bcm_flasher.c`: `bcm_flasher <filename>`.

- Opens the file, prints size and NAND geometry from `imgif_get_flash_info`.
- `parseImgHdr` **always returns `CMS_IMAGE_FORMAT_FLASH`** (it ignores the buffer). It does **not** run `verifyBroadcomFileTag`.
- Writes through `imgif_open` / `imgif_write` / `imgif_close`.

Only the **header** `bcm_imgif.h` is present. The `imgif` implementation (where extra NAND / WFI checks would live) is **missing**, same as `bcm_flashutil`.

### Kernel checks (mostly NOR; NAND write is userspace)

SoC copy: `bcmdrivers/opensource/char/board/bcm963xx/bcm96858/board_ioctl.c` and `board_image.c`.

`BOARD_IOCTL_FLASH_WRITE`:

- **`BCM_IMAGE_CFE`**: reject if NAND (`NAND_RFS_OFS` is set). Size must be `> 0` and `≤ FLASH_LENGTH_BOOT_ROM`.
- **`BCM_IMAGE_FS`**: also **rejects NAND**. On NOR, `flashFsKernelImage` uses FILE_TAG addresses/lengths and available flash (including dual-partition if both copies fit).
- **`BCM_IMAGE_WHOLE`**: size must be `> 0`, then `commonImageWrite`.

`commonImageWrite` on NAND prints **`no longer support NAND flash in kernel`** and returns **-1**. NVG578 is NAND, so this kernel path is **not** how a product `.w` is programmed.

On **NOR** whole-image (`kerSysBcmImageSet`), the trailing **`WFI_TAG`** (also 20 bytes: CRC, version, chip id, flash type, flags) is copied from the end of the buffer. The kernel then:

- Requires `wfiVersion` in the `WFI_ANY_VERS` family and **`wfiChipId`** matching the SoC (or family id).
- Requires **`wfiFlashType == WFI_NOR_FLASH`** (NAND types 128/256/… are defined in `bcmTag.h` but this function will not accept them).
- On BCM63268 only: **`WFI_FLAG_SUPPORTS_BTRM`** must match OTP secure-boot. **This `#if` does not apply to BCM96858** (this gateway).
- On 6858 (this chip): if `WFI_FLAG_HAS_PMC` is unset, skip/preserve a 64 KB PMC region at the start of flash.

Userspace `cmsImg_validateImage` for a whole `.w` **only checks the trailing CRC and size**. Chip id / NAND erase-block type in the WFI tag would be enforced later in the **missing** NAND writer, or (for NOR) in the kernel.

### Motopia “signed image” — flag only

`targets/NVG578LX_AX/NVG578LX_AX`:

- `CONFIG_MOTOPIA_SIGNED_IMAGE=y`
- `CONFIG_MOTOPIA_FIRMWARE_USER_UPDATE=y` (listed twice)

A search of Motopia/Arris C in this drop finds **no implementation** of those flags. Whatever cryptographic check the Ziply UI runs is in **closed Motopia**, not in `cmsImg_validateImage`.

Bootrom/OTP is a separate layer (`SECURE_BOOT_ARCH=GEN3`, `BTRM_BOOT_ONLY=y`). Demo keys under `targets/keys/demo/GEN3/` are not factory OTP keys. See [Signing and boot](#signing-and-boot-why-the-ui-will-likely-refuse-you) above.

### Intern takeaway

| Question | Answer in this OSS tree |
| --- | --- |
| Is flashing implemented? | **Partial.** Validate + NOR ioctl + CLI stub: yes. NAND write library, Motopia UI, `fwmgr`, signed-image check: **no**. |
| What does “upload firmware” check? | Broadcom path: **CRC, tag version 7, SoC chip id, file vs flash size.** Not board id, not Motopia signature. |
| Can I test the Ziply upload page from this repo? | **No** — `muhttpd` / webui source is missing. |

Do not add patches that skip CRC or chip-id checks. Do not document how to craft a matching tag. If you dump an ISP rootfs you are allowed to inspect, a useful finding is whether `/sbin/fwmgr` and a Motopia signer binary are actually on the box — write that under [findings/](findings/), no keys.

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
- [security.md](security.md) — firmware-upload surface vs missing Motopia signer
- [versions.md](versions.md) — 9.5.0h4 vs ISP builds; why SourceForge is not an update feed
