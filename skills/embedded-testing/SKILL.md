---
name: embedded-testing
description: Test strategy for embedded firmware where most code cannot run on a PC by default. Covers separating pure logic from hardware, host-compiled tests with ASan/UBSan and thin stubs for RTOS/SDK headers, byte-level fake peripherals and fixtures captured from real devices, fault-injection (power loss, ENOSPC, malformed frames), on-target Unity/pytest tests, and hardware-in-the-loop smoke checks. Use when adding logic to firmware, creating a test harness for a component, or deciding what must be verified on hardware.
---

# Embedded Testing

The goal is to push as much correctness as possible **off the hardware** (fast, repeatable, sanitized), and reserve hardware for what only hardware can show: timing, electrical behaviour, cache/flash/RF interactions, and integration.

## When to Use

- Adding protocol parsers, state machines, calibration, configuration/validation, schedulers, or storage formats
- Creating or extending a host test harness for a firmware component
- Deciding what to verify on target vs on the host
- Building fault-injection or fixture-based tests for drivers and links

## When NOT to Use

- Generic test pyramid and mocking guidance — `test-strategy`, `unit-testing`
- Timing, electrical or RF correctness — those need hardware; this skill says how to scope the hardware checks, not how to avoid them

## Core Principle

**Make logic pure, then make the impure edge thin.** A function that takes bytes and a state and returns bytes and a new state needs no hardware to test; a driver that mixes parsing, timing, FreeRTOS calls and GPIO does.

## Delivery Workflow

```
Embedded testing progress:
- [ ] Step 1: Split the component: pure core (parse/validate/FSM/format) vs service (tasks, I/O, timers)
- [ ] Step 2: Host-test the pure core with sanitizers; add golden fixtures
- [ ] Step 3: Test the service with stubbed SDK headers and a byte-level fake peripheral
- [ ] Step 4: Add fault injection for the failure paths that are hard to hit on hardware
- [ ] Step 5: Define the minimal on-target / HIL smoke set for what only hardware can prove
- [ ] Step 6: Wire the host suite into CI; keep it runnable with one command
```

## Layering for Testability

```
Component/
  Foo.h / Foo.c            service: tasks, queues, ESP-IDF/HAL calls   (thin)
  FooProto.c               pure: frame parse/build, CRC, validation     (host-tested)
  FooFsm.c                 pure: state machine, takes events, returns actions
  FooStore.c               pure-ish: serialise/deserialise, versioning  (host-tested with fixtures)
  test_host/
    run.sh                 builds & runs everything with one command
    stubs/                 minimal fake esp_log.h, esp_err.h, freertos/*.h, driver/*.h ...
    fake_<peripheral>.c    byte-level fake of the device on the other end of the link
    fixtures/              recorded real-world frames/files, per firmware/hardware version
    test_*.c               one executable per area
```

Rules:

- Pure modules **must not include SDK headers**. If they need time, memory or logging, take them through a small interface (function pointers or a struct of ops) so tests can inject a fake clock/allocator.
- State machines take `(state, event) → (new state, actions)`; the service executes actions. This makes timeouts testable with a fake clock — no sleeping.
- Keep ISR-adjacent code minimal and **separately** reviewed; it cannot be meaningfully host-tested for timing.

## Host Harness (no SDK required)

```sh
#!/bin/sh
set -e
CFLAGS="-std=gnu11 -Wall -Wextra -Werror -O1 -g -fsanitize=address,undefined -I$SRC -I$DIR"
cc $CFLAGS $SRC/FooProto.c test_foo_proto.c -o $OUT/test_foo_proto && $OUT/test_foo_proto
# service with stubbed SDK headers and a fake peripheral
cc $CFLAGS -DHOST_TEST -I$DIR/stubs $SRC/Foo.c fake_foo.c test_foo_service.c -o $OUT/test_foo_service
```

- Compile with `-Werror` + **ASan/UBSan** — most embedded memory bugs (overflow, use-after-free, unaligned/packed access, signed overflow) show up here for free.
- Stubs are **minimal**: only the declarations/behaviours the code under test uses. A stub that grows into a re-implementation of the SDK is a smell — move more logic into the pure layer.
- Test 32-bit assumptions: compile with `-m32` where the toolchain allows, or add `static_assert`s for size/layout; host 64-bit hides pointer/`long`/`size_t` bugs.
- Reproduce **time** with an injected clock: wraparound at `UINT32_MAX`, timeouts, backoff, watchdog-like behaviours.
- Allocation failure: inject `NULL` from the allocator stub and verify error paths release everything and keep invariants.

## Fixtures and Fakes

