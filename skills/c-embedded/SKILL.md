---
name: c-embedded
description: C programming patterns for embedded systems. Covers memory management, fixed-width types, bitwise operations, volatile and const correctness, interrupt-safe code, hardware register access, and defensive coding for resource-constrained environments. Use when writing or reviewing C code targeting microcontrollers (ESP32, STM32, AVR, RP2040) regardless of the SDK or framework on top.
---

# C for Embedded Systems

Embedded C is not desktop C. The constraints are different: no OS memory safety net, limited RAM measured in kilobytes, peripherals mapped to memory addresses, and bugs that brick hardware or cause silent data corruption. This skill covers the patterns that separate reliable firmware from firmware that works until it doesn't.

## When to Use

- Writing C code for any microcontroller (ESP32, STM32, AVR, RP2040, or similar)
- Reviewing firmware for correctness, safety, and resource usage
- Any task involving hardware registers, interrupts, or peripheral drivers
- Porting or refactoring embedded C code

## When NOT to Use

- ESP32-specific SDK patterns (component model, sdkconfig, memory caps, flash/cache rules, NVS, WiFi) — use `esp-idf`
- High-level Arduino sketches with no direct hardware access — the patterns here apply but are not primary
- Rust embedded (`no_std`) — different ownership model, different skill

## Core Principle

**In embedded, undefined behavior kills hardware.** Integer overflow, uninitialized memory, and race conditions are not academic concerns — they corrupt sensor readings, lock up peripherals, or drain batteries. Every pattern here exists to prevent a specific class of hardware failure.

## Delivery Workflow

```
Embedded C progress:
- [ ] Step 1: Establish memory budget and stack/heap constraints
- [ ] Step 2: Define types and data structures with explicit widths
- [ ] Step 3: Implement peripheral access with correct volatile/const usage
- [ ] Step 4: Handle interrupts safely
- [ ] Step 5: Verify error handling and defensive coding
- [ ] Step 6: Review for undefined behavior and resource leaks
```

## Types and Fixed-Width Integers

Never use `int`, `long`, or `unsigned` in embedded code. Their sizes are platform-defined and change between architectures.

```c
#include <stdint.h>
#include <stdbool.h>

// Always use fixed-width types
uint8_t  byte_val;      // 0–255, GPIO state, single register byte
uint16_t adc_raw;       // 0–65535, 12-bit ADC fits here
uint32_t timestamp_ms;  // millisecond uptime counter
int16_t  temperature;   // signed sensor value in 0.1°C units
int32_t  error_code;    // signed for negative error values

// Size-explicit struct for protocol frames
typedef struct __attribute__((packed)) {
    uint8_t  start_byte;   // 0xAA
    uint16_t device_id;
    uint8_t  cmd;
    uint16_t payload_len;
    uint8_t  checksum;
} uart_frame_t;
// __attribute__((packed)) prevents padding — critical for wire protocols
// BUT: never take a pointer to a packed member (&frame.device_id) — unaligned access traps on
// Cortex-M0/RISC-V and is slow elsewhere. memcpy the field out instead. Serialize/parse
// explicitly byte by byte for anything crossing a wire or flash boundary (endianness, versioning);
// treat the packed struct as a layout description, not as the parser.
_Static_assert(sizeof(uart_frame_t) == 7, "uart_frame_t wire layout changed");

// Never do this in embedded:
int count;          // 16-bit on AVR, 32-bit on ARM — unpredictable
long timeout;       // 32-bit on some, 64-bit on others
```

Use `size_t` for sizes and counts (buffer lengths, array indices). Use `ptrdiff_t` for pointer arithmetic differences.

## Volatile and Const Correctness

`volatile` tells the compiler that a variable can change outside normal program flow. Missing `volatile` causes the optimizer to cache values in registers, silently breaking interrupt-driven code and hardware register access.

