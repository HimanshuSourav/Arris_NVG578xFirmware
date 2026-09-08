# Intern findings (no secrets)

Drop write-ups here when a starter ticket produces **evidence**, not guesses.

Examples: image inventory (setuid, listeners, whether `dropbear`/`docker`/`muhttpd` are on `fs.install`), OpenSSL/dnsmasq CVE spreadsheet notes (start from [versions.md](../versions.md)), OMCI-auth residual risk.

- Do not commit keys, ISP credentials, customer packet dumps, or GPON passwords.
- Name files after the ticket (`image-inventory.md`, `ssl-sh-notes.md`).
- Link the path and profile flag you used so someone can reproduce without the firmware tree in git.

Logged:

- [uart-button0-cut.md](uart-button0-cut.md) — earlier listen-only on **official Ziply firmware**: box booted until serial pins were soldered, then died inside Motopia `registerBtns` GPIO 36 (WPS). GPIO unplug did not help. `brcm_board_init`→snow still has no `SES:` / `request_irq failed` / `Registering button 1`.
- [uart-btrm-nand.md](uart-btrm-nand.md) — later listen-only: BTRM `COM1`/`UB` without `PASS`, NAND `TRY2`/`NAN3`, one late CFE; a follow-up live listen still saw CFE/PMC and `Board Id: NVG578HLX`. Do not UART-download, factory-reset, or flash.
