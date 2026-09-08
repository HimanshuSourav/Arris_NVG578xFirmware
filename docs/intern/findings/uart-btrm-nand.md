# UART moved earlier: BTRM / NAND / CFE, no Linux

Listen-only, **official Ziply firmware**, same spare that used to reach Linux (and that first died in Motopia `registerBtns` GPIO 36 after serial pins were soldered). Not a flash cookbook. Do **not** type at CFE. Do **not** send a UART/BTRM download (repeating `COM1` is not an invitation to feed an image). Do not factory-reset. Do not flash.

UART homework (chat history): [cursor.com/agents/bc-a9d7cc40-d472-452e-85f9-af84ef825f7a](https://cursor.com/agents/bc-a9d7cc40-d472-452e-85f9-af84ef825f7a).

## Capture

- 15 s, 115200 8N1, DTR/RTS off, no TX, port closed that way. PL2303 `/dev/ttyUSB0`.
- **93.7% `0xff` snow.** No Linux, no `Registering button 0`, no SWREG dump, no `SES:`, no `request_irq failed`, no `Registering button 1`.

| t | What |
| --- | --- |
| 0–2 s | BTRM repeating **`COM1` / `UB`** (~63 times). **No `PASS`.** |
| ~2.8 s | `UBI#` / `TRY2` / `NAN3` (NAND probe / retry) |
| 3–11 s | snow |
| ~12 s | **One** CFE banner, then snow again |

```
Base: 5.2_07p2
CFE version 1.0.38-164.255 for BCM96856
Boot Strap Register:  0x53008074
Total Memory: 512MB
NAND flash device: Micron ... id 0x00002cda
CPU1
```

This is **not** the earlier ~8 s Motopia button-0 Linux reboot. In **this 15 s window** the cut is **before** Linux.

A few minutes later, still listen-only (DTR/RTS off, no TX), a live console on the same port saw **CFE continue**: SWREG dump, `Take PMC out of reset` / `waiting for PMC finish booting`, snow, then `PMC rev … running` / `pmc_init:PMC using DQM mode`, and CFE NVRAM including **`Board Id: NVG578HLX`**. So the 15 s pass is a **bad BTRM/NAND attempt**, not proof that CFE/PMC never run again. Port was then closed; DTR/RTS left off. No `Booting Linux` in that short live view before the session was stopped.

## How this compares to the previous loop

| | Before (button-0 loop) | This 15 s capture |
| --- | --- | --- |
| BTRM | `HELO` / **`PASS`** (bootrom accepted CFEROM) | `COM1`/`UB` × many, **no `PASS`** |
| CFE / PMC | Full banner + SWREG + `PMC rev: … running` | Banner once at ~12 s; **no** SWREG / PMC **in this window** (a later live listen did see SWREG/PMC + `NVG578HLX`) |
| Linux | 4.1.52 to `registerBtns` GPIO 36 | **None** in this window |
| NAND | UBI mounted, rootfs looked normal | `UBI#` + `TRY2`/`NAN3` while still in BTRM/CFE |

Same CFE version and SoC as before (`1.0.38-164.255`, `BCM96856`, 512 MB, Micron `0x2cda`). The chip still enumerates NAND and can start CFE. This pass did not launch the kernel.

`UBI#` is the UBI erase-counter magic (`bcm_ubi.h` / `ubi-media.h`, ASCII `UBI#`). Seeing it plus `TRY2`/`NAN3` means the bootrom/CFE NAND path is **retrying or reading error pages**, not that Linux UBI mounted. BTRM strings are **not** in this OSS drop (fused bootrom).

## What it means

The solder/UART work did not “get past GPIO 36.” The board is **sicker**: bootrom often skips the clean `PASS` path, NAND reads look noisy (`TRY2`/`NAN3`), and a 15 s listen can miss Linux entirely. CFE/PMC can still appear on a later listen (`NVG578HLX`). That fits a worse electrical problem (bridge, 5 V into a pad, heat, NAND/power neighbor) — not a Ziply config issue and not something this OSS `.w` will repair.

Repeating `COM1` is bootrom UART chatter (often a download/wait or NAND-fail fallback). Sending bytes there can overwrite bootrom-stage images. Leave TX off.

## What to do

1. Unplug **all** USB–UART leads. Original PSU only. If LAN/Power LEDs still never settle, the dongle is not the only load.
2. Inspect/desolder the joint. Do not add solder. Do not probe NAND pins.
3. UART homework is **parked**. Unplug the dongle. Do not add another listen unless you are only checking that LEDs recovered after desolder. Still no TX.
4. Do not factory-reset. Do not flash. Do not type CFE.

Related: [uart-button0-cut.md](uart-button0-cut.md) (older, later-in-boot cut).
