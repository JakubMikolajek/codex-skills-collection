---
name: embedded-lvgl
description: LVGL on embedded targets (esp_lvgl_port, MIPI-DSI/RGB/SPI panels, touch, PSRAM framebuffers). Covers the single-thread/lock model, calling LVGL from other tasks, draw/frame buffer placement and tearing, CPU budget and refresh period, screen lifecycle and memory leaks, assets and fonts in flash, i18n, backlight/dimming and idle behaviour, and keeping UI work off the critical path. Use when writing or reviewing UI code that runs LVGL on a microcontroller.
---

# LVGL on Embedded Targets

LVGL is a single-threaded library with its own timer loop, running on a device that is also doing I/O, security-relevant work and networking. UI bugs on an MCU are rarely visual; they are **threading, memory and CPU-budget** bugs.

## When to Use

- Creating or modifying screens, widgets, styles, animations, fonts or images in an LVGL firmware
- Calling UI updates from application/network/sensor tasks
- Tuning display throughput, tearing, memory use or touch responsiveness
- Debugging UI freezes, crashes after navigating screens, or heap decay

## When NOT to Use

- Web/React/native UI work — FRONTEND / NATIVE branches
- Display controller bring-up electrical details — hardware datasheets; this skill covers the software model
- Generic UX/visual quality — `ui-design-quality` (apply within the constraints here)

## Core Principle

**Exactly one context touches LVGL objects at a time, and the UI task must never wait on anything slow.** Everything else is a consequence: lock discipline, message-passing from workers, bounded work per refresh, and explicit lifecycle for every object and buffer.

## Delivery Workflow

```
LVGL progress:
- [ ] Step 1: Decide which task owns LVGL; list every other task that needs to update UI
- [ ] Step 2: Choose the update mechanism per caller (lock, async call, or message/subject)
- [ ] Step 3: Decide buffer placement (internal vs PSRAM), single/double/direct mode, tearing strategy
- [ ] Step 4: Budget render time per screen (worst-case redraw), set refresh period
- [ ] Step 5: Define screen create/destroy lifecycle and verify no leaks across repeated navigation
- [ ] Step 6: Test on the release preset with all background activity running
```

## Threading Model

- LVGL APIs are **not thread-safe**. With the ESP-IDF port: wrap every LVGL call made outside the LVGL task in `lvgl_port_lock(timeout)` / `lvgl_port_unlock()`; callbacks invoked **by** LVGL (event handlers, timers) already run holding the lock.
- **Never call LVGL from an ISR**, from an `esp_event`/MQTT handler, or from any callback that must return quickly. Post a message to the app/UI task instead.
- Prefer **message passing to the UI task** (queue + `lv_async_call`, or a subject/observer layer) over many tasks locking LVGL: it bounds lock hold time and removes lock-order risks.
- Take the LVGL lock with a **timeout** and handle failure (skip the update, count it). Holding it blocks rendering and touch; **never hold it while doing I/O, waiting on a queue/mutex, or sleeping**.
- Lock ordering: UI lock is a leaf lock. Don't take app/storage locks while holding it; don't call into modules that might need the UI lock while holding theirs.
- A callback that triggers heavy work (storage, network, crypto) must hand it to a worker and return; show a busy state and update on completion.

```c
// From a non-UI task: bounded, brief
if (lvgl_port_lock(50)) {
    lv_label_set_text(label, text);      // short, no blocking calls
    lvgl_port_unlock();
} else {
    ui_drop_counter++;                   // never block forever on the UI lock
}
```

## Rendering and Memory

- **Placement**: frame/draw buffers are big; PSRAM is slower but plentiful. Put hot, small buffers in internal RAM; large ones in PSRAM with the chip's alignment/DMA rules. Prefer panel-owned frame buffers (e.g. DSI/RGB double framebuffers) with "avoid tearing" modes where the port supports them — and note their constraints (often **no software rotation** in that mode).
- **Build** the LVGL component for speed (`-O2`) even if the rest builds `-Os`; software rendering dominates CPU.
- **Tearing**: use vsync/double-buffer modes supported by the panel interface; changing buffer count/mode changes memory use and latency — re-measure.
- **Refresh period**: LVGL's default is tuned for desktop; set the display refresh timer period to what the panel and CPU can sustain (and what the UX needs). A UI that renders at 60 fps while the device needs CPU for security or comms is a trade-off to make deliberately.
- **Fonts/images**: assets in flash are accessed via the cache (slow if cache contention; unreachable during flash writes — fine for rendering because the UI task is not an IRAM-safe context, but keep latency in mind). Decode large images (PNG) once into a cache/pre-converted format; avoid per-frame decoding. Subset fonts to needed glyph ranges.
- **LVGL heap** (`LV_MEM`/custom allocator): decide internal vs PSRAM and size it from measured peaks; log `lv_mem_monitor` periodically in dev builds to catch fragmentation/leaks.
- Don't animate big areas or many objects simultaneously; each animated pixel is CPU time stolen from everything else. Check the worst redraw (full-screen transitions, lists with images).

