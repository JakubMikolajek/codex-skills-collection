---
name: esp-idf
description: ESP-IDF platform patterns for ESP32-family firmware (ESP32, S3, C6, P4). Covers the component model and CMake, sdkconfig layering (dev vs release presets), memory regions and heap caps (IRAM/DRAM/PSRAM/DMA), the flash-cache-disabled rules (IRAM ISRs, PSRAM task stacks), dual-core task design, watchdogs, esp_err_t error handling, logging, and component/SDK upgrades. Use when writing, reviewing or debugging ESP-IDF firmware. Load alongside c-embedded and freertos.
---

# ESP-IDF

ESP-IDF is FreeRTOS + drivers + a configuration system (Kconfig/`sdkconfig`) + a component build. Most production bugs on ESP32 do not come from the API surface — they come from **where code and data live**, **what runs while flash is busy**, and **which sdkconfig a binary was actually built with**. This skill covers those.

> Path note: framework behaviour changes between IDF majors (5.x → 6.x). Before relying on a Kconfig name, an API or a documented limitation, check the **IDF version pinned by the project** (`idf.py --version`, `dependencies.lock`, the tag in `$IDF_PATH`) and read the header/Kconfig from that tree. Do not quote docs for a different version.

## When to Use

- Writing or reviewing firmware on ESP32 / S2 / S3 / C3 / C6 / P4 with ESP-IDF
- Adding or changing a component, `CMakeLists.txt`, `idf_component.yml`, `Kconfig(.projbuild)` or an sdkconfig default
- Touching memory placement (PSRAM, IRAM, DMA buffers), interrupts, task creation, or watchdog settings
- Upgrading ESP-IDF or a managed component, or vendoring a patched component locally

## When NOT to Use

- Generic C patterns, volatile/atomics, DMA basics — `c-embedded`
- FreeRTOS primitive semantics — `freertos`
- Secure boot, flash encryption, signed OTA, partition layout — `esp-idf-secure-ota`
- Reset/WDT/panic forensics — `embedded-debugging`
- Flash filesystems and NVS data design — `embedded-persistence`
- Arduino-ESP32 sketches (different abstraction, same silicon)

## Core Principle

**Every ESP-IDF design decision answers three questions: where does this code/data live (IRAM, DRAM, flash, PSRAM), which core and priority runs it, and what happens while flash is being written?** If you cannot answer all three for a new task, ISR, or buffer, it is not ready for review.

## Delivery Workflow

```
ESP-IDF progress:
- [ ] Step 1: Confirm IDF version, target chip/revision, and which sdkconfig preset applies
- [ ] Step 2: Place the new code in the right component (REQUIRES vs PRIV_REQUIRES)
- [ ] Step 3: Decide memory placement for each buffer/stack (internal vs PSRAM vs DMA)
- [ ] Step 4: Decide task core/priority/stack and watchdog participation
- [ ] Step 5: Define the error and failure path for every esp_err_t call
- [ ] Step 6: Build BOTH dev and release presets; compare sdkconfig effects
- [ ] Step 7: Check heap/stack headroom at runtime on the worst-case path
```

## Component Model and CMake

```cmake
# components/Foo/CMakeLists.txt
idf_component_register(
    SRCS "Foo.c" "FooInternal.c"
    INCLUDE_DIRS "."               # public headers only
    REQUIRES esp_timer             # in PUBLIC headers of this component
    PRIV_REQUIRES nvs_flash esp_littlefs   # only used in .c files
)
```

- `REQUIRES` leaks into dependants; use `PRIV_REQUIRES` unless the dependency's types appear in your public headers. Wrong `REQUIRES` is the main cause of circular-dependency errors.
- Never `file(GLOB ...)` sources in a component that multiple people edit — a new file silently not being built is a classic. List sources explicitly.
- Per-component compile options go on the component lib: `idf_component_get_property(lib foo COMPONENT_LIB)` + `target_compile_options(${lib} PRIVATE ...)` (e.g. build a hot UI library `-O2` while the rest stays `-Os`).
- Version set in `CMakeLists.txt` **before** `project()` via `PROJECT_VER` ends up in `esp_app_desc_t` — the OTA comparison reads this. Keep one source of truth.
- Fail the build when a safety-relevant sdkconfig is wrong (`idf_build_get_config(...)` + `message(FATAL_ERROR ...)`) instead of documenting it in a README.

