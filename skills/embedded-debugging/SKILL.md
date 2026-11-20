---
name: embedded-debugging
description: Evidence-first debugging of embedded firmware failures that leave little trace - watchdog resets, panics without backtrace, hangs, heap/stack corruption, intermittent resets tied to a specific action. Covers reading reset reasons, decoding backtraces and coredumps, hang-instead-of-reset experiments, JTAG/GDB, retained-RAM breadcrumbs, isolation matrices, and how to keep hypotheses honest without hardware. Use when a device resets, freezes or corrupts data and the cause is not obvious. Load alongside debug-trace.
---

# Embedded Debugging

Embedded failures hide: logs are compiled out in release, the crash resets the very thing that holds the evidence, and timing changes when you add a `printf`. This skill is about **getting evidence first** and **not promoting theories to facts**.

## When to Use

- Unexpected resets (`INT_WDT`, `TASK_WDT`, `WDT`, `PANIC`, `BROWNOUT`) or boot loops
- Device hangs / UI freezes / network task stalls
- Data corruption, random crashes, "works in dev build, fails in release"
- A fix attempt did not change the symptom and you need a new loop
- Analysing a field crash report or coredump

## When NOT to Use

- General debugging workflow (feedback-loop menu, hypothesis discipline) — `debug-trace` covers it; this skill adds embedded specifics
- Known-class compile/link errors — `embedded-toolchain`

## Core Principle

**Classify first, hypothesise second, instrument third.** The reset reason, core(s) involved, last known PC and what the system was doing narrow the space by an order of magnitude *before* any code change. Keep three separate lists at all times: **Established (with evidence)**, **Hypotheses (with how to falsify each)**, **Rejected (and why)**.

## Delivery Workflow

```
Embedded debug progress:
- [ ] Step 1: Capture the exact symptom: reset reason, timing relative to a trigger, build/preset, hardware revision
- [ ] Step 2: Classify (table below) and decide whether a hang-instead-of-reset run is possible
- [ ] Step 3: Build the tightest reproducer (loop, scripted trigger, or bench rig)
- [ ] Step 4: Add retained breadcrumbs / coredump / JTAG capture, not more logs
- [ ] Step 5: Falsify hypotheses with isolation experiments, one variable at a time
- [ ] Step 6: Fix, then verify with the reproducer under the RELEASE preset
- [ ] Step 7: Record Established / Rejected so the next session does not redo it
```

## Reading the Reset

| Reset reason | Means | First move |
|---|---|---|
| `PANIC` (exception, assert, abort) | Software fault with a handler that ran | Decode backtrace + registers with the **matching ELF** |
| `TASK_WDT` | A subscribed task/IDLE did not run for N s | Backtrace of the starving and starved tasks; who holds CPU/lock |
| `INT_WDT` | Interrupts/scheduler blocked too long (critical section, ISR loop, cache-disabled spin) | Look for long critical sections, ISR work, flash ops with blocked cores |
| `WDT` / main system WDT / RTC WDT | Chip-level stall: even the panic handler could not run. No backtrace | Treat as a *system* stall: cache/flash/PSRAM/bus/clock, other-core spin; need JTAG, breadcrumbs or hang mode |
| `BROWNOUT` | Supply dip | Measure the rail under the triggering load (radios, motors, backlight, lock actuators) |
| `SW` / `esp_restart()` | Intentional | Find *who* asked; log the reason before restarting |
| `POWERON` after unexpected loss | Power or reset line | Hardware |

Notes:

- A saved PC like the reset vector after a WDT reset is the PC **after** the reset, not the fault location.
- Prefer facts over guesses on which watchdog fired: read the reset-cause register/field your SDK exposes, and the config of each WDT window in the **resolved** sdkconfig of the **failing preset**.
- Dev builds can differ from release in console, log level, CPU1 watchdog coverage, heap poisoning, and timing. Repro on release before believing a conclusion.

## Make the Failure Observable

1. **Hang instead of reset.** Temporarily disable the watchdogs that mask the stall (bootloader/RTC/task/interrupt as appropriate), then halt both cores on JTAG when it freezes. A frozen system keeps its registers, stacks and cache state — a reset destroys them. Record that watchdog changes were made and revert them.
2. **JTAG/GDB.** `openocd` + `gdb` (`idf.py openocd`, `idf.py gdb`); on a hang `info threads`, `bt` per core, read `$pc`, fault registers, FreeRTOS thread list. Without symbols (ELF that does not match the binary) everything is guesswork — archive the ELF of each build.
3. **Coredump.** Enable core dump to flash (needs a `coredump` partition; encrypted if flash encryption is on) or UART; `idf.py coredump-info` / `coredump-debug` with the matching ELF. Remember coredumps only exist for panics, not for chip-level WDT resets.
4. **Retained breadcrumbs.** Write small structs into no-init/retained RAM (`RTC_NOINIT_ATTR` on ESP32) *without logging, locking or heap use*: current step enum, per-core heartbeat tick, last handler entered, timestamp. After reset, read, report, and clear. Guard with magic + CRC; contents are random on power-on. Breadcrumbs must be written from code that may run with the cache disabled → keep them in internal RAM and avoid calling flash-resident helpers there.
5. **Per-core heartbeats.** Increment a counter from each core every N ms (hook, timer, or high-priority tick). After a stall, whether one or both counters stopped, and when relative to the last step marker, discriminates "one core spinning" from "whole chip stalled".
6. **Split coarse markers.** If one marker covers two calls (`fflush` + `fsync`), split it. Add markers *around* suspicious regions, not inside regions where logging would change behaviour.
7. **Reset-reason telemetry.** Even in release with no console, send `reset_reason` + breadcrumb to the backend/syslog on next boot. Fleet statistics beat single-unit guesses.