## Screen Lifecycle and Leak Hunting

- Every screen has explicit **create / show / hide / destroy**. Delete screens (and their timers, animations, styles, subjects, event callbacks with user data) when navigating away unless they are intentionally cached.
- `lv_timer_t`, `lv_anim_t`, observers and `lv_async_call` closures that reference deleted objects are a classic crash source after navigation. Stop/delete them in the screen's destroy path; guard async callbacks with a validity check.
- Navigate in a loop for minutes (scripted/test mode) and watch heap min-free and LVGL monitor numbers: **steady state must be flat**.
- Styles are shared objects: initialise once (static), don't allocate per widget.
- User-visible strings go through the i18n layer from the start (extract/compile translation tables as part of the build), with layout tested against the **longest** translation and the widest glyph set.

## Input

- Touch: report coordinates through the port's indev; calibrate/flip/swap in the driver, not in app code. Keep the touch ISR/driver task light; debounce physical keypads in software with a state machine.
- Long-press, double-tap and gesture timings are UX contracts — define them as constants, not magic numbers in handlers.
- Sensitive inputs (PIN/passcode entry): do not log keystrokes, mask by default, clear buffers after use (`explicit_bzero`/volatile wipe), and time out the screen.

## Backlight, Idle and Power

- Backlight dimming/sleep is a state machine driven by activity events (touch, proximity/radar, access events) with explicit wake sources; keep it in a dedicated module, not scattered through screens.
- Don't block wake-up on slow I/O; render the first frame immediately and fill in data after.
- PWM/backlight changes and display power sequencing follow the panel datasheet order; encapsulate them.

## Checklist

```
Threading:
- [ ] One LVGL owner task; non-UI tasks use lock-with-timeout or message passing
- [ ] No LVGL calls from ISR, MQTT/esp_event handlers or other time-critical callbacks
- [ ] No blocking calls (I/O, queues, mutexes, sleep) while holding the UI lock

Rendering/memory:
- [ ] Buffer placement and mode justified; tearing behaviour verified
- [ ] LVGL built for speed; refresh period set deliberately
- [ ] Heap peaks measured; screens/styles/timers freed; navigation soak is flat
- [ ] Large assets pre-decoded or cached; fonts subset

Lifecycle:
- [ ] create/show/hide/destroy defined per screen; timers/anims/observers cleaned up
- [ ] Async callbacks guard against deleted objects

UX/safety:
- [ ] Longest translation and widest glyphs tested
- [ ] Sensitive input masked, not logged, wiped
- [ ] Idle/backlight state machine independent of screens
- [ ] Tested on the release preset with background load
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Calling `lv_*` from an MQTT/event handler | Post a message; update from the UI task |
| `lvgl_port_lock(portMAX_DELAY)` from application tasks | Short timeout + drop/retry policy |
| Doing storage/network work inside an LVGL event callback | Hand off to a worker; show busy state |
| Allocating styles/timers per widget and never freeing | Static styles; delete timers/anims in destroy |
| Per-frame image decoding | Decode once / pre-convert |
| Full-screen animations at max refresh while the CPU is needed elsewhere | Budget CPU, lower the refresh/animation load |
| Logging PIN keystrokes "for debugging" | Never log secrets; mask and wipe |
| Hard-coded English strings | i18n layer from day one |
| Testing UI only on the dev preset on an idle device | Release preset with comms/sensors active |

## Connected Skills

- `esp-idf` — memory placement, cache rules, task priorities
- `freertos` — queues, lock ordering
- `c-embedded` — DMA/cache alignment and buffer safety
- `i18n` — translation workflow and layout testing
- `ui-design-quality` — visual quality within embedded constraints
- `performance-profiling` — render time and CPU budget measurement
- `embedded-debugging` — UI freezes, leaks, watchdog interactions