- **Golden fixtures**: capture real frames/files from hardware (including odd ones: truncated, garbage, version N-1, vendor firmware quirks) and commit them with a short README of how they were captured. Parser tests iterate over every fixture.
- **Byte-level fake peripheral**: a model of the other end of a UART/SPI/CAN link that speaks the real protocol (including bad checksums, partial frames, delays), driven by the test. It lets you test the *service* (task loop, retries, timeouts, recovery) deterministically.
- **Format compatibility tests**: store a file per shipped format version; assert that the current loader reads each and that migrate→save→load round-trips.
- **Fuzz/property tests** for parsers: random bytes/lengths must never crash, loop forever, or read out of bounds; valid frames round-trip.

## Fault Injection (hard-to-hit paths)

| Fault | How to inject | What to assert |
|---|---|---|
| Power loss mid-save | Fake FS that fails/aborts at step N of the save protocol; iterate N over every step | Old or new state loads; never empty/mixed |
| Disk full | Fake `write` returning short/`ENOSPC` | Previous state preserved; error reported |
| Allocation failure | Allocator stub returning NULL at the k-th call | No leak, no crash, defined degraded behaviour |
| Queue full | Zero-length queue stub | Documented drop policy applied, counted |
| Disconnect mid-message | Fake transport cut at each byte offset | Reassembly state reset, no leak |
| Malformed/oversize input | Fixtures + fuzz | Rejected with error, bounds respected |
| Clock jump/wrap | Fake clock | Durations monotonic; no spurious timeouts |
| Peer on older/newer version | Fixture of old handshake | Clean refusal or compatibility path |

## On-Target Tests

- Use the SDK's on-target framework (Unity + `pytest-embedded` on ESP-IDF) for things the host cannot model: peripheral drivers, memory placement, flash/cache interactions, task timing, watchdog behaviour, filesystem on the real part.
- Keep each on-target test **short, self-contained and idempotent**; restore state; tag long tests (soak) separately.
- Run the **release preset** at least for smoke/soak — dev-only config deltas hide bugs.

## Hardware-in-the-Loop / Bench Smoke Set

Define a small, scripted checklist run before each release candidate on real units (ideally release-configured):

```
- Cold boot -> reach steady state within X s; reset reason is POWERON
- Primary function path (e.g. unlock path) end-to-end within latency budget
- Connectivity: connect, broker/offline transitions, recovery without reboot
- Update path: previous release -> candidate -> rollback on injected failure
- Storage: write-heavy loop with random power cuts (relay/PSU) — state consistent after each
- Stress/soak: N hours of the highest-rate scenario; track heap min-free, largest block, stack watermarks, reset count
- Thermal/brownout-sensitive actions (radio TX + actuator) concurrently
```

Automate what you can with a console command or a test mode that exposes counters (heap, watermarks, reset reasons) so soak results are numbers, not impressions.

## Checklist

```
- [ ] New logic lives in a pure module with no SDK includes
- [ ] Host tests build with -Werror and ASan/UBSan; one command runs them all
- [ ] Fixtures include real captures and old format versions
- [ ] Fake clock/allocator/FS/transport injected; failure paths exercised
- [ ] Parsers fuzzed/property-tested for bounds and termination
- [ ] On-target tests only for what needs hardware; run on release preset
- [ ] HIL smoke set defined, scripted and run before release
- [ ] Soak metrics (heap, stacks, resets) collected as numbers
- [ ] Host tests wired into CI
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| "Can't test, it needs hardware" for parsing/FSM logic | Extract pure core, host-test it |
| Stubbing the whole SDK in one giant fake | Minimal stubs + move logic to the pure layer |
| `sleep()` in host tests to wait for timeouts | Inject a fake clock |
| Only happy-path fixtures | Add truncated, garbage, old-version, oversize frames |
| Testing power-loss by "unplugging a few times" | Deterministic fault injection at every protocol step + a bench soak with a relay |
| On-target tests only on the dev preset | Also run on the release preset |
| Tests that depend on wall-clock or test order | Hermetic, fixed seeds, isolated state |
| Fixing a field bug without adding the captured case as a fixture | Add the fixture first (red), then fix |

## Connected Skills

- `c-embedded` — language-level hazards ASan/UBSan will find
- `freertos` — stubbing queues/tasks/semaphores for service tests
- `esp-idf` — on-target test infrastructure and config presets
- `embedded-persistence` — power-fail protocol under test
- `embedded-connectivity` — protocol and fragmentation cases
- `test-strategy` — overall test pyramid and risk-based scope
- `unit-testing` — general unit-test craft
- `ci-cd` — running the host suite in CI