### Managed vs vendored components

- `idf_component.yml` + the component manager resolves versions at configure time. Projects that patch third-party components (LVGL, esp_hosted, network provisioning) often **vendor them into `components/`** and disable the manager (`IDF_COMPONENT_MANAGER=0`). Then upstream fixes do not arrive by themselves, and every local patch must be documented.
- Keep a `PATCHES`/notes entry for each local modification of a vendored component (file, line, reason, upstream issue) so an upgrade does not silently drop it. Re-apply and rebuild after every update.
- A `REQUIRES`/`PRIV_REQUIRES` workaround inside a vendored component (e.g. commenting out a version check) must be re-evaluated on each IDF bump.

## sdkconfig Discipline

```
sdkconfig.defaults            # shared
sdkconfig.defaults.dev        # + dev overrides  (console, log level, JTAG, relaxed security)
sdkconfig.defaults.prod       # + release overrides
sdkconfig.defaults.<hw-rev>   # per hardware revision
sdkconfigs/sdkconfig.<preset> # generated, per CMake preset (SDKCONFIG=...)
```

Rules:

1. **Defaults files are inputs; the generated `sdkconfig` is a cache.** If a default changes but the generated file already contains the symbol, the change is ignored. After editing defaults, delete the generated `sdkconfig.<preset>` (or run `idf.py -B <dir> reconfigure` after removal) and verify the resulting value.
2. A change made in `menuconfig` is **lost** unless written back to a defaults file (`idf.py save-defconfig`, then merge by hand into the right layer).
3. **Dev and release must be diffed on every config change.** Settings that exist only in dev (CPU1 watchdog check, console, relaxed asserts, extra heap poisoning) silently change timing and memory — a bug that "only happens in release" is often a config delta. Diff the *resolved* configs, not the defaults files:
   `diff <(sort sdkconfigs/sdkconfig.A) <(sort sdkconfigs/sdkconfig.B)`.
4. Safety-critical symbols (signed apps scheme, rollback, flash encryption mode) get a CMake `FATAL_ERROR` guard so a mis-generated config cannot produce a shippable binary.
5. Never edit `sdkconfig` by hand without saying so in the PR; never commit an `sdkconfig.old`.
6. Treat chip revision settings (`CONFIG_ESP32P4_REV_MIN_*`) as part of the hardware contract — changing them changes which silicon workarounds are compiled in.

## Memory: Where Things Live

| Region | Use | Notes |
|---|---|---|
| IRAM | ISRs and code that must run with the flash cache disabled | Scarce; every `IRAM_ATTR` byte reduces the cache/heap |
| DRAM (internal) | Default for stacks, DMA buffers, hot data, most heap | Fast, scarce. Fragmentation matters |
| Flash (XIP via cache) | Code, `const` data | **Inaccessible while flash is written/erased** unless cached or in IRAM |
| PSRAM (external) | Large buffers, framebuffers, caches, big JSON, TLS I/O buffers | Slower; accessed through the cache; **unreachable while the cache is off**; check alignment/DMA rules per chip |
| RTC / retained RAM | Data surviving deep sleep or watchdog/panic resets | `RTC_NOINIT_ATTR` survives most resets but not power loss; contents are garbage on first boot — guard with a magic + CRC |

```c
// Explicit placement
uint8_t *big = heap_caps_malloc(n, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
uint8_t *dma = heap_caps_aligned_alloc(align, n, MALLOC_CAP_DMA | MALLOC_CAP_INTERNAL);
static RTC_NOINIT_ATTR boot_trace_t s_trace;           // retained across WDT/panic reset
```

Rules:

- **Always check `heap_caps_*` return values** and define the failure behaviour (drop the message, return `ESP_ERR_NO_MEM`, degrade) — a missing PSRAM allocation must not become a NULL dereference.
- Large allocations repeatedly made/freed in internal RAM fragment it. Track `heap_caps_get_largest_free_block(MALLOC_CAP_INTERNAL)` and `heap_caps_get_minimum_free_size(...)`, not just total free.
- DMA-capable ≠ internal-only on all chips; on chips with PSRAM + data cache, DMA from PSRAM needs cache-line alignment and cache sync (`esp_cache_msync` / aligned allocation helpers). Read the peripheral driver's documentation for the exact requirement.
- Changing the L2/cache/PSRAM configuration changes how much **internal** RAM is left for the heap (e.g. shrinking an L2 cache frees SRAM; moving mbedTLS or LWIP allocations to internal RAM consumes it). Re-measure after every such change.
- `CONFIG_SPIRAM_*` options that put instructions/rodata in PSRAM (XIP from PSRAM) increase the set of code that is unreachable with the cache off — re-audit IRAM-safety when enabling them.
- Prefer `EXT_RAM_BSS_ATTR` for large static buffers that may live in PSRAM and `heap_caps_*` for runtime ones; keep **all** latency-critical data internal.
- Report memory in logs/diagnostics as `largest free block` per capability, not only `esp_get_free_heap_size()`.

