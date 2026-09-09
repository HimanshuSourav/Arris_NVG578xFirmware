# Release version and missing CVE fixes

Snapshot of **what this OSS drop actually is**, whether it is “too old to use,” and which upstream security fixes are **not** in the tree. Paths are relative to `nvg578.9.5.0h4/` after extract.

Checked against the tree on **2026-09-07**. Re-verify versions in `opensslv.h`, app `Makefile`s, and a built `fs.install` before claiming anything public.

## Product version

| Identifier | Value |
| --- | --- |
| CommScope/Arris firmware | **9.5.0h4** |
| Public tarball | `nvg578.9.5.0h4.tar.gz` |
| SourceForge published | **2022-08-10** ([files listing](https://sourceforge.net/projects/nvg578.arris/files/)) |
| Broadcom SDK | **5.02L.07p2** (`axis/broadcom/version.make`: `BRCM_VERSION=5`, `BRCM_RELEASE=02`, `BRCM_EXTRAVERSION=07p2`) |
| Profile / SKU | `NVG578LX_AX` (`PROFILE_KERNEL_VER=LINUX_4_1_0`) |
| Newer OSS drop on that project | **None** as of the date above |

Public mirrors of a **complete flashable Ziply image**, Motopia `webui`/`muhttpd` source, or a second OSS tarball were not found (search of SourceForge, GitHub, Vantiva OSS pages, OpenWrt, Archive.org, 2026-09-07). See [deploy.md](deploy.md#what-is-actually-on-the-public-internet).

This GitHub repo does not contain a newer vendor tree. If SourceForge later adds `nvg578.9.5.0h5` (or similar), this page is stale until someone updates it.

### Why only one public drop?

**They did not use SourceForge as an update feed.** The [project home](https://sourceforge.net/arris/nvg578/home/Home/) says CommScope is providing “the open source software used in” the gateway, and that the site is **not** an SDK or general developer support. That is a **GPL/open-source compliance dump**, not “Arris Linux” in the OpenWrt sense.

Three different pipelines, often confused:

| Channel | Who it is for | What actually happens |
| --- | --- | --- |
| **ISP firmware** | Ziply / YouFibre subscribers | Images go box ← ACS / OMCI / TR-069. Version strings can move (`9.5.0h4d134_…`) with **no** new SourceForge tarball. |
| **GPL corresponding source** | Anyone who received GPL binaries | Vendors must offer the source that built **those** GPL pieces (BusyBox, dnsmasq, kernel, …). Motopia UI, Wi-Fi blobs, Runner, and most management daemons are **proprietary** and are not required on SourceForge. |
| **Community development** | Hobbyists / this GitHub repo | Explicitly **not** offered. Missing `webui` / Dropbear trees in the tarball is consistent with an incomplete dump, not with a living git project. |

So a single `nvg578.9.5.0h4.tar.gz` on **2022-08-10** does **not** mean “no firmware shipped after that.” It means **no second public OSS archive** was posted there.

Why later archives often never appear (what we can show vs what we infer):

1. **Launch dump, then silence.** Older Arris gateways *sometimes* got multiple OSS folders when the **GPL** bits changed (example: [NVG510 news](https://sourceforge.net/arris/nvg510/news/) and [NVG589/599 files](https://sourceforge.net/projects/nvg599.arris/files/) with several `9.x` / `11.x` tarballs). NVG578’s SourceForge project was **registered the same day** as this one file and never gained a second. That is a process choice, not proof that 9.5.0h4 was the last binary Ziply ever pushed.
2. **Later ISP builds may only have changed closed code.** If `h4d134` is Motopia/ISP branding, certificates, or ACS settings, the vendor can tell themselves the **GPL corresponding source is still 9.5.0h4**. Whether that is legally enough if they also patched BusyBox/OpenSSL is a compliance question, not something this tarball answers. GPL enforcement texts say **each distributed binary version** should have matching source; many CPE vendors lag or skip that in practice.
3. **The customer is the ISP, not GitHub.** Security and feature updates are sold as managed CPE. Publishing a rebuildable tree that matches the shipped image competes with that model (and with Broadcom NDA pieces). The home page already disclaims developer support.
4. **The product line changed owners.** Home Networks moved **Arris → CommScope → Vantiva** (Vantiva closed the CommScope Home Networks deal **9 Jan 2024**). The SourceForge “Arris” account still hosts the 2022 files; a 2025 forum note treats it as effectively archived and points at [Vantiva regulatory information](https://www.vantiva.com/regulatory-information/). New dumps, if any, might land there (or only on written request), not as `nvg578.9.5.0h5` on the old project.
5. **We do not have a vendor quote that says “we will never post again.”** Treat “one tarball” as **observed**. A written offer of source (GPL’s other option) can also exist without a public files tab. If you need corresponding source for a **specific** ISP image, ask Ziply/Vantiva for that version — do not assume this 2022 tree is it.

Intern takeaway: work on **this** drop because it is what we can build and patch. Do not wait for a vendor “9.5.1 security refresh” on SourceForge. Do not assume Ziply boxes are bit-identical to a `./build` of this tarball.

### OSS drop vs what Ziply may be running

ISP units have been reported with a **later build of the same 9.5.0h4 line** (example seen in the wild: `9.5.0h4d134_YouFibre`). Those extra letters are ISP packaging. They are **not** a second public source tree.

So:

- This tarball is the **open-source snapshot of 9.5.0h4**.
- The box in a home might be 9.5.0h4 **plus** closed Motopia bits and ISP patches we cannot see.
- Do not assume Ziply backported OpenSSL/dnsmasq/kernel CVEs. Do not assume they did not. Confirm on a device or a dumped rootfs if you have one you are allowed to inspect.

## Is it outdated for basic operation?

**No — not in the “this hardware cannot be a GPON Wi-Fi 6 gateway” sense.** 9.5.0h4 is still the software family this SKU was built for: Linux 4.1 on the Broadcom PON SoC, GPON, 802.11ax, NAT, DHCP, Motopia UI/OMCI.

What **is** outdated is **maintenance of bundled GPL/crypto/kernel**, not the product generation.

What you cannot assume:

- This OSS tarball is a complete, flash-ready Ziply image (Motopia apps are often missing).
- A successful `./build` produces the same binary the ISP ships.
- “Old libraries” means every listed CVE is remotely exploitable on this box (see [Reachability](#reachability-not-every-cve-is-on-the-box)).

## Component inventory (in this drop)

Confirm these files after extract. Dropbear’s **directory is often absent** even though the make target names 2016.74.

| Component | In-tree version | Where the version is | Upstream status (high level) |
| --- | --- | --- | --- |
| Linux | **4.1.52** | `kernel/linux-4.1/Makefile`; `make.common` `LINUX_VER_STR_LINUX_4_1_0` | Last 4.1 stable was **May 2018**; 4.1 is EOL. This is a Broadcom fork, not a mainline bump. |
| OpenSSL | **1.1.1b** (26 Feb 2019) | `userspace/public/libs/libssl/include/openssl/opensslv.h` (`OPENSSL_VERSION_NUMBER 0x1010102fL`) | 1.1.1 LTS ended **11 Sep 2023**. Last **public** 1.1.1 was **1.1.1w**. This tree never moved past **b**. |
| dnsmasq | **2.79** | `userspace/gpl/apps/dnsmasq-2.79/` | DNSpoq set fixed in **2.83**; later DNSSEC/DoS work through **2.90+** also absent. |
| BusyBox | **1.30.1** | `userspace/gpl/apps/busybox/Makefile` (`APP = busybox-1.30.1`) | Later applet bugs (gzip/lzma/ash, …). Current line is 1.37+. |
| PCRE | **8.32** (30 Nov 2012) | `userspace/gpl/libs/pcre-8.32/` | PCRE1 ended at 8.45; PCRE2 is current. |
| zlib | **1.2.7** (2 May 2012) | `userspace/gpl/libs/zlib-1.2.7/` | Missing CVE-2018-25032, CVE-2022-37434, … (upstream fixed in 1.2.12+). |
| Dropbear | **2016.74** (make target) | `userspace/gpl/apps/dropbear-2016.74` — **often missing from the tarball** | If the **image** ships it, it is years behind. CVE-2017-9078 already affects through 2016.74. Confirm on `fs.install`. |
| Lua | **5.3.4** (12 Jan 2017) | `userspace/gpl/apps/lua-5.3.4/` | 5.3 line is old; later 5.3/5.4 fixes not here. |
| haserl | **0.9.35** | `userspace/gpl/apps/haserl-0.9.35/` | CGI helper for Motopia UI path. |
| iptables | **1.6.2** + Arris patch file named `iptables-1.4.16.3-arris.patch` | `userspace/gpl/apps/iptables/` | Version in `Makefile` is 1.6.2; do not trust the patch filename alone. |
| ipset | **6.38** | `userspace/gpl/apps/ipset/ipset-6.38/` | |
| ebtables | **v2.0.10-4** | `userspace/gpl/apps/ebtables/` | |
| Docker (headers) | **18.03.1-ce** mentioned | CMS/Motopia headers; profile `CONFIG_MOTOPIA_DOCKER=y` | Prove whether `dockerd` is on the image before treating this as live. |

Kernel and Wi-Fi blobs (`bcmdrivers/broadcom/net/wl/`, `rdp/`) are **not** intern starter upgrades.

## Missing OpenSSL fixes (1.1.1b → 1.1.1w)

This product builds stock **1.1.1b**. Public 1.1.1 security releases after **b** are not in the tree. Examples (not a complete NVD dump):

| CVE | Fixed in public 1.1.1 | Sketch |
| --- | --- | --- |
| CVE-2019-1543 | 1.1.1c | ChaCha20-Poly1305 over-long nonces |
| CVE-2020-1971 | 1.1.1i | `GENERAL_NAME_cmp` NULL deref (EDIPartyName / CRLs) |
| CVE-2021-3711 | 1.1.1l | SM2 decryption buffer overflow |
| CVE-2021-3712 | 1.1.1l | ASN.1 string read overruns |
| CVE-2022-0778 | 1.1.1n | `BN_mod_sqrt` infinite loop (DoS) |
| CVE-2022-4304 | 1.1.1t | RSA decryption timing |
| CVE-2022-4450 | 1.1.1t | `PEM_read_bio_ex` double free |
| CVE-2023-0215 | 1.1.1t | Use-after-free after `BIO_new_NDEF` |
| CVE-2023-0286 | 1.1.1t | X.400 / `GENERAL_NAME` type confusion |

There are more between 1.1.1c and **1.1.1w** (Sep 2023). After that date there are **no public 1.1.1 patches**. Motopia still uses 1.1.1 APIs; jumping to OpenSSL 3.x is a port, not a drop-in.

Starter ticket: complete the mapping in [findings/](findings/) — CVE id, whether Motopia compile flags mean we do not ship the code, leftover risk (TLS 1.0, RSA-only, self-signed `ssl.sh`).

## Other high-signal missing fixes

**dnsmasq 2.79** predates:

- CVE-2020-25681 through CVE-2020-25687 (DNSpoq: DNSSEC memory corruption **and** cache-poisoning issues; overflows mainly if DNSSEC is enabled; poisoning issues are broader). Fixed starting in **2.83**.
- CVE-2021-3448 (fixed in 2.85).
- Later DNSSEC resource-exhaustion work (e.g. CVE-2023-50387 / CVE-2023-50868 in **2.90**), which matters if DNSSEC validation is on.

**zlib 1.2.7** predates CVE-2018-25032 (deflate memory corruption, fixed 1.2.12) and CVE-2022-37434 (`inflateGetHeader` extra-field overflow, fixed after 1.2.12). Only apps that hit those code paths are affected.

**BusyBox 1.30.1** has later applet CVEs (examples: gzip/lzma handling, `ash` stack issues, `netstat` terminal escape). Impact depends on **which applets this profile actually enables**.

**Dropbear 2016.74** (if present on the image): CVE-2017-9078 is a double-free on TCP forwarding for authenticated users through 2016.74. Many later SSH/crypto fixes also missing. The make target exists; the **source directory often does not** in this tarball.

**Linux 4.1.52**: eight years of mainline CVEs are not in 4.1. Broadcom may have backported some; we cannot see a changelog that proves it. Do not file “kernel is pwned” without a specific syscall/driver and a check that the code is in this fork.

## Reachability: not every CVE is on the box

Inventory ≠ exploit.

- OpenSSL is built with `OPENSSL_SMALL_FOOTPRINT` and **DSA / ECDSA / ECDH / engine / DSO off** (`userspace/public/libs/libssl/makefile` and `axis/lib/libssl/makefile`). SM2 (CVE-2021-3711) and some EC-only TLS issues may **not compile in**. RSA and the algorithms that remain **do**.
- dnsmasq DNSSEC heap bugs require DNSSEC; cache-poisoning CVEs may still apply if the daemon is the LAN resolver.
- BusyBox CVEs need the applet to be enabled in this BusyBox config.
- Dropbear CVEs need the binary on `fs.install` (or the ISP image).
- Motopia closed source is not in this drop; ISP images may differ.

When you write a finding, use: component, **exact version file**, compile flag, **whether the binary is on the image**, expected vs actual. Do not paste exploit PoCs against networks you do not own.

## What to do with this (intern)

1. Read [security.md](security.md) for *where* these components sit in the product.
2. Pick **one** component (OpenSSL mapping is the default). Fill a table under [findings/](findings/) (`openssl-cve-map.md`, `dnsmasq-cve-map.md`, …).
3. Do **not** silently replace OpenSSL 1.1.1b with 3.x or Linux 4.1 with 6.x as a first PR. Smallest durable change: document residual risk, or a **minimal** bump that still builds with Motopia `CFLAGS` (see PCRE `#define const` trap in security.md).
4. Persist SDK edits in [patches/](../../patches/README.md).

## How we verified the versions

```text
axis/broadcom/version.make                          → 5.02L.07p2
userspace/public/libs/libssl/include/openssl/opensslv.h
  OPENSSL_VERSION_TEXT "OpenSSL 1.1.1b  26 Feb 2019"
userspace/gpl/apps/dnsmasq-2.79/
userspace/gpl/apps/busybox/Makefile                 → busybox-1.30.1
userspace/gpl/libs/pcre-8.32/
userspace/gpl/libs/zlib-1.2.7/
kernel/linux-4.1/Makefile                           → 4.1.52
userspace/gpl/apps/dropbear-2016.74                 → absent in this extract
```

If your extract differs, **trust the files**, then send a docs PR.