```c
// Hardware register — must be volatile
// (memory-mapped peripheral, value changes based on hardware state)
#define GPIO_IN_REG  (*((volatile uint32_t *)0x3FF44004))

// Shared between ISR and main loop — must be volatile
volatile bool data_ready = false;
volatile uint16_t adc_buffer[32];

// ISR sets flag
void IRAM_ATTR adc_isr_handler(void *arg) {
    adc_buffer[adc_idx++] = read_adc();
    data_ready = true;
    // Without volatile on data_ready, the compiler may never re-read it in main()
}

// Main loop reads flag
void app_main(void) {
    while (!data_ready) {
        // Without volatile, compiler may optimize this to: if (!false) { infinite_loop(); }
    }
    process(adc_buffer);
}

// Const pointer to volatile — pointer is constant, pointed-to value can change
const volatile uint32_t *status_reg = (volatile uint32_t *)0x3FF44000;

// Read-only input parameter — use const to communicate intent and enable optimization
void process_frame(const uart_frame_t *frame, size_t len);
```

Rule: **every hardware register access must be volatile. Every variable shared with an ISR must be at least `volatile` — and if more than one value must stay consistent, or the access is a read-modify-write, `volatile` is not enough.**

`volatile` only stops the compiler from caching/eliding the access. It gives **no atomicity** (a `uint64_t` or a struct is read in several instructions), **no ordering** between different variables, and **no cross-core visibility** on SMP chips (ESP32, ESP32-P4 dual core). For shared state use one of:

```c
#include <stdatomic.h>

static atomic_uint_fast32_t s_rx_overruns;          // single counter / flag, lock-free
atomic_fetch_add_explicit(&s_rx_overruns, 1, memory_order_relaxed);

static atomic_bool s_data_ready;                    // publish flag with data behind it:
// producer: write payload, THEN release-store the flag
atomic_store_explicit(&s_data_ready, true, memory_order_release);
// consumer: acquire-load the flag, THEN read payload
if (atomic_load_explicit(&s_data_ready, memory_order_acquire)) { /* payload is visible */ }
```

Use a critical section / mutex / queue when several fields must change together. Check `ATOMIC_*_LOCK_FREE` on tiny cores (Cortex-M0 has no `LDREX/STREX`; the compiler falls back to library calls that are not ISR-safe).

## Interrupt-Safe Code

Interrupts can preempt any instruction. Code that looks atomic in C is often not at the assembly level.

```c
// WRONG — non-atomic read-modify-write, can be interrupted mid-operation
uint32_t counter = 0;
void isr_handler(void) { counter++; }   // read-modify-write: 3 instructions on most CPUs
void main_reads(void) { use(counter); } // may read a half-updated value

// RIGHT — disable interrupts around multi-step shared state access
volatile uint32_t counter = 0;

// Platform-agnostic critical section pattern:
// ARM Cortex-M (STM32, RP2040, most commercial MCUs)
void isr_handler(void) {
    counter++;   // NOT atomic even on Cortex-M: LDR / ADD / STR can be preempted.
                 // Safe only if this ISR is the SOLE writer and nothing else modifies it.
                 // Otherwise: atomic_fetch_add or a critical section.
}

// Multi-variable or multi-step critical section — ARM Cortex-M
static inline uint32_t enter_critical(void) {
    uint32_t primask = __get_PRIMASK();
    __disable_irq();
    return primask;
}
static inline void exit_critical(uint32_t primask) {
    __set_PRIMASK(primask);
}

// Usage:
void update_state(void) {
    uint32_t mask = enter_critical();
    state.x = new_x;
    state.y = new_y;   // these two must be consistent
    exit_critical(mask);
}

// FreeRTOS critical sections (use when RTOS is present):
// taskENTER_CRITICAL() / taskEXIT_CRITICAL()          — from task context
// taskENTER_CRITICAL_FROM_ISR() / taskEXIT_CRITICAL_FROM_ISR() — from ISR

// ESP32-specific: portENTER_CRITICAL_ISR(&mux) for SMP (dual-core)
// See esp-idf skill for ESP32-specific critical section patterns
```