## Flash Operations and the Cache

While SPI flash is being written/erased (and by anything that remaps the cache, such as `esp_partition_mmap`/`munmap` — which is what reading an encrypted partition through some drivers does; verify for the pinned IDF version and chip), the CPU cache is disabled. Consequences:

1. **ISRs not registered with `ESP_INTR_FLAG_IRAM` are masked** during the operation — interrupt latency spikes by the operation's duration. Latency-sensitive interrupts (audio, motor, radio, TWAI with small FIFO) need `ESP_INTR_FLAG_IRAM` handlers.
2. An IRAM-safe ISR must reside in IRAM (`IRAM_ATTR`), and everything it touches must be reachable with the cache off: no calls into flash-resident functions (incl. `ESP_LOG*`, `printf`, libc string functions unless placed in IRAM), no flash-resident `const` tables (use `DRAM_ATTR`), no PSRAM data, no non-ISR FreeRTOS calls (use `*FromISR`; these are IRAM-resident unless `CONFIG_FREERTOS_PLACE_FUNCTIONS_INTO_FLASH` is enabled — if it is, they are not IRAM-safe).
3. **Task stacks in PSRAM are unsafe for any task that can call into flash operations** (filesystem, NVS, OTA, `esp_partition_*`, logging to a flash-backed sink). Such a task's stack must be internal RAM — a violation asserts at runtime (`esp_task_stack_is_sane_cache_disabled`). If any task may need a PSRAM stack (to save internal RAM), restrict it to flash-free work and route flash access through a dedicated storage task with a static internal-RAM stack (see `embedded-persistence`).
4. Time-critical code must not assume a bounded latency around flash writes. Flash erase of a sector can take tens of ms; a big write may stall other CPU's access depending on chip and config. Do not write to flash inside a latency-sensitive path (e.g. directly in an access-control decision path) — queue it.
5. Frequent flash writes (counters, event logs) also wear the part — see `embedded-persistence`.

```c
// IRAM-safe ISR registration
gpio_install_isr_service(ESP_INTR_FLAG_IRAM);
static void IRAM_ATTR on_edge(void *arg) {
    BaseType_t woken = pdFALSE;
    vTaskNotifyGiveFromISR(s_task, &woken);   // IRAM-safe
    portYIELD_FROM_ISR(woken);
}
```

## Tasks, Cores and Priorities

- ESP-IDF FreeRTOS is **SMP on dual-core chips**; a task may run on either core unless pinned. Pin (`xTaskCreatePinnedToCore`) tasks that must share a core with a driver's ISR or that touch per-core resources; otherwise leave `tskNO_AFFINITY` and write the task as if it could run in parallel with every other task.
- IDF system tasks have high priorities (Wi-Fi/lwIP/esp_timer/ipc, `esp_hosted` workers, mqtt). A user task above them can starve connectivity; a CPU-bound user task at priority 1 on the same core as IDLE trips the task watchdog.
- Stack size is in **bytes** in IDF. Typical floors: plain logic 3–4 KB; `printf`/`snprintf` with floats 4+ KB; JSON (cJSON) 6 KB+; TLS/HTTPS/OTA 8–10 KB+; filesystem + logging 6–8 KB. Measure with `uxTaskGetStackHighWaterMark`.
- Static allocation (`xTaskCreateStatic`) with an **explicitly internal** stack buffer is the safest option for tasks that touch flash, and avoids runtime allocation failure.
- Use `portMUX`/spinlocks (`portENTER_CRITICAL(&mux)`) only for very short (µs) sections on shared data across cores/ISRs; they disable interrupts on that core. Anything that can block uses a mutex.
- Do not call blocking or non-ISR-safe APIs from `esp_timer` callbacks with `ESP_TIMER_ISR` dispatch; the default `ESP_TIMER_TASK` dispatch runs on one shared task — keep callbacks tiny or hand off to a worker.
- Event handlers registered via `esp_event` run on the **event loop task**; a blocking handler stalls all Wi-Fi/IP/MQTT events behind it. Copy data and signal a worker.
- Creating a task from inside a time-critical path (e.g. per-request) fragments the heap and can fail; prefer a long-lived worker plus queue.

