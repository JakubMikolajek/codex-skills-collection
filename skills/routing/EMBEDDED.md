# EMBEDDED Branch

## When to enter this branch
- Task involves firmware for a microcontroller (ESP32, STM32, AVR, RP2040, or similar)
- Task involves C or C++ code targeting a resource-constrained device
- Task involves peripheral drivers (GPIO, I2C, SPI, UART, ADC, DMA)
- Task involves FreeRTOS tasks, queues, semaphores, mutexes, or interrupt handlers
- Task involves bare-metal startup, linker scripts, or memory layout
- Task involves CMake cross-compilation or GCC embedded toolchain configuration
- Task involves MQTT communication from an embedded device
- Task involves WiFi connectivity, provisioning, or OTA updates on a device
- Task involves ESP-IDF (components, sdkconfig, PSRAM/IRAM placement, watchdogs), secure boot, flash encryption or signed OTA
- Task involves persistent storage on flash (NVS, littlefs, counters, config files) or power-loss safety
- Task involves LVGL UI on a microcontroller, CAN/ISO-TP links, or device reset/watchdog/crash investigation
- Task involves host-side tests or hardware-in-the-loop checks for firmware
- Files being edited are `.c`, `.h`, `.cpp`, `.s` (assembly), `CMakeLists.txt`, or `*.ld` (linker script)

## When NOT to enter this branch
- Backend MQTT consumers (NestJS, Python) — use BACKEND
- WebSocket or real-time from a web frontend — use FRONTEND
- Rust embedded (`no_std`) — use BACKEND (rust skill) with c-embedded as supplement for concepts
- CI/CD for firmware build pipelines — use WORKFLOW (ci-cd skill)

## Decision tree

| If the task involves... | Read next |
|---|---|
| C/C++ language patterns, types, volatile, ISR, memory, bitwise ops | skills/c-embedded/SKILL.md |
| FreeRTOS tasks, queues, semaphores, mutexes, event groups, timers | skills/c-embedded/SKILL.md + skills/freertos/SKILL.md |
| STM32 HAL drivers, CubeMX project, STM32 peripherals | skills/c-embedded/SKILL.md + skills/stm32-hal/SKILL.md |
| STM32 + FreeRTOS | Load all three: c-embedded + freertos + stm32-hal |
| ESP32 / ESP-IDF firmware (components, sdkconfig, memory placement, tasks, watchdogs, peripherals) | skills/c-embedded/SKILL.md + skills/freertos/SKILL.md + skills/esp-idf/SKILL.md |
| Secure boot, flash encryption, signing keys, partition table, OTA/rollback, companion-chip updates | skills/esp-idf/SKILL.md + skills/esp-idf-secure-ota/SKILL.md (+ WORKFLOW security-hardening) |
| Persisted config/users/counters/logs, littlefs/NVS, power-loss safety, schema migration | skills/c-embedded/SKILL.md + skills/embedded-persistence/SKILL.md (+ skills/esp-idf/SKILL.md on ESP32) |
| Wi-Fi/ESP-Hosted, MQTT client, CAN/TWAI + ISO-TP, device-to-device secure links | skills/c-embedded/SKILL.md + skills/embedded-connectivity/SKILL.md (+ esp-idf on ESP32, + BACKEND message-queue for the contract) |
| LVGL UI, display/touch, backlight/idle behaviour on a device | skills/c-embedded/SKILL.md + skills/embedded-lvgl/SKILL.md (+ esp-idf on ESP32) |
| Resets, watchdogs, panics, hangs, corruption, "only in release" failures | skills/embedded-debugging/SKILL.md + skills/esp-idf/SKILL.md (ESP32) + WORKFLOW debug-trace |
| Host tests, fakes, fixtures, HIL smoke plan for firmware logic | skills/embedded-testing/SKILL.md + skills/c-embedded/SKILL.md |
| CMake cross-compilation, linker scripts, GCC toolchain, OpenOCD | skills/embedded-toolchain/SKILL.md |
| Non-IDF project (STM32, RP2040) setup from scratch | skills/c-embedded/SKILL.md + skills/embedded-toolchain/SKILL.md |
| MQTT from device, topic/queue contract alignment | skills/c-embedded/SKILL.md + skills/routing/BACKEND.md (message-queue) |
| Full ESP32 IoT device (firmware + connectivity) | c-embedded + freertos + esp-idf + embedded-connectivity + embedded-persistence + BACKEND(message-queue) |
| Production ESP32 device (secure, updatable, with UI) | c-embedded + freertos + esp-idf + esp-idf-secure-ota + embedded-persistence + embedded-connectivity (+ embedded-lvgl when a display exists) |
| Full STM32 IoT device (firmware + connectivity) | c-embedded + freertos + stm32-hal + embedded-toolchain + BACKEND(message-queue) |
| Unclear / general embedded task | skills/c-embedded/SKILL.md |

## Combination rules
- `c-embedded` is always the foundation — load it with every other embedded skill
- `freertos` always alongside `stm32-hal` when RTOS is enabled in CubeMX
- `embedded-toolchain` for any non-IDF project (STM32, RP2040 bare metal, custom CMake); ESP-IDF projects use `esp-idf` instead (IDF has its own CMake layer)
- `esp-idf` is the ESP32-family foundation — load it with `c-embedded` + `freertos` for any ESP-IDF task; the other ESP-oriented skills (`esp-idf-secure-ota`, `embedded-persistence`, `embedded-connectivity`, `embedded-lvgl`) assume it
- `esp-idf-secure-ota` for any change to partitions, signing, eFuse/security sdkconfig, OTA code or release scripts — together with `security-hardening`
- `embedded-persistence` whenever code writes to flash; it also owns the rules for monotonic counters/nonces
- `embedded-debugging` for resets/hangs/corruption; it adds embedded specifics on top of `debug-trace`, it does not replace it
- `embedded-testing` when adding logic that can be separated from hardware; load before writing the code so the pure/impure split is designed in
- `BACKEND` branch should be loaded when task includes broker topology, routing keys, and consumer semantics
- `security-hardening` (from WORKFLOW) for TLS, secure boot, flash encryption on production devices
- `message-queue` (from BACKEND) for the backend side of the device MQTT pipeline
- `debug-trace` (from WORKFLOW) for JTAG/SWD debugging, core dumps, hardware faults
- `performance-profiling` (from WORKFLOW) for ISR timing, cycle counting, stack/heap analysis
