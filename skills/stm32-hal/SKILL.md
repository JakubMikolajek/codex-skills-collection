---
name: stm32-hal
description: STM32 firmware development patterns using STM32 HAL and LL drivers, CubeMX project generation, and CMake or STM32CubeIDE build setup. Covers GPIO, UART, I2C, SPI, ADC, DMA, interrupts, and low-power modes for STM32F4/F7/H7/G4/L4 families. Use when writing or reviewing STM32 firmware with HAL drivers. Always load alongside c-embedded and freertos when applicable.
---

# STM32 with HAL

STM32 is the dominant microcontroller family in commercial embedded. This skill covers HAL-based development — the recommended starting point for most projects — with notes on where LL (Low-Layer) drivers are preferable for performance.

## When to Use

- Writing firmware for any STM32 microcontroller (F0/F1/F4/F7/H7/G4/L4/WB)
- Reviewing STM32 HAL driver usage for correctness
- Adding peripherals to a CubeMX-generated project
- Debugging HAL timeout, DMA transfer, or interrupt issues

## When NOT to Use

- ESP32 — use `esp32-idf`
- RP2040 — different SDK (Pico SDK), different patterns
- AVR — different toolchain, avr-libc

## Project Setup

### CubeMX Workflow

CubeMX generates the peripheral initialization code. Your application code goes in the `USER CODE BEGIN/END` sections — this survives code re-generation.

```
project/
├── Core/
│   ├── Inc/
│   │   ├── main.h           # CubeMX generated
│   │   └── stm32f4xx_hal_conf.h
│   └── Src/
│       ├── main.c           # Add app code in USER CODE sections
│       ├── stm32f4xx_it.c   # ISR handlers — add your code here
│       └── stm32f4xx_hal_msp.c
├── Drivers/
│   ├── STM32F4xx_HAL_Driver/
│   └── CMSIS/
├── Middlewares/
│   └── Third_Party/FreeRTOS/  # if RTOS enabled in CubeMX
├── CMakeLists.txt              # or .ioc + CubeIDE project
└── STM32F407VGTx_FLASH.ld     # linker script (CubeMX generated)
```

### CMake with arm-none-eabi

```cmake
# CMakeLists.txt for STM32F4 project
cmake_minimum_required(VERSION 3.22)
project(my_firmware C CXX ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# MCU-specific flags — adjust for your part
set(CPU_FLAGS
    -mcpu=cortex-m4
    -mthumb
    -mfpu=fpv4-sp-d16
    -mfloat-abi=hard
)

add_compile_options(
    ${CPU_FLAGS}
    -ffunction-sections
    -fdata-sections
    -fno-exceptions      # C++ only
    -fno-rtti            # C++ only
    -Wall
    -Wextra
    -Os
)

add_link_options(
    ${CPU_FLAGS}
    -T${CMAKE_SOURCE_DIR}/STM32F407VGTx_FLASH.ld
    -Wl,--gc-sections
    -Wl,--print-memory-usage
    -specs=nano.specs    # newlib-nano: reduced printf/malloc
    -specs=nosys.specs   # no system calls (bare metal)
)

# Collect sources
file(GLOB_RECURSE SOURCES
    Core/Src/*.c
    Drivers/STM32F4xx_HAL_Driver/Src/*.c
)
# Exclude template files
list(FILTER SOURCES EXCLUDE REGEX ".*_template\\.c")

add_executable(${PROJECT_NAME}.elf ${SOURCES} startup_stm32f407vgtx.s)

target_include_directories(${PROJECT_NAME} PRIVATE
    Core/Inc
    Drivers/STM32F4xx_HAL_Driver/Inc
    Drivers/CMSIS/Device/ST/STM32F4xx/Include
    Drivers/CMSIS/Include
)

target_compile_definitions(${PROJECT_NAME} PRIVATE
    USE_HAL_DRIVER
    STM32F407xx
)

# Generate .bin and .hex
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ihex   $<TARGET_FILE:${PROJECT_NAME}.elf> ${PROJECT_NAME}.hex
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${PROJECT_NAME}.elf> ${PROJECT_NAME}.bin
    COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${PROJECT_NAME}.elf>
)
```

## GPIO

```c
// CubeMX generates MX_GPIO_Init() — call it from main
// In your code: use named aliases defined in main.h

// main.h (add your aliases in USER CODE section)
#define LED_GREEN_Pin    GPIO_PIN_12
#define LED_GREEN_GPIO_Port GPIOD
#define BUTTON_Pin       GPIO_PIN_0
#define BUTTON_GPIO_Port GPIOA

// Drive output
HAL_GPIO_WritePin(LED_GREEN_GPIO_Port, LED_GREEN_Pin, GPIO_PIN_SET);
HAL_GPIO_WritePin(LED_GREEN_GPIO_Port, LED_GREEN_Pin, GPIO_PIN_RESET);
HAL_GPIO_TogglePin(LED_GREEN_GPIO_Port, LED_GREEN_Pin);

// Read input
GPIO_PinState state = HAL_GPIO_ReadPin(BUTTON_GPIO_Port, BUTTON_Pin);

// External interrupt callback (override weak symbol in stm32f4xx_it.c or main.c)
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin) {
    if (GPIO_Pin == BUTTON_Pin) {
        // Handle button press — keep short, signal task
        BaseType_t woken = pdFALSE;
        xSemaphoreGiveFromISR(button_sem, &woken);
        portYIELD_FROM_ISR(woken);
    }
}
```

