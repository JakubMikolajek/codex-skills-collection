---
name: embedded-persistence
description: Power-fail-safe persistent storage design for embedded devices. Covers choosing NVS vs a flash filesystem (littlefs/FAT) vs raw partitions, atomic save patterns (temp file + fsync + rename), a dedicated storage worker with an internal-RAM stack, schema versioning and migration, CRC/validation on load, wear and write-rate budgets, ENOSPC handling, factory-reset semantics, and monotonic counters/nonces that must survive power loss. Use when adding or changing anything that writes configuration, credentials, user records, counters or logs to flash.
---

# Embedded Persistence

Flash storage is slow, finite, can be interrupted at any instruction, and (on ESP32-class parts) **disables the CPU cache while it works**. The failure you must design for is not "write returns an error", it is "power or watchdog hits in the middle".

## When to Use

- Adding or changing persisted config, credentials, user/access lists, counters, bonds/keys
- Choosing a storage mechanism or file layout
- Reviewing code that calls `fopen/fwrite/fsync/rename`, NVS, or `esp_partition_*`
- Designing format versions and migrations across firmware releases
- Investigating corrupted, empty, or rolled-back state after resets

## When NOT to Use

- Database/ORM design on the backend — `sql-and-database`, `data-modeling`
- Encryption-at-rest policy, key custody — `esp-idf-secure-ota`, `security-hardening`
- OTA slot handling — `esp-idf-secure-ota`

## Core Principle

**After any reset at any point, the device must come up with either the old complete state or the new complete state — never a mix, never empty, never rolled back past a security invariant.** Then: **write rarely, write small, write off the critical path.**

## Delivery Workflow

```
Persistence progress:
- [ ] Step 1: List every persisted item: size, change rate, criticality, secrecy, who reads/writes
- [ ] Step 2: Choose the mechanism per item class (table below)
- [ ] Step 3: Define the atomic-save and recovery protocol, incl. what a half-written state looks like
- [ ] Step 4: Define version/migration and the load-time validation
- [ ] Step 5: Compute write budget (writes/day x item size) vs wear and latency
- [ ] Step 6: Test power loss at every step (fault injection) and ENOSPC
```

## Choose the Mechanism

| Data | Use | Why |
|---|---|---|
| Small key/value settings, flags, counters of low rate | NVS | Wear-levelled, atomic per key, simple; mind quota and key naming |
| Structured records, lists, files of KB–MB, user-visible data | Flash filesystem (littlefs for power-fail tolerance; FAT only if PC-mountable media is a requirement) | Atomic rename, directories, bounded RAM |
| Large append-only logs/events | Ring of fixed-size records in a raw partition (or littlefs files rotated by size) | Predictable wear and bounded size |
| Secrets/keys | eFuse or encrypted partitions/NVS; never plain files | See `esp-idf-secure-ota` |
| Frequently changing hot data (per-event counters) | RAM + periodic checkpoint, or reserve-ahead scheme | Flash cannot take per-event writes |
| Data that must survive a software reset only | Retained RAM (`RTC_NOINIT`) with magic + CRC | No flash wear; lost on power loss |

## Atomic Save Pattern

```c
// 1. Serialize into RAM (versioned header + payload + CRC32)
// 2. Write to a temp name on the SAME filesystem
// 3. Flush data to the medium (fflush AND fsync/equivalent)
// 4. Close
// 5. rename(temp, final)   -- atomic replace in littlefs/most journalled FS
// 6. (optional) fsync the directory if the FS requires it
static esp_err_t save_blob(const char *path, const void *buf, size_t len) {
    FILE *f = fopen(TMP_PATH, "wb");
    if (!f) return ESP_FAIL;
    bool ok = fwrite(buf, 1, len, f) == len;      // check short writes (ENOSPC)
    ok &= (fflush(f) == 0) && (fsync(fileno(f)) == 0);
    ok &= (fclose(f) == 0);
    if (ok && rename(TMP_PATH, path) != 0) ok = false;
    if (!ok) unlink(TMP_PATH);                    // never leave debris that confuses recovery
    return ok ? ESP_OK : ESP_FAIL;
}
```