ISR rules (platform-agnostic):
- Keep ISRs as short as possible — set a flag or push to a queue, do work in main loop or task
- Never call blocking functions from ISR context (`printf`, `malloc`, mutex lock)
- Never block in an ISR — no `while(waiting)`, no sleep
- For RTOS systems: use ISR-safe API variants (FreeRTOS `xQueueSendFromISR`, `xSemaphoreGiveFromISR`)
- For ESP32: only ISRs registered with `ESP_INTR_FLAG_IRAM` run while the flash cache is disabled; those (and everything they call, plus the data they touch) must live in IRAM/DRAM — see `esp-idf`
- Never assume an ISR runs "rarely enough" — design for the worst-case storm (bouncing input, bus error loop) and bound the work per interrupt

```c
// Correct ISR pattern: flag + main loop (bare metal / no RTOS)
volatile bool data_ready = false;

void adc_isr(void) {
    raw_adc = ADC_DR;       // read hardware register immediately
    data_ready = true;      // signal main loop
}

void main_loop(void) {
    while (1) {
        if (data_ready) {
            data_ready = false;          // clear before processing (not after)
            process_adc_reading(raw_adc);
        }
    }
}

// Correct ISR pattern: queue (with FreeRTOS)
void gpio_isr_handler(void *arg) {
    uint32_t gpio_num = (uint32_t)arg;
    BaseType_t higher_prio_woken = pdFALSE;
    xQueueSendFromISR(isr_queue, &gpio_num, &higher_prio_woken);
    portYIELD_FROM_ISR(higher_prio_woken);  // yield if higher-priority task unblocked
}
```

## Memory Management

Dynamic allocation (`malloc`/`free`) is dangerous in embedded:
- Heap fragmentation causes `malloc` to return `NULL` after days of uptime
- No garbage collector — every allocation must have a corresponding free
- Allocation failure is silent if you don't check the return value

```c
// Prefer static allocation for objects with known lifetime
static uint8_t rx_buffer[256];         // statically allocated, no fragmentation
static sensor_data_t sensor_readings[MAX_SENSORS];

// If dynamic allocation is necessary — ALWAYS check return value
uint8_t *buf = malloc(size);
if (buf == NULL) {
    ESP_LOGE(TAG, "malloc failed for %zu bytes", size);
    return ESP_ERR_NO_MEM;             // propagate error, never continue with NULL
}
// ... use buf ...
free(buf);
buf = NULL;                            // null after free — prevents use-after-free

// Stack allocation for temporaries — but watch stack depth
// Task stacks are typically 2-8 KB; stack arrays + printf/snprintf + library frames add up
// Large local arrays overflow the stack silently
uint8_t large_buf[1024];              // DANGEROUS if task stack < ~2KB — use static or heap
// Also avoid recursion, VLAs, and alloca() in firmware (unbounded stack use)
```

Stack overflow detection: FreeRTOS `configCHECK_FOR_STACK_OVERFLOW = 2` (ESP-IDF: `CONFIG_FREERTOS_CHECK_STACKOVERFLOW_CANARY`), optionally GCC `-fstack-protector` / `CONFIG_COMPILER_STACK_CHECK_MODE_*` for overflow of local arrays. The task watchdog does **not** detect stack overflow. Use `uxTaskGetStackHighWaterMark()` to measure actual stack usage during development, under worst-case load (TLS handshake, JSON, logging, error paths) — not on the happy path.

```c
// Check stack headroom during development
void monitor_task(void *pvParameters) {
    while (1) {
        UBaseType_t watermark = uxTaskGetStackHighWaterMark(NULL);
        ESP_LOGI(TAG, "Stack watermark: %u words", watermark);
        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}
```

## Error Handling

Embedded systems cannot throw exceptions. Every function that can fail must return an error code and callers must check it.

