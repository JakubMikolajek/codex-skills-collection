---
name: freertos
description: FreeRTOS implementation patterns for commercial embedded systems. Covers task design, queues, semaphores, mutexes, event groups, software timers, memory management, and stack sizing. Portable patterns applicable to any FreeRTOS port (STM32, ESP32, RP2040, AVR, or bare-metal Cortex-M). Always load alongside c-embedded for language-level patterns.
---

# FreeRTOS

FreeRTOS is the most widely deployed RTOS in commercial embedded. This skill covers using it correctly — task boundaries, synchronization primitives, memory discipline, and common failure modes.

## When to Use

- Designing task architecture for a new embedded system
- Reviewing FreeRTOS code for correctness (deadlock, priority inversion, stack overflow)
- Adding FreeRTOS to a bare-metal project
- Any task involving queues, semaphores, mutexes, or event groups
- Debugging a system that locks up, has priority inversion, or experiences stack overflow

## When NOT to Use

- ESP32-specific IDF patterns (`xTaskCreatePinnedToCore`, `IRAM_ATTR`, `portMUX`) — see `esp32-idf`
- Bare metal without RTOS — see `c-embedded` for bare-metal patterns
- Linux POSIX threads — different API despite similar concepts

## Core Principle

**Every FreeRTOS object consumes RAM.** Queues, tasks, semaphores — all are statically allocated or taken from the heap at creation time. In a system with 64KB SRAM, a misconfigured task stack or oversized queue is the difference between a working device and a reset loop.

## Task Design

### Anatomy of a Well-Designed Task

```c
#include "FreeRTOS.h"
#include "task.h"

// Task parameters — prefer a config struct over void* casting
typedef struct {
    uint8_t  sensor_addr;
    uint16_t sample_rate_hz;
    QueueHandle_t output_queue;
} sensor_task_cfg_t;

static void sensor_task(void *pvParameters) {
    const sensor_task_cfg_t *cfg = (sensor_task_cfg_t *)pvParameters;
    TickType_t last_wake = xTaskGetTickCount();
    const TickType_t period = pdMS_TO_TICKS(1000 / cfg->sample_rate_hz);

    while (1) {
        // Fixed-rate: vTaskDelayUntil accounts for task run time
        // Use vTaskDelay only when exact period doesn't matter
        vTaskDelayUntil(&last_wake, period);

        int16_t reading;
        if (sensor_read(cfg->sensor_addr, &reading) == HAL_OK) {
            measurement_t m = { .value = reading, .tick = xTaskGetTickCount() };
            // Non-blocking send — log if full, don't block the sampling task
            if (xQueueSend(cfg->output_queue, &m, 0) != pdTRUE) {
                // Queue full — consumer is too slow
            }
        }
    }
    // Unreachable — tasks must not return. If exit needed: vTaskDelete(NULL)
}

// Task creation — check return value
TaskHandle_t sensor_handle = NULL;
BaseType_t result = xTaskCreate(
    sensor_task,
    "sensor",                   // name visible in debugger / task list
    256,                        // stack depth in WORDS (not bytes) on most ports
                                // ESP32: bytes. Check portSTACK_TYPE size.
    (void *)&sensor_cfg,        // parameters
    5,                          // priority (higher number = higher priority)
    &sensor_handle
);
configASSERT(result == pdPASS); // fail loudly if creation fails
```

### Stack Sizing

The most common FreeRTOS bug is stack overflow — and it is often silent (corrupt memory, not a clean crash).

```c
// During development: measure high-water mark regularly
void stack_monitor_task(void *pv) {
    while (1) {
        vTaskDelay(pdMS_TO_TICKS(10000));
        // Print remaining stack space (in words) for all tasks
        TaskHandle_t tasks[] = { sensor_handle, comms_handle, ui_handle };
        const char *names[] = { "sensor", "comms", "ui" };
        for (int i = 0; i < 3; i++) {
            UBaseType_t wm = uxTaskGetStackHighWaterMark(tasks[i]);
            // If watermark < 20 words: increase stack
            // If watermark > 100 words consistently: reduce stack
        }
    }
}

// Enable stack overflow detection in FreeRTOSConfig.h:
// #define configCHECK_FOR_STACK_OVERFLOW 2  (pattern-check method)
// Implement the hook:
void vApplicationStackOverflowHook(TaskHandle_t task, char *name) {
    // Called when overflow detected — only useful if you reach it
    // Often the system is already corrupt by this point
    // Minimum: log and reset
    (void)task;
    NVIC_SystemReset();  // Cortex-M reset
}
```

Stack sizing guidelines:
- Start with 256 words (1KB on 32-bit) for simple tasks
- Tasks that call `printf`, `sprintf`, or nested functions: 512+ words
- Tasks that use floating point: add 64 words for FPU save area
- Tasks that call complex libraries (JSON parsing, crypto): 1024+ words
- Measure with `uxTaskGetStackHighWaterMark` — do not guess

### Priority Assignment