- A reset before `rename` leaves the **old file intact**; the temp file is garbage and is deleted on mount/next save.
- Never `fopen(path, "w")` on the live file (truncates first) — a reset leaves an empty file.
- Validate on load (magic, version, length, CRC). On failure: fall back to the **previous good copy** (keep `.bak` for critical data), then to safe defaults — and report it (telemetry), do not hide it.
- Keep the tmp file name fixed and the save path **serialized** (one save at a time) so recovery has one thing to look for.
- Check **every** return value: `fwrite` short counts, `fflush`, `fsync`, `fclose`, `rename`. Disk full (`ENOSPC`) must not delete the previous good state.

## Dedicated Storage Worker

On ESP-IDF every flash operation disables the cache; a task whose stack lives in PSRAM would fault. Isolate it:

```c
#define STORAGE_STACK_BYTES 8192
static StackType_t  s_stack[STORAGE_STACK_BYTES];   // static => internal RAM
static StaticTask_t s_tcb;
// one worker task owns all filesystem calls; others post jobs (queue) and wait with a TIMEOUT
```

- Callers from any task (including PSRAM-stack tasks) submit jobs and wait for completion; detect self-calls from the worker to avoid self-deadlock.
- **Callers must not hold their own long-lived locks while waiting for the worker**, and the worker must not call back into modules that take those locks (lock-order inversion; see `freertos`). A module that blocks synchronously on a save while holding its mutex stalls everyone behind that mutex for the full flash latency — decouple: copy state, release lock, enqueue, return.
- Add a **queue depth + timeout policy**: if saves back up, coalesce (only the latest state of a file matters) rather than growing without bound.
- Do not run saves in the interrupt/latency-critical path (e.g. the decision that opens a lock, a CAN receive handler). Persist asynchronously.
- Expose save duration metrics (p50/max) — a sudden max increase is an early warning of fragmentation, near-full FS or hardware wear.

## Save Tracing for Resets Mid-Write

```c
typedef struct { uint32_t magic, step, len; int64_t t_us; char name[48]; uint32_t crc; } save_trace_t;
static RTC_NOINIT_ATTR save_trace_t s_trace;   // survives WDT/panic reset, not power-on
// set step = OPEN/WRITE/FSYNC/CLOSE/RENAME before each stage; on boot report and clear
```

