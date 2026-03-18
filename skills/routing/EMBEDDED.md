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
| ESP32 firmware (tasks, peripherals, OTA, power) | skills/c-embedded/SKILL.md + skills/freertos/SKILL.md |
| CMake cross-compilation, linker scripts, GCC toolchain, OpenOCD | skills/embedded-toolchain/SKILL.md |
| Non-IDF project (STM32, RP2040) setup from scratch | skills/c-embedded/SKILL.md + skills/embedded-toolchain/SKILL.md |
| MQTT from device, topic/queue contract alignment | skills/c-embedded/SKILL.md + skills/routing/BACKEND.md (message-queue) |
| Full ESP32 IoT device (firmware + connectivity) | c-embedded + freertos + embedded-toolchain + BACKEND(message-queue) |
| Full STM32 IoT device (firmware + connectivity) | c-embedded + freertos + stm32-hal + embedded-toolchain + BACKEND(message-queue) |
| Unclear / general embedded task | skills/c-embedded/SKILL.md |

## Combination rules
- `c-embedded` is always the foundation — load it with every other embedded skill
- `freertos` always alongside `stm32-hal` when RTOS is enabled in CubeMX
- `embedded-toolchain` for any non-IDF project (STM32, RP2040 bare metal, custom CMake)
- `BACKEND` branch should be loaded when task includes broker topology, routing keys, and consumer semantics
- `security-hardening` (from WORKFLOW) for TLS, secure boot, flash encryption on production devices
- `message-queue` (from BACKEND) for the backend side of the device MQTT pipeline
- `debug-trace` (from WORKFLOW) for JTAG/SWD debugging, core dumps, hardware faults
- `performance-profiling` (from WORKFLOW) for ISR timing, cycle counting, stack/heap analysis
