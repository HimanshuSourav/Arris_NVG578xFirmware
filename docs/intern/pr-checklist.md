# Security PR checklist

Use this before you open a pull request that changes firmware behavior, profile flags, or crypto/init. Docs-only PRs can skip the rebuild rows.

## Intent

- [ ] The PR states the **threat** (LAN, WAN/OMCI, local admin, supply chain) and the **expected** vs **actual** behavior.
- [ ] The change does not disable TLS verification, enable `CMS_BYPASS_LOGIN`, or turn HTTP-only back on.
- [ ] Guest / firewall / Docker changes include a short residual-risk note.

## Where the bits live

- [ ] Durable path is used (`scripts/`, `patches/`, `axis/arris/`, docs) — not a one-off edit that `./build` will wipe.
- [ ] No `nvg578.9.5.0h4/` tree, `.w` images, keys, or ISP credentials in the diff.
- [ ] Motopia-only bugs are labeled **missing source** if `webui` / `muhttpd` / dropbear trees are absent; no stub apps invented.

## Build and inspect

- [ ] Compiled the affected subdirectory, or ran a full `NVG578LX_AX` image build.
- [ ] Inspected `targets/NVG578LX_AX/fs.install` for the actual binary/script (do not assume a Makefile target means the file shipped).
- [ ] For permission/init changes: noted owner/mode of new files and whether they run as root.

## Crypto and secrets

- [ ] Key material is not world-readable at any documented step.
- [ ] HTTPS and SSH keys are not silently reused unless that is still required and called out.
- [ ] GPON / TR-069 / admin passwords are not logged or pasted into the PR.

## Network

- [ ] WAN ping / management from WAN is still off unless the ticket is specifically about that.
- [ ] LAN DHCP and basic forwarding still work if you touched iptables/ebtables.
- [ ] Guest isolation: listed the ports/IPs a guest must **not** reach (at least the LAN admin UI).
- [ ] IPv6 considered if you only changed IPv4 rules.

## Reviewer hints

Paste into the PR body:

```
Threat: …
Paths: …
Flag(s): …
How tested: …
fs.install evidence: …
Residual risk: …
```