- One marker per distinct operation: **split `fflush` and `fsync`**, `close` and `rename`, otherwise the report is ambiguous.
- Use a monotonic clock consistently (don't mix with the log clock).
- The trace tells you *which stage was running at reset*, not *why*; pair with `embedded-debugging`.

## Formats, Versions and Migration

- Every persisted blob starts with `{magic, format_version, length}` and ends with a CRC (or has an authenticated tag if tampering matters).
- **Loaders accept all versions you ever shipped** (or explicitly refuse with a defined recovery), and the writer writes the newest. Test with fixture files from each released version.
- Migrate **in a copy**, validate, then atomically swap. Never migrate in place.
- Don't bake in struct layout: serialise field-by-field (little-endian, fixed width). Reordering a C struct must not corrupt stored data.
- Size limits matter to the FS: some filesystems store files below a threshold inline in metadata and use separate blocks above it; crossing the threshold (e.g. adding a second record to a file) changes the write path and cost. Know the limits of your FS configuration (cache size, inline threshold, block size, lookahead) and keep hot files comfortably on the cheap side — or split per-record files.
- Keep the file set small and flat; avoid directories with thousands of entries.
- Bound all strings/lists on load (never trust length fields from flash, they can be corrupt).

## Wear and Write Budget

```
writes/day = events/day * (state size or file size) / coalescing factor
```

- Estimate per-sector erase cycles vs part endurance for the product lifetime; filesystems wear-level but a hot file in a nearly full FS concentrates erases.
- Counters: persist **every N events** and on clean shutdown, not every event — but see monotonic counters below.
- Keep FS utilisation moderate (≤ ~70–80 %); near-full filesystems get slow and fragment.
- Log to RAM ring buffers; persist only summaries or on error.

## Monotonic Counters, Nonces and Replay Protection

Counters used for uniqueness (message counters, nonces, anti-replay windows) have a **stronger contract than ordinary state**:

1. They must **never go backwards** across any reset, restore, migration, or "recover from backup" path.
2. The usual safe scheme is **reserve-ahead**: persist `counter + K` *before* handing out values from `counter..counter+K-1`; after reset, resume from the persisted reserved value (skipping unused values is fine, reuse is not).
3. A write triggered by a *receive* event must not overwrite the reserved *transmit* counter with a stale value (separate keys/fields, or a single writer that persists the max). Saves that bundle several fields into one blob are especially prone to stale-field overwrites — review who owns each field.
4. **Do not "fix" a storage stall by deferring or dropping counter persistence.** That trades a performance bug for a security regression. If counter saves are the problem, reduce frequency via reserve-ahead or make saves cheaper, then re-review with `security-hardening`.
5. Test: kill power between "value used" and "value persisted" at every step and prove no reuse.

## Reset / Wipe Semantics

Define and document what each destructive operation clears and keeps (e.g. *wipe user data* keeps pairing/bonds; *factory reset* clears everything). Implement as an explicit allow-list of paths/keys per operation, test each, and make it **interruptible-safe** (a power cut during wipe must end in a bootable, consistent state — e.g. write a "wipe in progress" marker first and complete on next boot). Long wipes (formatting a big encrypted partition can take minutes) need progress/UX and watchdog care.

## Checklist

```
Design:
- [ ] Each persisted item classified (size, rate, criticality, secrecy)
- [ ] Mechanism matches the class; hot data not written per event
- [ ] Atomic-save protocol written down; every return value checked
- [ ] Load-time validation + fallback to previous good + defaults + telemetry
- [ ] Format version, migration tests with fixtures of all shipped versions

Runtime:
- [ ] Single storage worker with internal-RAM stack; callers use timeouts
- [ ] No save on a latency-critical path; no lock held across a blocking save
- [ ] Coalescing/queue bound; save-duration metrics
- [ ] ENOSPC and full-FS behaviour defined; old state preserved

Security:
- [ ] Counters/nonces monotonic across all paths (reserve-ahead)
- [ ] Secrets in encrypted storage only; none in logs
- [ ] Wipe/reset operations are allow-list based and power-fail safe

Verification:
- [ ] Power-loss/reset injected at every stage of save and migration
- [ ] Soak test of write rate; wear estimate for product life
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `fopen(path, "w")` on the live file | Temp file + fsync + `rename` |
| Ignoring `fwrite`/`fsync`/`rename` results | Check all; keep old state on failure |
| Saving on every event | Coalesce, reserve-ahead, or checkpoint |
| Calling storage from many tasks on PSRAM stacks | One worker with a static internal stack |
| Holding a module mutex while waiting for the save to finish | Copy, unlock, enqueue |
| Persisting a raw C struct | Versioned, field-wise serialisation + CRC |
| Loading and trusting length fields | Bound and validate everything |
| Migrating in place | Migrate a copy, validate, swap atomically |
| Restoring or rolling a counter backward | Monotonic reserve-ahead; fail closed |
| Deleting the previous good file before the new one is durable | Rename-over-old only |
| "Factory reset" implemented as `rm -rf` of an unspecified set | Explicit allow-listed paths per operation, resumable |

## Connected Skills

- `esp-idf` — cache-disabled flash ops, PSRAM stack rule, RTC_NOINIT
- `freertos` — worker/queue design, lock ordering
- `embedded-debugging` — power-loss and mid-write reset forensics
- `esp-idf-secure-ota` — encrypted partitions, update-time data migration
- `security-hardening` — nonce/replay and key handling review
- `migration-strategy` — schema/versioning discipline
- `error-handling` — failure policy per operation