```c
// Define error codes — use esp_err_t conventions on ESP32, or define your own
typedef int32_t hal_err_t;
#define HAL_OK          (0)
#define HAL_ERR_TIMEOUT (-1)
#define HAL_ERR_BUSY    (-2)
#define HAL_ERR_NODEV   (-3)

// Every fallible function returns an error code
hal_err_t sensor_read(uint8_t addr, int16_t *out_temp) {
    if (out_temp == NULL) return HAL_ERR_NODEV;    // guard against NULL output

    hal_err_t err = i2c_read_register(addr, REG_TEMP, (uint8_t *)out_temp, 2);
    if (err != HAL_OK) {
        ESP_LOGW(TAG, "sensor_read failed: %ld", err);
        return err;
    }
    *out_temp = (*out_temp >> 4);   // apply 12-bit shift per datasheet
    return HAL_OK;
}

// Caller MUST check return value
hal_err_t err = sensor_read(SENSOR_ADDR, &temperature);
if (err != HAL_OK) {
    // Handle: retry, use cached value, enter safe state
    use_cached_temperature();
    return err;
}

// ESP-IDF macro for propagating errors (similar to Rust's ?)
ESP_ERROR_CHECK(i2c_master_init());   // logs + aborts on error — use only during init
// In runtime code: check manually and handle gracefully
```

## Bit Manipulation and Register Access

```c
// Bit manipulation — use macros for readability
#define BIT(n)          (1UL << (n))
#define SET_BIT(reg, n) ((reg) |= BIT(n))
#define CLR_BIT(reg, n) ((reg) &= ~BIT(n))
#define GET_BIT(reg, n) (((reg) >> (n)) & 1UL)
#define TOG_BIT(reg, n) ((reg) ^= BIT(n))

// Bit fields in structs — use for register maps from datasheets
typedef union {
    uint32_t raw;
    struct {
        uint32_t data_ready  : 1;   // bit 0
        uint32_t overrun     : 1;   // bit 1
        uint32_t mode        : 2;   // bits 2-3
        uint32_t reserved    : 12;  // bits 4-15 — always name reserved bits
        uint32_t sample_rate : 16;  // bits 16-31
    };
} sensor_status_reg_t;

// Read register
sensor_status_reg_t status;
status.raw = read_register32(SENSOR_STATUS_ADDR);
if (status.data_ready) {
    // process new sample
}

// Multi-byte values: always be explicit about endianness
// Microcontrollers are typically little-endian; many sensors are big-endian
uint16_t raw = (uint16_t)(buf[0] << 8) | buf[1];   // big-endian from sensor
// NOT: uint16_t raw = *(uint16_t *)buf;             // UB + wrong on LE systems
```

## Defensive Coding Patterns

```c
// 1. Assert in debug builds, handle gracefully in release
#ifdef DEBUG
#define ASSERT(cond) do { if (!(cond)) { ESP_LOGE(TAG, "Assert failed: %s", #cond); abort(); } } while(0)
#else
#define ASSERT(cond) ((void)0)       // never evaluate `cond` in release — no side effects hidden in asserts
#endif
// Asserts catch *programmer* errors (broken invariants). Runtime/IO failures (timeout, NACK, CRC)
// are NOT asserts — they are error returns. In production decide explicitly: log + safe state + reset.

// 2. Guard all pointer parameters
void process_data(const uint8_t *data, size_t len) {
    ASSERT(data != NULL);
    ASSERT(len > 0 && len <= MAX_PAYLOAD);
    if (data == NULL || len == 0) return;    // still guard in release
    // ...
}

// 3. Bounds-check array accesses — no exceptions to save you
uint8_t ring_buffer[64];
static uint8_t head = 0, tail = 0;

bool rb_push(uint8_t byte) {
    uint8_t next_head = (head + 1) % sizeof(ring_buffer);
    if (next_head == tail) return false;    // full — never overflow silently
    ring_buffer[head] = byte;
    head = next_head;
    return true;
}

// 4. Timeout every blocking wait
uint32_t start = get_tick_ms();
while (!sensor_ready()) {
    if ((get_tick_ms() - start) > SENSOR_TIMEOUT_MS) {
        ESP_LOGW(TAG, "Sensor timeout");
        return HAL_ERR_TIMEOUT;
    }
    vTaskDelay(pdMS_TO_TICKS(1));
}

// 5. Watchdog — reset if main loop hangs
// Enable hardware watchdog and feed it in the main loop
```