## UART

```c
// Blocking (polling) — simple, for init/debug only
uint8_t tx_buf[] = "Hello\r\n";
HAL_UART_Transmit(&huart2, tx_buf, sizeof(tx_buf) - 1, HAL_MAX_DELAY);

uint8_t rx_byte;
HAL_UART_Receive(&huart2, &rx_byte, 1, 100);  // 100ms timeout

// Interrupt-driven receive (preferred for real data)
// In CubeMX: enable UART global interrupt
uint8_t rx_buf[256];
HAL_UART_Receive_IT(&huart2, rx_buf, sizeof(rx_buf));

// Callback when receive complete (override weak symbol)
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart) {
    if (huart->Instance == USART2) {
        // Process rx_buf — signal processing task
        xQueueSendFromISR(uart_queue, rx_buf, NULL);
        // Restart receive for next packet
        HAL_UART_Receive_IT(&huart2, rx_buf, sizeof(rx_buf));
    }
}

// DMA receive with idle line detection (best for variable-length packets)
// In CubeMX: enable DMA for UART RX, enable UART global interrupt
HAL_UARTEx_ReceiveToIdle_DMA(&huart2, rx_buf, sizeof(rx_buf));
__HAL_DMA_DISABLE_IT(&hdma_usart2_rx, DMA_IT_HT);  // disable half-transfer interrupt

void HAL_UARTEx_RxEventCallback(UART_HandleTypeDef *huart, uint16_t Size) {
    if (huart->Instance == USART2) {
        // Size = actual bytes received (idle line detected)
        process_packet(rx_buf, Size);
        HAL_UARTEx_ReceiveToIdle_DMA(&huart2, rx_buf, sizeof(rx_buf));
        __HAL_DMA_DISABLE_IT(&hdma_usart2_rx, DMA_IT_HT);
    }
}
```

## I2C

```c
// Write register
uint8_t buf[2] = { reg_addr, value };
HAL_StatusTypeDef status = HAL_I2C_Master_Transmit(
    &hi2c1,
    dev_addr << 1,   // HAL expects 8-bit address (7-bit shifted left)
    buf, 2,
    HAL_MAX_DELAY
);
if (status != HAL_OK) {
    // HAL_ERROR or HAL_TIMEOUT — handle accordingly
    return HAL_ERR_COMM;
}

// Read register (write address, then read data)
uint8_t reg = REG_TEMP;
uint8_t data[2];
HAL_I2C_Master_Transmit(&hi2c1, dev_addr << 1, &reg, 1, 100);
HAL_I2C_Master_Receive(&hi2c1, (dev_addr << 1) | 0x01, data, 2, 100);

// Or use Mem functions (simpler for register-based sensors)
HAL_I2C_Mem_Read(&hi2c1, dev_addr << 1, REG_TEMP, I2C_MEMADD_SIZE_8BIT, data, 2, 100);
HAL_I2C_Mem_Write(&hi2c1, dev_addr << 1, REG_CONFIG, I2C_MEMADD_SIZE_8BIT, &cfg, 1, 100);
```

## SPI

```c
// Assert CS manually (HAL does not manage CS automatically for most drivers)
HAL_GPIO_WritePin(SPI_CS_GPIO_Port, SPI_CS_Pin, GPIO_PIN_RESET);  // CS low = active

uint8_t tx_data[4] = { CMD_READ, reg_addr, 0x00, 0x00 };
uint8_t rx_data[4] = { 0 };
HAL_SPI_TransmitReceive(&hspi1, tx_data, rx_data, 4, 100);

HAL_GPIO_WritePin(SPI_CS_GPIO_Port, SPI_CS_Pin, GPIO_PIN_SET);   // CS high = deassert

// DMA SPI for high-throughput (display, audio, large transfers)
HAL_SPI_Transmit_DMA(&hspi1, frame_buf, FRAME_SIZE);
// Callback when complete:
void HAL_SPI_TxCpltCallback(SPI_HandleTypeDef *hspi) {
    if (hspi->Instance == SPI1) {
        // Transfer complete — update display or start next transfer
    }
}
```

## ADC

```c
// Single conversion (polling)
HAL_ADC_Start(&hadc1);
if (HAL_ADC_PollForConversion(&hadc1, 10) == HAL_OK) {
    uint32_t raw = HAL_ADC_GetValue(&hadc1);
    float voltage = (raw * 3.3f) / 4095.0f;  // for 12-bit ADC, 3.3V ref
}
HAL_ADC_Stop(&hadc1);

// Continuous DMA (best for multi-channel or high-rate sampling)
// In CubeMX: enable continuous mode, DMA, scan mode for multi-channel
uint16_t adc_buf[ADC_CHANNELS * SAMPLES_PER_CHANNEL];
HAL_ADC_Start_DMA(&hadc1, (uint32_t *)adc_buf, sizeof(adc_buf) / sizeof(uint16_t));

void HAL_ADC_ConvCpltCallback(ADC_HandleTypeDef *hadc) {
    // Full buffer ready — process or double-buffer
    process_adc_buffer(adc_buf, sizeof(adc_buf));
}

void HAL_ADC_ConvHalfCpltCallback(ADC_HandleTypeDef *hadc) {
    // Half buffer ready — for double-buffering to avoid gaps
    process_adc_buffer(adc_buf, sizeof(adc_buf) / 2);
}
```

