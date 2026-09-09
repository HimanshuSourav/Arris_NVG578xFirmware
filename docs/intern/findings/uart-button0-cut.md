# UART cut at Motopia button 0 (GPIO 36)

Listen-only evidence from a spare running **official Ziply firmware**. Not a flash cookbook. Do not send TX, do not issue CFE commands, do not factory-reset, do not flash this OSS `.w`.

The same unit **booted normally until serial-port pins were soldered** (UART J7/J8-style pad). After that joint, Linux died inside Motopia `registerBtns` at GPIO 36 (WPS) and SW-reset looped. Treat the cause as the solder (bridge to GND or a neighbor, splash onto another GPIO, pad/SoC heat, or 5 V from the USB–UART through the new pin)—not missing Motopia source and not a NAND-image problem.

**Closed 2026-09-08.** Soldering the UART pins put this spare into that mode. Listen-only homework is done: no TX, no CFE, no factory-reset, no OSS `.w` flash, no kernel “skip button 0” patch. Next step is hardware only (unplug dongle, inspect/desolder). Chat: [bc-a9d7cc40](https://cursor.com/agents/bc-a9d7cc40-d472-452e-85f9-af84ef825f7a). Intern docs: [PR #2](https://github.com/HimanshuSourav/Arris_NVG578xFirmware/pull/2).

## Capture

- 115200 8N1, **DTR/RTS off**, no TX.
- Window: after `Registering button 0` until `0xff` snow.
- **0.13 s**, **122 bytes** of log, then mark/`0xff`, then BTRM.
- Same last two lines on four cycles.

```
Registering button 0 (ffffffc000a07ee0) (bpGpio: 00008024, bpExtIrq:00000000 (0))
    extIrqIdx:0, gpioNum:36 ACTIVE LOW
```

122 bytes is those two lines (plus a CR). There is no truncated third kernel line in this window.

| String | After button 0 until snow |
| --- | --- |
| `board_wl` / `SES:` | **none** (and `board_wl_init` runs *before* buttons anyway) |
| `rdpa` | **none** |
| `gpon` | **none** |
| `ubi` / `UBI` | **none** (UBI only earlier: cmdline `ubi.mtd=0` and rootfs-on-UBI) |
| `Oops` / `panic` / `Watchdog` / `sysmgr` | **none** |
| `Button 0: Registering` (hook lines) | **none** |
| `Registering button 1` | **none** |
| `WPS Button Pressed` / `Restarting System` / `D%G` | **none** |

Kernel never reaches WLAN/RDPA/GPON **modules**. It stops in Motopia GPIO/button init, the line goes to snow, then BTRM. Earlier in the same boot: NAND/UBI look normal; `/mfg` ENODEV (`-19`) is **not** the last line; dying-gasp IRQ was armed but did not fire (`D%G` absent); last reset reason on a clean printk was **SW reset** `0x00010000`.

## Source mapping (OSS tree, after extract)

Printks: `bcmdrivers/opensource/char/board/bcm963xx/impl1/board_button.c` (`registerBtns`).

Board table: `shared/opensource/boardparms/bcm963xx/boardparms_6856.c` `g_nvg578lxmfg` (templates `NVG578LX` / `LX1` / `HLX`).

| Log field | Value | Why |
| --- | --- | --- |
| `bpGpio` | `00008024` | `BP_GPIO_36_AL` = GPIO 36 \| `BP_ACTIVE_LOW` (`0x8000`) |
| `bpExtIrq` | `00000000` | `BP_EXT_INTR_0` is `0`; `BP_EXT_INTR_TYPE_IRQ_LOW_LEVEL` is also `0` |
| `extIrqIdx` / `gpioNum` | `0` / `36` ACTIVE LOW | `(bpExtIrq & ~flags) - BP_EXT_INTR_0`; polarity from `BP_ACTIVE_LOW` |

Button 0 in that table is **WPS**: PRINT (`"WPS Button Pressed !!"`) + SES on **press**.

Button 1 is **reset**: PRINT, `RESTORE_DEFAULTS` hold 10 s, **`BP_BTN_ACTION_RESET` on release** (GPIO 82, `BP_EXT_INTR_1`). A stuck **WPS** line does not call `btnHook_Reset`. Do not factory-reset the spare to “test” this.

## `brcm_board_init` order

`board.c`:

1. `board_util_init` — `print_rst_status`, dying gasp  
2. `init_reset_irq` — only if `BpGetResetToDefaultExtIntr` exists; **this SKU does not** (reset is the button-1 hook, not the legacy ISR)  
3. **`board_wl_init`** — PCI screen, `kerSetWirelessPD(WLAN_ON)` on GPIO 0, SES map. No `bp_usExtIntrSesBtnWireless` on this table, so **no** `SES: Button Interrupt` printk  
4. LEDs / optional HW timers  
5. `board_wd_init` — empty unless `CONFIG_BCM_WATCHDOG_TIMER`  
6. **`registerBtns`** — dies here on the captured box  
7. `add_proc_files` — not reached if step 6 does not return  

RDPA/GPON drivers are **later** `module_init`s. Empty greps for `rdpa`/`gpon` after button 0 only show those modules never got to run.

## What runs after the last printk

Immediately after the `gpioNum` line, still in the button-0 loop:

1. `kthread_run(btnThread, …, "btnhandler0")` — would printk `ERROR could not start kthread` on NULL (does **not** check `IS_ERR`)  
2. `spin_lock_irqsave`, timer setup, `map_external_irq(bpExtIrq)` (integer switch to `INTERRUPT_ID_EXTERNAL_0`; would printk `Invalid External Interrupt` on a bad id)  
3. **`printk("Button %d: Registering %s hook"…)`** for PRINT then SES — **not in the capture**  
4. Unlock, then `BcmHalMapInterrupt(pressIsr, …)` (`request_irq`; would printk `request_irq failed`)  

Hook printks happen **before** `BcmHalMapInterrupt`, while the button spinlock is held with IRQs off. If those lines are truly never issued, the cut is **`kthread_run` / timer / `map_external_irq`**, not a WPS press ISR. If they were issued but UART died before flush, `BcmHalMapInterrupt` on a **level-low** GPIO 36 that is already asserted could run `btnPressIsr` immediately — still PRINT+SES, not `kernel_restart`.

`btnHook_Reset` (` *** Restarting System ***` + `kernel_restart`) is only registered when **button 1** is processed. That loop never printed.

## If it booted before the solder

1. Unplug **all** USB–UART wires (not only TX). Power with the original adapter. If LEDs/LAN come up like before, the dongle was loading the new pin — do not reconnect a 5 V Prolific lead.
2. If it still loops: power off. Under magnification, look for bridges (especially a signal pin to GND or to the next pad) and solder balls on nearby `TP*` / GPIO. Continuity, **unpowered**: a TX/RX pad must not be a dead short to the shield unless it was already GND.
3. Desolder that pin/header if you can without more heat; clean flux. Do not solder GPIO 36 / WPS to “fix” the log line.
4. Do not factory-reset (Linux never registers that hook). Do not flash this OSS `.w`.

## What this does *not* prove

- Not a stuck SWREG inner loop; not a hang in `WaitPmc` (PMC already printed `running` earlier).  
- Not dying-gasp (`D%G`).  
- Not `/mfg` as the kill.  
- Not “WLAN/RDPA/GPON crashed” — those strings would be **after** a successful `brcm_board_init`.  
- Not a proven short **on GPIO 36 itself** — that is only where the kernel last printed; the soldered pad may be UART or a neighbor. Not a reason to flash this OSS `.w`.
- Disconnecting Motopia GPIO/button leads **did not** stop the reboot loop. Linux still printed `Registering button 0` / `gpioNum:36 ACTIVE LOW` and died there. The WPS pad is where the printk stops, not a confirmed stuck IRQ you can unplug around.

## `brcm_board_init` through snow (done)

Same settings. Window starts at `brcmboard: brcm_board_init entry` (the prefix, not only the two death lines) until `0xff` snow. **0.19 s**, 781 bytes of log.

**Not useful for a later cut.** Still **no** `SES:`, **no** `request_irq failed`, **no** `Registering button 1`. Prefix is the known block (`/mfg` `-19`, `print_rst_status`, dying-gasp enable, `map_hw_timer_interrupt` 10–13), then the same two `registerBtns` lines, then snow. Listen-only greps for a third kernel line are exhausted; stop adding UART experiments. Still no TX.

Later the same spare no longer always reaches Linux at all — see [uart-btrm-nand.md](uart-btrm-nand.md).