## Concurrency Patterns Worth Knowing

```c
// Single-producer / single-consumer ring buffer (ISR -> task, or task -> task, no lock).
// Power-of-two size, free-running indices, release/acquire pairing.
#define RB_SIZE 64u                               // must be power of two
_Static_assert((RB_SIZE & (RB_SIZE - 1u)) == 0, "RB_SIZE must be power of two");

typedef struct {
    uint8_t buf[RB_SIZE];
    atomic_uint head;   // written only by producer
    atomic_uint tail;   // written only by consumer
} spsc_rb_t;

static inline bool rb_push(spsc_rb_t *rb, uint8_t b) {      // producer only
    unsigned h = atomic_load_explicit(&rb->head, memory_order_relaxed);
    unsigned t = atomic_load_explicit(&rb->tail, memory_order_acquire);
    if (h - t == RB_SIZE) return false;                     // full: count it, never overwrite silently
    rb->buf[h & (RB_SIZE - 1u)] = b;
    atomic_store_explicit(&rb->head, h + 1u, memory_order_release);
    return true;
}
```

This is correct only for exactly **one** producer and **one** consumer. Multiple producers → queue or mutex. On an RTOS, prefer the RTOS queue / stream buffer over hand-rolled lock-free code unless you have measured a need.

## Time, Integers and Overflow

```c
// Tick/time counters wrap. Compare with unsigned subtraction, never with `<` on absolute values.
if ((uint32_t)(now_ms - deadline_ms) < 0x80000000u) { /* deadline passed */ }
// 32-bit ms counter wraps after 49.7 days — test with the counter pre-set near UINT32_MAX.

// Integer promotion: uint8_t/uint16_t operands promote to int
uint16_t a = 0xFFFF;
uint32_t bad  = a << 16;            // UB-adjacent: a promotes to (signed) int, shift into sign bit
uint32_t good = (uint32_t)a << 16;

// Never shift by >= type width; never left-shift negative values; check size arithmetic
if (count > SIZE_MAX / elem_size) return ERR_INVALID;   // before count * elem_size
// Signed overflow is UB (compiler may delete your overflow check). Use unsigned or __builtin_*_overflow.
if (__builtin_add_overflow(a, b, &sum)) return ERR_OVERFLOW;
```

Persisted counters that provide **uniqueness or replay protection** (nonces, TX counters, OTA anti-rollback) must be monotonic across power loss: persist/reserve **before** use, and never let a restore/rollback path move them backwards. See `embedded-persistence`.

## DMA, Caches and Memory Regions

- DMA buffers must be in DMA-capable memory, correctly aligned, and not on the stack. On chips with a data cache (Cortex-M7, ESP32-S3/P4 with PSRAM, STM32H7) **cache-line align and size** the buffer and clean/invalidate (or use non-cacheable regions) around transfers — otherwise you get stale data or corrupted neighbours that only appear under load.
- Tightly-coupled/CCM RAM is often not DMA reachable. Check the reference manual bus matrix before placing buffers.
- Do not touch a DMA buffer from the CPU while the transfer owns it; hand ownership off explicitly (flag/semaphore/callback).
- Anything executed or read while flash is being written/erased must sit in RAM (`IRAM_ATTR` / `__attribute__((section(".ramfunc")))`).

## Build-Time Hardening