```c
// Priority scheme — define named priorities in your project
// Never scatter magic numbers through code
#define PRIORITY_IDLE       0   // FreeRTOS idle task
#define PRIORITY_LOW        1   // logging, monitoring
#define PRIORITY_NORMAL     3   // application logic, UI updates
#define PRIORITY_HIGH       5   // sensor sampling, comms processing
#define PRIORITY_REALTIME   7   // motor control, safety-critical
// Leave headroom below configMAX_PRIORITIES (usually 10 or 32)
```

Priority inversion risk: if a low-priority task holds a mutex needed by a high-priority task, and a medium-priority task preempts the low-priority task, the high-priority task is blocked indefinitely. Use **priority inheritance mutexes** (`xSemaphoreCreateMutex`) — FreeRTOS raises the low-priority holder's priority temporarily.

## Queues

Queues are the primary communication mechanism between tasks and ISRs.

```c
#include "queue.h"

// Create queue at startup — never create in a task (timing unpredictable)
QueueHandle_t sensor_queue = xQueueCreate(
    16,                      // depth: number of items
    sizeof(measurement_t)    // item size: queue copies by value
);
configASSERT(sensor_queue != NULL);

// Producer (task context)
measurement_t m = { .value = 2340, .tick = xTaskGetTickCount() };
if (xQueueSend(sensor_queue, &m, pdMS_TO_TICKS(10)) != pdTRUE) {
    // Timed out — queue full. Handle: drop, log, or block longer
}

// Producer (ISR context) — must use FromISR variant
BaseType_t higher_prio_woken = pdFALSE;
xQueueSendFromISR(sensor_queue, &m, &higher_prio_woken);
portYIELD_FROM_ISR(higher_prio_woken);  // yield if consumer unblocked

// Consumer (blocking — waits for data)
measurement_t received;
if (xQueueReceive(sensor_queue, &received, portMAX_DELAY) == pdTRUE) {
    process_measurement(&received);
}

// Peek without removing (check if data available)
if (xQueuePeek(sensor_queue, &received, 0) == pdTRUE) {
    // Data available, not consumed
}
```

Queue depth sizing:
- Too shallow: producers block or drop data, causing jitter
- Too deep: wastes RAM (depth × item_size bytes always allocated)
- Rule of thumb: 2–4× the burst rate of the fastest producer

## Semaphores and Mutexes

```c
#include "semphr.h"

// Binary semaphore — signaling (ISR → task, one-shot event)
SemaphoreHandle_t data_ready_sem = xSemaphoreCreateBinary();

// ISR signals task
void adc_isr(void) {
    BaseType_t woken = pdFALSE;
    xSemaphoreGiveFromISR(data_ready_sem, &woken);
    portYIELD_FROM_ISR(woken);
}

// Task waits for signal
void processing_task(void *pv) {
    while (1) {
        xSemaphoreTake(data_ready_sem, portMAX_DELAY);
        process_adc_data();
    }
}

// Counting semaphore — resource pool or event counter
SemaphoreHandle_t conn_pool = xSemaphoreCreateCounting(MAX_CONNECTIONS, MAX_CONNECTIONS);
xSemaphoreTake(conn_pool, portMAX_DELAY);  // acquire a connection slot
// ... use connection ...
xSemaphoreGive(conn_pool);                 // release back to pool

// Mutex — shared resource protection (with priority inheritance)
SemaphoreHandle_t spi_mutex = xSemaphoreCreateMutex();

void use_spi(void) {
    if (xSemaphoreTake(spi_mutex, pdMS_TO_TICKS(100)) == pdTRUE) {
        // Protected SPI access
        spi_transfer(data, len);
        xSemaphoreGive(spi_mutex);
    } else {
        // Timed out — log and handle (do not proceed without mutex)
    }
}

// NEVER use mutex from ISR — use binary semaphore instead
// NEVER call xSemaphoreTake twice from the same task (deadlock)
```

**Mutex vs Binary Semaphore:**
- Mutex: shared resource protection between tasks. Has priority inheritance. Must be given by the same task that took it.
- Binary semaphore: signaling. Can be given from ISR. No priority inheritance. Giver and taker can be different tasks.

## Event Groups

Use when a task needs to wait for multiple conditions simultaneously:

```c
#include "event_groups.h"

EventGroupHandle_t system_events = xEventGroupCreate();

// Define bits
#define EVENT_WIFI_CONNECTED   BIT0
#define EVENT_MQTT_CONNECTED   BIT1
#define EVENT_SENSOR_READY     BIT2
#define EVENT_ALL_READY        (EVENT_WIFI_CONNECTED | EVENT_MQTT_CONNECTED | EVENT_SENSOR_READY)

// Set bit from any task or ISR
xEventGroupSetBits(system_events, EVENT_WIFI_CONNECTED);

// Wait for ALL bits (logical AND)
EventBits_t bits = xEventGroupWaitBits(
    system_events,
    EVENT_ALL_READY,
    pdTRUE,               // clear bits on exit
    pdTRUE,               // wait for ALL (pdFALSE = wait for ANY)
    pdMS_TO_TICKS(30000)  // timeout
);
if ((bits & EVENT_ALL_READY) == EVENT_ALL_READY) {
    start_telemetry();
}
```

## Software Timers

