# Firmware patches (applied after `bcm.patch`)

This directory is how intern and security changes **persist**. The vendor `./build` script deletes `axis/broadcom/` and recreates it from tarballs plus `bcm963xx/bcm.patch`. Anything you edit only inside that generated tree is gone on the next full extract.

## When to add a file here

- You changed a file that originates from the Broadcom consumer tarball or from `bcm.patch` (typical: `targets/fs.src/etc/init.d/ssl.sh`, GPL apps under `userspace/gpl/`, profile `NVG578LX_AX`).
- The change is small enough to review as a unified diff.

Do **not** dump a second copy of `bcm.patch` here. Do not vendor the 760 MB tree.

## Naming

Use a zero-padded series so apply order is obvious:

```
0001-ssl-sh-restrict-key-perms.patch
0002-profile-disable-docker-for-ziply.patch
```

One logical change per file. Include a short comment at the top of the diff (or in the PR) naming the ticket and the test you ran.

## How to create a patch

From a tree that has already been extracted and patched with `bcm.patch`:

```bash
cd nvg578.9.5.0h4/axis/broadcom
# edit files, then:
diff -u targets/fs.src/etc/init.d/ssl.sh.orig \
        targets/fs.src/etc/init.d/ssl.sh \
  > ../../../patches/0001-ssl-sh-restrict-key-perms.patch
```

Prefer `git diff` inside a throwaway clone of `axis/broadcom` if you have one. Paths in the patch must match the tree after extract (`axis/broadcom/...` or relative to that directory — pick one convention and state it in the PR).

## How to apply

After `bcm.patch` succeeds, before `make`:

```bash
cd nvg578.9.5.0h4/axis/broadcom
patch -p1 < ../../patches/0001-ssl-sh-restrict-key-perms.patch
```

If `scripts/build-nvg578.sh` is in the repo, extend it to apply `patches/*.patch` in sorted order rather than relying on a manual step. Until that exists, document the apply command in the PR.

## Arris overlay vs this folder

Code that already lives under `nvg578.9.5.0h4/axis/arris/` (for example `gpl/inetd/`) is **not** wiped by extract. Those edits still are not in this GitHub repo until we add a tracked overlay. For now, either:

- copy the changed file into a git-tracked path agreed in the PR, or
- keep a patch here that applies to `axis/arris/` after tarball extract.

Empty on purpose until the first real firmware patch lands.