```
- Warnings as errors on your own code: -Wall -Wextra -Wshadow -Wconversion -Wformat=2 -Wundef -Werror
  (relax per third-party component, not globally)
- _Static_assert for struct sizes, enum ranges, array lengths and buffer-vs-protocol limits
- Static analysis in CI: clang-tidy / cppcheck, plus -fanalyzer where the toolchain supports it
- Format specifiers: PRIu32 / PRId64 / %zu — never %d for uint32_t or size_t
- Fixed `const` tables: mark `static const` so they stay in flash, not RAM
- Keep ISR-visible and cache-sensitive sections explicit with attributes, not implicit by luck
```

## Code Quality Rules

- Function length: max 50 lines — extract hardware initialization, state machines, and protocol parsers into separate functions
- One function, one responsibility: `init_i2c()` initializes I2C; it does not also configure sensor registers
- Naming: `sensor_read_temperature()` not `do_temp()` — names must be unambiguous on their own
- No magic numbers: `#define SENSOR_ADDR 0x48` not `i2c_read(0x48, ...)`
- Header guards on every `.h` file: `#ifndef MY_SENSOR_H` / `#define MY_SENSOR_H` / `#endif`
- Separate interface from implementation: `.h` declares the API, `.c` implements it — never put logic in headers

## Embedded C Checklist

```
Types:
- [ ] All integers use fixed-width types (uint8_t, int32_t etc.)
- [ ] No int/long/unsigned without explicit size
- [ ] Packed attribute on wire-protocol structs

Volatile / atomics:
- [ ] All hardware register accesses are volatile
- [ ] ISR-shared variables are volatile AND atomic (or lock-protected) when read-modify-write or multi-field
- [ ] No pointer to a packed-struct member; wire formats parsed explicitly, sizes `_Static_assert`ed
- [ ] Time comparisons wrap-safe; size arithmetic overflow-checked

Interrupts:
- [ ] IRAM-safe ISRs (`ESP_INTR_FLAG_IRAM`) and everything they touch live in IRAM/DRAM (ESP32)
- [ ] ISRs only signal tasks, do not do work
- [ ] ISR-safe API variants used (xQueueSendFromISR etc.)
- [ ] Critical sections protect multi-byte shared state

Memory:
- [ ] malloc return value checked
- [ ] Pointer nulled after free
- [ ] Stack usage measured with uxTaskGetStackHighWaterMark under worst-case paths
- [ ] DMA buffers aligned, DMA-capable, cache-maintained, not on the stack
- [ ] Large buffers static or heap, not stack-allocated

Error handling:
- [ ] Every fallible function returns error code
- [ ] Every error code checked at call site
- [ ] Timeout on every blocking wait
- [ ] Watchdog enabled and fed
```

## C++ in Embedded Systems

C++ is increasingly used in embedded, especially on Cortex-M and ESP32. Use it selectively — only the subset that doesn't cost RAM, flash, or predictability.

**Safe C++ features in embedded:**
```cpp
// Namespaces — zero runtime cost
namespace sensor {
    constexpr uint8_t ADDR = 0x48;
    constexpr uint16_t TIMEOUT_MS = 100;
}

// constexpr — evaluated at compile time, no runtime overhead
constexpr uint32_t ms_to_ticks(uint32_t ms, uint32_t tick_rate_hz) {
    return ms * tick_rate_hz / 1000;
}

// Scoped enums — type-safe, no implicit int conversion
enum class GpioMode : uint8_t { Input, Output, InputPullUp, InputPullDown };

// References — safer than pointers for non-nullable params
void process_frame(const UartFrame& frame);

// Templates for type-safe containers without virtual dispatch or heap
template<typename T, size_t N>
class RingBuffer {
    T buf_[N];
    size_t head_ = 0, tail_ = 0, count_ = 0;
public:
    bool push(const T& item) {
        if (count_ == N) return false;
        buf_[head_] = item;
        head_ = (head_ + 1) % N;
        ++count_;
        return true;
    }
    bool pop(T& out) {
        if (count_ == 0) return false;
        out = buf_[tail_];
        tail_ = (tail_ + 1) % N;
        --count_;
        return true;
    }
    size_t size() const { return count_; }
};
// No heap, no virtual, no exceptions — safe for embedded
RingBuffer<SensorReading, 32> readings;  // statically allocated
```