## Watchdogs

| Watchdog | Catches | Typical action |
|---|---|---|
| Interrupt WDT (IWDT) | Interrupts/scheduler blocked too long (long critical section, ISR loop, cache-disabled spin) | Panic / reset |
| Task WDT (TWDT) | A subscribed task (or IDLE) not running for N s | Panic + backtrace or reset |
| RTC/main system WDT | Chip-level hang, bootloader stage | Hard reset, **no backtrace** |
| Bootloader WDT | Boot/validation takes too long | Reset (and rollback logic if enabled) |

- Subscribe **critical long-running tasks** explicitly (`esp_task_wdt_add`) and feed from the task's real progress point, not from a timer that fires regardless.
- Never "fix" a TWDT by raising the timeout or disabling it without understanding who is starving whom. Capture `esp_task_wdt` backtrace first (see `embedded-debugging`).
- Never feed the watchdog from a place that still runs when the app is logically hung (e.g. a heartbeat timer).
- Check CPU1 idle watchdog coverage (`CONFIG_ESP_TASK_WDT_CHECK_IDLE_TASK_CPU1`, `CONFIG_ESP_INT_WDT_CHECK_CPU1`) deliberately in both presets.
- A reset with reason `ESP_RST_WDT` / `INT_WDT` and no panic output means the CPU could not even run the panic handler — treat as a system-level stall (cache/flash/PSRAM/bus), not an ordinary bug.

## Error Handling and Logging

```c
#include "esp_check.h"

esp_err_t foo_init(void) {
    esp_err_t err = ESP_OK;
    ESP_GOTO_ON_FALSE(cfg, ESP_ERR_INVALID_ARG, fail, TAG, "no cfg");
    ESP_GOTO_ON_ERROR(i2c_driver_install(...), fail, TAG, "i2c install");
    return ESP_OK;
fail:
    foo_cleanup_partial();     // undo what succeeded; init functions must be re-entrant after failure
    return err;
}
```

- `ESP_ERROR_CHECK` aborts. Acceptable only during **boot-time init of things that make the device pointless if missing** — and even then decide if "reboot loop" is the right product behaviour. Never in runtime paths, and never around operations that can legitimately fail (network, flash full, sensor NACK).
- Return `esp_err_t` from every fallible function; use IDF's codes (`ESP_ERR_NO_MEM`, `ESP_ERR_TIMEOUT`, `ESP_ERR_INVALID_STATE`, …) and keep domain-specific details in logs, not magic numbers.
- Handle partial init: an init that fails halfway must release what it acquired and be safe to call again.
- Log tags: one `static const char *TAG` per file. Levels: `E` = needs attention / lost function, `W` = degraded but recovering, `I` = lifecycle events, `D/V` = development only.
- **Do not log secrets** (PINs, keys, tokens, passcodes, raw biometric templates, full credentials) at any level, and do not leave them in dev-only logs that could be shipped. See `security-hardening`.
- Logging is not free: it can block on UART/USB, runs in the caller's context, needs stack, and is not IRAM-safe. Keep it out of ISRs and tight loops; rate-limit repeated errors.
- Release builds often compile logs out (`LOG_DEFAULT_LEVEL` / `LOG_MAXIMUM_LEVEL` none) and disable the console. Then **diagnostics must go through an explicit channel** (retained trace, reset-reason report over MQTT/syslog, coredump) — see `embedded-debugging`. Do not assume "I'll just read the log".
- Timestamps: `esp_log_timestamp()` (ms since boot, log clock) and `esp_timer_get_time()` (µs, high-resolution timer) are different clocks. Never subtract one from the other.

## Boot, Reset Reasons and Retained State