## Clock and Time Traps

- Different timestamp sources are different clocks (`esp_log_timestamp()` ms-since-boot-of-log vs `esp_timer_get_time()` µs). **Never compute intervals across clocks**; one such mistake produced a fictitious "2.5 s stall" in a real investigation. Use one monotonic clock for deltas.
- Wall-clock (RTC/NTP) jumps — don't use it for intervals.
- A 32-bit µs counter wraps in ~71 min.

## Isolation Matrix

Change **one** variable per run and record the outcome and the number of attempts:

| Axis | Examples |
|---|---|
| Concurrency | single core (`UNICORE`), pin tasks to one core, serialise the suspect module |
| Subsystems off | Wi-Fi/hosted link, syslog/UDP, NFC/radar/other sensors, UI dimming/saver, automations |
| Memory | move stacks/buffers internal↔PSRAM, change cache/L2 size, heap poisoning, `heap_caps_check_integrity_all()` before/after the suspect op |
| Storage | clean partition vs worn/dirty, file size below/above a block-cache threshold, different filesystem config |
| Hardware | second unit, other board revision, alternate supply, scope on rails during the trigger |
| Build | full clean build, release vs dev preset, partial revert of path sets instead of bisecting commits when many areas changed |

Rules:

- A **reproducer without the product** (a console command/test task that loops the suspect operation at an adjustable rate) turns a once-an-hour failure into minutes and makes every experiment comparable (cycles-to-failure).
- For intermittent failures, define "fixed" statistically up front (N× the previous mean time-to-failure without recurrence).
- Prefer a **partial revert of a directory set** over commit bisecting when the suspect commit mixes unrelated changes.
- Fix attempts that "did not help" stay in the Rejected list with the evidence; do not re-try them silently.

## Corruption Suspects (heap, stack, DMA, PSRAM)

- Stack overflow: canary hook enabled, measure high-water mark on worst paths, check tasks created with small stacks that later gained logging/TLS/JSON.
- Heap: poisoning (comprehensive in test builds), `heap_caps_check_integrity_all(true)` around the suspect operation, `heap_trace` for leaks and double free, watch `largest free block` over uptime.
- Use-after-free / ownership across queues: who frees a message sent through a queue, and what if the queue is full or the receiver is deleted?
- DMA buffers: alignment, location (internal vs PSRAM), cache sync, buffer reuse before the transfer completes.
- Concurrent PSRAM + flash cache pressure: unusual stalls may be hardware/cache effects; check chip errata and SDK release notes for the exact revision and version, and reproduce with a minimal harness before opening a vendor issue.
- Unaligned/packed struct access, ISR touching non-IRAM-safe code while flash is busy (see `esp-idf`).

## Writing the Hypothesis Log

Keep it in the repo/vault, not in memory:

```
Symptom: ...   Build/preset: ...   HW: ...   Repro rate: ...
Established: [fact — evidence (log excerpt/file:line/measurement)]
Hypotheses:  H1 (weight, how to falsify)  H2 ...
Rejected:    [claim — why (evidence)]
Unverified without hardware: [list]
Next experiment (highest leverage first): ...
```

Mark claims derived only from reading code as **source-derived, not measured**. Cite file:line against the **exact SDK/commit** in use, not documentation for another version. Separate "security bug found while debugging" from the crash theory and route it to its own review.

## Checklist

```
- [ ] Reset reason + timing + preset + HW rev captured
- [ ] Classification done; "hang instead of reset" considered
- [ ] Matching ELF available for every decoded address
- [ ] Reproducer exists (or why not) and cycles-to-failure measured
- [ ] Retained breadcrumbs/heartbeats added without logging in critical regions
- [ ] One-variable-at-a-time isolation results recorded
- [ ] Fix verified on the release preset with the reproducer
- [ ] Temporary debug config (watchdogs off, poisoning) reverted
- [ ] Established / Rejected / Unverified recorded
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Adding `printf`s in the suspect region | Retained breadcrumbs; logging changes timing and can need the cache |
| Raising/disabling a watchdog and calling it fixed | Find what is starved or stalled; disable only for the diagnostic hang run |
| Debugging on dev preset only | Reproduce on release; diff resolved configs |
| Decoding addresses with an ELF from another build | Archive and use the exact ELF |
| Subtracting timestamps from different clocks | One monotonic clock for deltas |
| Treating a plausible source reading as a measured fact | Label it "source-derived"; design an experiment |
| Changing several things per run | One variable per run, record attempts-to-failure |
| Dropping rejected hypotheses from notes | Keep with evidence so work is not repeated |
| Fixing the symptom by deferring a write that protects a security invariant | Escalate; do not trade replay/nonce safety for stability |

## Connected Skills

- `debug-trace` — feedback-loop construction and general hypothesis discipline
- `esp-idf` — watchdogs, cache rules, memory placement
- `freertos` — deadlock/starvation review, stack overflow hooks
- `embedded-persistence` — storage-related stalls and power-loss traces
- `observability` — reset/crash telemetry pipeline
- `performance-profiling` — ISR timing, heap/stack analysis
- `session-learning` — record failure patterns after resolution
