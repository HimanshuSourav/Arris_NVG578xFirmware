# Intern findings (no secrets)

Drop write-ups here when a starter ticket produces **evidence**, not guesses.

Examples: image inventory (setuid, listeners, whether `dropbear`/`docker`/`muhttpd` are on `fs.install`), OpenSSL/dnsmasq CVE spreadsheet notes (start from [versions.md](../versions.md)), OMCI-auth residual risk.

- Do not commit keys, ISP credentials, customer packet dumps, or GPON passwords.
- Name files after the ticket (`image-inventory.md`, `ssl-sh-notes.md`).
- Link the path and profile flag you used so someone can reproduce without the firmware tree in git.

Logged:

- [uart-button0-cut.md](uart-button0-cut.md) — **closed.** Official Ziply firmware booted until **serial pins were soldered**; that joint put the spare into the Motopia GPIO-36 SW-reset loop (then sicker BTRM/NAND). Not a code/flash fix.
- [uart-btrm-nand.md](uart-btrm-nand.md) — later listen-only on the same soldered spare: BTRM `COM1`/`UB` without `PASS`, NAND `TRY2`/`NAN3`, one late CFE; a follow-up live listen still saw CFE/PMC and `Board Id: NVG578HLX`. Do not UART-download, factory-reset, or flash.