- At boot, read `esp_reset_reason()` once and surface it (log, diagnostics, telemetry). `ESP_RST_PANIC`, `ESP_RST_INT_WDT`, `ESP_RST_TASK_WDT`, `ESP_RST_WDT`, `ESP_RST_BROWNOUT` are product-quality signals — count them.
- `RTC_NOINIT_ATTR` data survives watchdog/panic/software resets but is **undefined on power-on**. Use `magic + version + CRC`, and clear after reporting.
- Restarting (`esp_restart()`) as an error recovery must be rate-limited (boot-loop protection counter) and must flush/close storage first when possible.

## Upgrading IDF or Components

1. Read the release notes/migration guide of every major/minor crossed; grep your code for removed or renamed Kconfig symbols (stale symbols are silently ignored in defaults).
2. Regenerate presets from defaults (delete generated sdkconfigs), then diff against the previous resolved config to see every behavioural change.
3. Rebuild with **warnings visible**; fix new deprecation warnings (they are removal notices).
4. Re-run all hardware smoke paths: Wi-Fi/Hosted link, TLS, OTA (including rollback), flash-encrypted storage, display/touch, watchdog behaviour.
5. Re-validate every vendored patch (see above).

## ESP-IDF Checklist

```
Build/config:
- [ ] IDF version and chip revision known; docs/headers checked against that version
- [ ] Default files edited, generated sdkconfigs regenerated, dev-vs-release resolved diff reviewed
- [ ] REQUIRES vs PRIV_REQUIRES correct; sources listed explicitly
- [ ] Safety-critical sdkconfig symbols guarded in CMake

Memory:
- [ ] Every large/DMA/latency-critical buffer has explicit placement
- [ ] All heap_caps_* returns checked; largest free block monitored
- [ ] RTC_NOINIT data protected by magic+CRC

Flash/cache:
- [ ] ISRs that must run during flash ops use ESP_INTR_FLAG_IRAM and touch only IRAM/DRAM
- [ ] No PSRAM stack for any task that can call filesystem/NVS/OTA/partition APIs
- [ ] No flash writes in latency-critical paths

Tasks:
- [ ] Core affinity, priority and stack (bytes) justified and measured
- [ ] Watchdog participation defined; no feeding from unrelated timers
- [ ] No blocking inside esp_event handlers / esp_timer callbacks

Errors:
- [ ] esp_err_t checked everywhere; ESP_ERROR_CHECK only in boot-critical init
- [ ] Partial-init cleanup paths; no secrets in logs
- [ ] Release diagnostics channel exists (logs may be compiled out)
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Editing `sdkconfig.defaults.*` and trusting the build | Delete the generated sdkconfig, rebuild, check the resolved value |
| Fixing a bug in dev config only | Reproduce with the release preset; diff the resolved configs |
| `file(GLOB ...)` for component sources | Explicit `SRCS` list |
| `ESP_ERROR_CHECK` in runtime code | Handle and return the error |
| PSRAM task stack for a task that touches NVS/FS/OTA | Static internal-RAM stack, or route flash work to a storage task |
| `ESP_LOGx` / `printf` inside an IRAM ISR | Set a flag / notify a task; log from task context |
| Raising a WDT timeout to "fix" resets | Find the starving task/critical section/stall |
| Feeding the TWDT from a periodic timer | Feed from the task's own progress |
| Comparing `esp_log_timestamp()` with `esp_timer_get_time()` | Use one clock per measurement |
| Assuming free heap = usable heap | Check largest free block per capability |
| Blocking in `esp_event` handler or `esp_timer` callback | Copy + signal a worker |
| Silent local patch to a vendored component | Document file/line/reason; re-apply after every update |
| Relying on UART logs in a release build with the console off | Retained trace / telemetry / coredump |

## Connected Skills

- `c-embedded` — language-level safety (atomics, packed structs, DMA/cache)
- `freertos` — primitives and deadlock review
- `esp-idf-secure-ota` — secure boot, flash encryption, signed/encrypted OTA, partitions, rollback
- `embedded-persistence` — flash filesystems, NVS, power-fail-safe writes
- `embedded-debugging` — reset reasons, WDT/panic/coredump, JTAG
- `embedded-connectivity` — Wi-Fi, esp_hosted, MQTT, CAN
- `embedded-lvgl` — LVGL on esp_lvgl_port
- `embedded-testing` — host tests for components
- `security-hardening` — secrets, key handling, TLS policy
- `performance-profiling` — ISR timing, heap/stack analysis
