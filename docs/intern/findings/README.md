# Intern findings (no secrets)

Drop write-ups here when a starter ticket produces **evidence**, not guesses.

Examples: image inventory (setuid, listeners, whether `dropbear`/`docker`/`muhttpd` are on `fs.install`), OpenSSL/dnsmasq CVE spreadsheet notes (start from [versions.md](../versions.md)), OMCI-auth residual risk.

- Do not commit keys, ISP credentials, customer packet dumps, or GPON passwords.
- Name files after the ticket (`image-inventory.md`, `ssl-sh-notes.md`).
- Link the path and profile flag you used so someone can reproduce without the firmware tree in git.

Logged:

- [uart-button0-cut.md](uart-button0-cut.md) — spare NVG578LX listen-only UART dies inside `registerBtns` after GPIO 36 (WPS), before RDPA/GPON; not a flash fix.