**Avoid in embedded C++:**
```cpp
// ✗ Exceptions — require unwinding tables, ~10KB flash overhead
try { read_sensor(); } catch (...) {}   // Never in embedded
// Disable: -fno-exceptions in CMakeLists

// ✗ RTTI (dynamic_cast, typeid) — adds overhead
// Disable: -fno-rtti in CMakeLists

// ✗ std::string — dynamic allocation, heap fragmentation
std::string name = "sensor";            // use const char* or char[N]

// ✗ new/delete on heap — fragmentation over time
Sensor *s = new TemperatureSensor();    // avoid

// ✓ Placement new for polymorphism without heap allocation
alignas(TemperatureSensor) static uint8_t buf[sizeof(TemperatureSensor)];
Sensor *s = new(buf) TemperatureSensor();   // no heap

// ✗ std::iostream — massive flash overhead (~200KB+)
std::cout << "debug";                   // never in embedded

// ✓ Safe STL: std::array, std::optional, std::variant (C++17)
#include <array>
std::array<uint8_t, 64> tx_buf{};      // stack allocated, size known at compile time
```

**CMakeLists flags for C++ embedded:**
```cmake
target_compile_options(${PROJECT_NAME} PRIVATE
    -fno-exceptions          # disable exception handling overhead
    -fno-rtti                # disable runtime type information
    -fno-threadsafe-statics  # avoid hidden mutex on local static init
    -Os                      # optimize for size (use -O2 for speed-critical)
    -std=c++17
)
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `int count` for loop variable | `uint16_t count` — explicit size |
| `*(uint16_t*)buf` for multi-byte read | Explicit shift + OR: `(buf[0] << 8) \| buf[1]` |
| `volatile` used as thread/ISR synchronization | `<stdatomic.h>`, critical section, or RTOS queue |
| `counter++` assumed atomic with an ISR | `atomic_fetch_add` or critical section |
| `assert(do_something())` | Never put side effects in asserts; they vanish in release |
| `now < deadline` on a wrapping tick counter | `(uint32_t)(now - deadline) < 0x80000000u` |
| Hand-rolled lock-free queue with 2+ producers | RTOS queue / mutex |
| Hardware register without `volatile` | `volatile uint32_t *reg = (volatile uint32_t*)ADDR` |
| `malloc()` without checking NULL | Always check: `if (!ptr) { return ERR_NO_MEM; }` |
| Blocking work inside ISR | Set flag / send to queue — work in main loop or task |
| Large array on task/function stack | `static` keyword or explicit heap allocation |
| `while(1)` with no timeout | Always bound blocking loops with timeout |
| `printf` in ISR | Set a flag, log from task context |
| Magic numbers in register access | Named `#define` or `constexpr` with datasheet reference |
| C++ exceptions in embedded | `-fno-exceptions` + return error codes |
| `std::string` in embedded | `const char*` or fixed `char[N]` |

## Connected Skills

- `esp-idf` — ESP32-family SDK patterns built on this C/C++ foundation
- `freertos` — FreeRTOS tasks, queues, semaphores, and synchronization (portable, not IDF-specific)
- `stm32-hal` — STM32 HAL driver patterns and CubeMX-generated project workflow
- `embedded-toolchain` — CMake cross-compilation, linker scripts, startup files, and GCC toolchain setup
- `embedded-persistence` — power-fail-safe storage, schemas, monotonic counters
- `embedded-connectivity` — MQTT, WiFi, CAN/ISO-TP and link-layer patterns for connected devices
- `embedded-testing` — host-side unit tests, fakes for RTOS/HAL, hardware-in-the-loop
- `embedded-debugging` — reset-cause triage, watchdog resets, coredumps, JTAG
- `debug-trace` — general debugging workflow (loop construction, hypothesis discipline)