```c
#include "timers.h"

// One-shot timer — fires once
TimerHandle_t watchdog_timer = xTimerCreate(
    "wdog",
    pdMS_TO_TICKS(5000),  // period
    pdFALSE,              // auto-reload: pdFALSE = one-shot, pdTRUE = periodic
    NULL,                 // timer ID (passed to callback)
    watchdog_callback     // callback function
);

// Periodic timer
TimerHandle_t heartbeat = xTimerCreate("hb", pdMS_TO_TICKS(1000), pdTRUE, NULL, hb_cb);
xTimerStart(heartbeat, 0);

// Timer callback — runs in timer daemon task context
// Keep short: no blocking, no long computation
void watchdog_callback(TimerHandle_t xTimer) {
    // Timeout — connection lost or sensor hung
    ESP_LOGE(TAG, "Watchdog expired — resetting");
    esp_restart();
}

// Reset timer from task (e.g., on successful heartbeat)
xTimerReset(watchdog_timer, 0);
```

Software timer callbacks run in a shared timer daemon task. Never block in a callback — this blocks ALL software timers. For anything non-trivial, signal a task from the callback.

## Memory Management

FreeRTOS provides five heap implementations. Choose based on requirements:

| Scheme | Description | Use when |
|---|---|---|
| `heap_1` | Never frees — simple static allocation | Fixed task set, no dynamic creation |
| `heap_2` | Frees but no coalescence — fragmentation over time | Dynamic tasks with similar sizes |
| `heap_3` | Wraps standard malloc/free | When libc malloc is available and acceptable |
| `heap_4` | Frees + coalescence — general purpose | **Default choice for most projects** |
| `heap_5` | heap_4 across multiple non-contiguous memory regions | MCUs with internal + external RAM |

```c
// In FreeRTOSConfig.h
#define configTOTAL_HEAP_SIZE ((size_t)(32 * 1024))  // 32KB for FreeRTOS heap

// Monitor heap usage during development
size_t free_heap = xPortGetFreeHeapSize();
size_t min_ever  = xPortGetMinimumEverFreeHeapSize();  // lowest watermark since boot
```

Static allocation (safest — no heap, no fragmentation):
```c
// Define storage statically
static StaticTask_t sensor_task_tcb;
static StackType_t  sensor_task_stack[256];

// Create with static buffers (no heap used)
sensor_handle = xTaskCreateStatic(
    sensor_task, "sensor", 256, &cfg,
    PRIORITY_HIGH, sensor_task_stack, &sensor_task_tcb
);
```

Enable static allocation in `FreeRTOSConfig.h`:
```c
#define configSUPPORT_STATIC_ALLOCATION  1
#define configSUPPORT_DYNAMIC_ALLOCATION 1
```

## FreeRTOS Checklist

```
Tasks:
- [ ] vTaskDelayUntil used for fixed-rate tasks (not vTaskDelay)
- [ ] Stack depth measured with uxTaskGetStackHighWaterMark
- [ ] configCHECK_FOR_STACK_OVERFLOW 2 enabled during development
- [ ] xTaskCreate return value checked with configASSERT
- [ ] Named priorities defined as constants (not magic numbers)

Queues:
- [ ] Created at startup (not inside tasks)
- [ ] xQueueCreate return value checked
- [ ] FromISR variants used in ISR context
- [ ] portYIELD_FROM_ISR called after FromISR operations

Synchronization:
- [ ] Mutex used for shared resource (not binary semaphore)
- [ ] Binary semaphore used for signaling ISR → task
- [ ] Timeout set on all xSemaphoreTake calls (not portMAX_DELAY in production)
- [ ] Mutex never taken from ISR

Timers:
- [ ] Timer callbacks are short and non-blocking
- [ ] Work delegated to task from callback

Memory:
- [ ] xPortGetMinimumEverFreeHeapSize monitored during dev
- [ ] Static allocation used for safety-critical tasks
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `vTaskDelay(100)` in fixed-rate task | `vTaskDelayUntil` — compensates for task run time |
| Mutex from ISR context | Binary semaphore for ISR signaling |
| `xSemaphoreTake` with `portMAX_DELAY` in production | Set timeout + handle failure |
| Calling `printf` / `malloc` from ISR | Signal task — work done outside ISR |
| Guessing task stack sizes with no runtime checks | Measure `uxTaskGetStackHighWaterMark` and tune with margin |
| Sharing mutable task data without mutex/queue/event synchronization | Use FreeRTOS primitives to protect ownership and ordering |
| Creating queue inside a task | Create all objects at startup (e.g. in main before scheduler) |
| No `configASSERT` on object creation | Assert immediately — fail loudly |
| Magic priority numbers in xTaskCreate | Named constants: `PRIORITY_HIGH` |
| Blocking in timer callback | Signal a task from callback |

## Connected Skills

- `c-embedded` — always load for C/C++ language patterns
- `esp32-idf` — ESP32-specific FreeRTOS extensions (pinned tasks, portMUX, IRAM_ATTR)
- `stm32-hal` — STM32 + FreeRTOS integration patterns (CubeMX generated FreeRTOS config)
- `debug-trace` — FreeRTOS task list dump, stack overflow debugging