## HAL Error Handling

HAL functions return `HAL_StatusTypeDef`: `HAL_OK`, `HAL_ERROR`, `HAL_BUSY`, `HAL_TIMEOUT`.

```c
// Always check return values — never assume success
HAL_StatusTypeDef status = HAL_I2C_Mem_Read(&hi2c1, addr, reg, 1, data, len, 100);
switch (status) {
    case HAL_OK:      break;
    case HAL_TIMEOUT: log_error("I2C timeout"); return ERR_TIMEOUT;
    case HAL_BUSY:    log_error("I2C busy");    return ERR_BUSY;
    case HAL_ERROR:
        // Check HAL error code for more detail
        if (hi2c1.ErrorCode & HAL_I2C_ERROR_AF) {
            log_error("I2C NACK — device not responding at addr 0x%02X", addr >> 1);
            return ERR_NO_DEVICE;
        }
        return ERR_COMM;
}

// Recover from stuck I2C bus (common after power glitch or incomplete transfer)
void i2c_recover_bus(I2C_HandleTypeDef *hi2c) {
    HAL_I2C_DeInit(hi2c);
    // Toggle SCL 9 times to release stuck slave
    for (int i = 0; i < 9; i++) {
        HAL_GPIO_WritePin(I2C_SCL_GPIO_Port, I2C_SCL_Pin, GPIO_PIN_SET);
        HAL_Delay(1);
        HAL_GPIO_WritePin(I2C_SCL_GPIO_Port, I2C_SCL_Pin, GPIO_PIN_RESET);
        HAL_Delay(1);
    }
    HAL_I2C_Init(hi2c);
}
```

## Low-Power Modes

```c
#include "stm32f4xx_hal.h"

// Sleep mode — CPU stopped, peripherals running
// Woken by any interrupt
HAL_PWR_EnterSLEEPMode(PWR_MAINREGULATOR_ON, PWR_SLEEPENTRY_WFI);

// Stop mode — CPU + most clocks stopped, RAM retained
// Woken by EXTI line or RTC alarm
// Re-initialize clocks after wakeup
HAL_PWR_EnterSTOPMode(PWR_LOWPOWERREGULATOR_ON, PWR_STOPENTRY_WFI);
// After wakeup — reinitialize system clock (HSI used after stop, not HSE/PLL)
SystemClock_Config();   // CubeMX generated

// Standby mode — lowest power, only VBAT domain retained
// Woken by WKUP pin or RTC
// Full reset on wakeup — RAM lost
HAL_PWR_EnterSTANDBYMode();
```

## STM32 HAL Checklist

```
Project:
- [ ] CubeMX .ioc file committed (source of truth for peripheral config)
- [ ] Application code in USER CODE sections only
- [ ] CMakeLists.txt or CubeIDE project checked in

Peripherals:
- [ ] HAL return values checked on every call
- [ ] I2C/SPI addresses verified (7-bit vs 8-bit shift)
- [ ] DMA used for UART receive with idle line detection
- [ ] SPI CS managed manually (GPIO, not NSS in most cases)

Interrupts:
- [ ] Callback functions override weak symbols
- [ ] ISR-safe FreeRTOS APIs used in callbacks
- [ ] NVIC priorities set: FreeRTOS-managed ISRs ≤ configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY

Error handling:
- [ ] I2C bus recovery procedure for NACK / stuck bus
- [ ] HAL_ERROR case handled (not just HAL_TIMEOUT)
- [ ] Timeout set on all blocking HAL calls (not HAL_MAX_DELAY in production)
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Magic I2C address `0x90` | Document: `0x48 << 1 = 0x90` — comment the 7-bit address |
| `HAL_MAX_DELAY` in production | Set explicit timeout + handle `HAL_TIMEOUT` |
| Ignoring HAL return value | Always check `if (status != HAL_OK)` |
| Blocking UART receive in production | DMA + idle line detection + callback |
| Modifying CubeMX-generated code outside USER CODE | Regeneration will overwrite it |
| Missing `SystemClock_Config()` after STOP mode wakeup | Clock must be reconfigured |
| FreeRTOS syscall from ISR with higher priority than `configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY` | Set NVIC priority correctly |

## Connected Skills

- `c-embedded` — always load for C/C++ language patterns
- `freertos` — FreeRTOS patterns when RTOS is enabled in CubeMX
- `embedded-toolchain` — CMake toolchain file, flashing with OpenOCD/ST-Link
- `debug-trace` — JTAG/SWD debugging with OpenOCD + GDB, STM32CubeMonitor
