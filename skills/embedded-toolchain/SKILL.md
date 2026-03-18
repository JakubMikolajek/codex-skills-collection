---
name: embedded-toolchain
description: Embedded build system patterns using CMake and GCC cross-compilation toolchain. Covers arm-none-eabi and riscv toolchain setup, CMake cross-compilation configuration, linker scripts, startup files, memory maps, and flashing with OpenOCD. Use when setting up a new embedded project from scratch, reviewing build configuration, or debugging linker errors and memory issues.
---

# Embedded Toolchain (CMake + GCC)

This skill covers the build layer underneath the SDK — the toolchain file, linker script, startup code, and CMake structure that turns C/C++ source into a binary that runs on bare metal.

## When to Use

- Setting up a new embedded project with CMake (not CubeIDE or Arduino)
- Debugging linker errors (`undefined reference`, `region overflow`, `multiple definition`)
- Understanding the memory map of a firmware binary
- Adding a new source file, library, or component to the build
- Configuring flashing and debugging with OpenOCD

## When NOT to Use

- ESP-IDF projects — IDF has its own CMake integration (`idf_component_register`), see `esp32-idf`
- Arduino IDE projects — different build system entirely
- CubeIDE-managed projects — use CMakeLists only if you explicitly export from CubeIDE

## Toolchain Setup

### arm-none-eabi (Cortex-M: STM32, RP2040, etc.)

```bash
# Install on Ubuntu/Debian
sudo apt install gcc-arm-none-eabi binutils-arm-none-eabi

# Or download from ARM developer site (latest):
# https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
# Extract and add to PATH

# Verify
arm-none-eabi-gcc --version
```

### RISC-V (ESP32-C3/C6, RP2350 RISC-V core)

```bash
# ESP32-C3/C6 — use IDF toolchain manager
idf.py --version  # IDF installs the correct riscv toolchain automatically

# Standalone RISC-V (RP2350)
# Pico SDK handles toolchain — use SDK's CMake integration
```

## Toolchain File

The toolchain file tells CMake to cross-compile instead of using the host compiler:

```cmake
# toolchain-arm-cortex-m4.cmake
# Usage: cmake -B build -DCMAKE_TOOLCHAIN_FILE=toolchain-arm-cortex-m4.cmake

set(CMAKE_SYSTEM_NAME      Generic)    # bare metal, no OS
set(CMAKE_SYSTEM_PROCESSOR arm)

# Toolchain binaries (adjust path if not in PATH)
set(CMAKE_C_COMPILER       arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER     arm-none-eabi-g++)
set(CMAKE_ASM_COMPILER     arm-none-eabi-gcc)
set(CMAKE_AR               arm-none-eabi-ar)
set(CMAKE_OBJCOPY          arm-none-eabi-objcopy)
set(CMAKE_OBJDUMP          arm-none-eabi-objdump)
set(CMAKE_SIZE             arm-none-eabi-size)

# Prevent CMake from testing the compiler by trying to link an executable
# (can't run ARM binary on host)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# MCU-specific flags — customize per target
# Cortex-M4F (STM32F4, STM32F7 at M4 mode)
set(MCU_FLAGS "-mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard")

# Cortex-M3 (STM32F1, STM32L1)
# set(MCU_FLAGS "-mcpu=cortex-m3 -mthumb")

# Cortex-M0+ (STM32G0, STM32L0, RP2040)
# set(MCU_FLAGS "-mcpu=cortex-m0plus -mthumb")

# Cortex-M7 (STM32H7, STM32F7)
# set(MCU_FLAGS "-mcpu=cortex-m7 -mthumb -mfpu=fpv5-d16 -mfloat-abi=hard")

set(CMAKE_C_FLAGS_INIT   "${MCU_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${MCU_FLAGS}")
set(CMAKE_ASM_FLAGS_INIT "${MCU_FLAGS} -x assembler-with-cpp")
set(CMAKE_EXE_LINKER_FLAGS_INIT "${MCU_FLAGS}")
```

## Project CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.22)
project(my_firmware C CXX ASM)

# Language standards
set(CMAKE_C_STANDARD   11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Compile options (apply to all targets)
add_compile_options(
    # Code generation
    -ffunction-sections     # place each function in its own section → linker can GC unused
    -fdata-sections         # same for data
    -fno-common             # prevent tentative definitions (safer)

    # C++ specific (add only for C++ targets)
    $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>
    $<$<COMPILE_LANGUAGE:CXX>:-fno-rtti>
    $<$<COMPILE_LANGUAGE:CXX>:-fno-threadsafe-statics>

    # Optimization (use -Og for debug: optimize but keep debug info)
    $<$<CONFIG:Debug>:-Og -g3 -DDEBUG>
    $<$<CONFIG:Release>:-Os -DNDEBUG>

    # Warnings
    -Wall -Wextra
    -Wno-unused-parameter   # common in HAL callback overrides
)

# Linker options
add_link_options(
    -T${CMAKE_SOURCE_DIR}/STM32F407VGTx_FLASH.ld
    -Wl,--gc-sections           # remove unused sections
    -Wl,--print-memory-usage    # show flash/RAM usage after linking
    -Wl,-Map=${PROJECT_NAME}.map  # generate memory map file
    -specs=nano.specs           # newlib-nano: smaller printf, reduced malloc
    -specs=nosys.specs          # stub out system calls (no OS)
    -lc -lm -lnosys             # link C library, math, no-OS stubs
)

# Sources
file(GLOB_RECURSE APP_SOURCES
    Core/Src/*.c
    Core/Src/*.cpp
)
file(GLOB_RECURSE HAL_SOURCES
    Drivers/STM32F4xx_HAL_Driver/Src/*.c
)
list(FILTER HAL_SOURCES EXCLUDE REGEX ".*_template\\.c$")

# Startup file (assembler)
set(STARTUP_FILE startup_stm32f407vgtx.s)

add_executable(${PROJECT_NAME}.elf
    ${APP_SOURCES}
    ${HAL_SOURCES}
    ${STARTUP_FILE}
)

target_include_directories(${PROJECT_NAME}.elf PRIVATE
    Core/Inc
    Drivers/STM32F4xx_HAL_Driver/Inc
    Drivers/STM32F4xx_HAL_Driver/Inc/Legacy
    Drivers/CMSIS/Device/ST/STM32F4xx/Include
    Drivers/CMSIS/Include
)

target_compile_definitions(${PROJECT_NAME}.elf PRIVATE
    USE_HAL_DRIVER
    STM32F407xx
)

# Post-build: generate .hex and .bin, print size
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ihex   ${PROJECT_NAME}.elf ${PROJECT_NAME}.hex
    COMMAND ${CMAKE_OBJCOPY} -O binary ${PROJECT_NAME}.elf ${PROJECT_NAME}.bin
    COMMAND ${CMAKE_SIZE} --format=berkeley ${PROJECT_NAME}.elf
    COMMENT "Building ${PROJECT_NAME}.hex and .bin"
)
```

## Linker Script

The linker script defines the memory layout. CubeMX generates one — understand it before modifying.

```ld
/* STM32F407VGTx_FLASH.ld — example, generated by CubeMX */

ENTRY(Reset_Handler)   /* entry point = reset ISR */

/* Memory regions — match your specific MCU's datasheet */
MEMORY {
    CCMRAM (xrw) : ORIGIN = 0x10000000, LENGTH = 64K   /* Core Coupled Memory — CPU only, no DMA */
    RAM    (xrw) : ORIGIN = 0x20000000, LENGTH = 128K
    FLASH  (rx)  : ORIGIN = 0x08000000, LENGTH = 1024K
}

SECTIONS {
    /* Vector table and code → FLASH */
    .isr_vector : { KEEP(*(.isr_vector)) } >FLASH

    .text : {
        *(.text)
        *(.text*)
        *(.rodata)
        *(.rodata*)
        _etext = .;    /* end of text — used by startup to copy .data */
    } >FLASH

    /* Initialized data → copied from FLASH to RAM at startup */
    .data : {
        _sdata = .;
        *(.data)
        *(.data*)
        _edata = .;
    } >RAM AT>FLASH      /* AT>FLASH = load address in flash, VMA in RAM */

    /* Zero-initialized data → zeroed by startup */
    .bss : {
        _sbss = .;
        *(.bss)
        *(.bss*)
        *(COMMON)
        _ebss = .;
    } >RAM

    /* Stack and heap — define sizes in startup or here */
    ._user_heap_stack : {
        . = ALIGN(8);
        PROVIDE(end = .);        /* heap start (used by newlib malloc) */
        . = . + _Min_Heap_Size;
        . = . + _Min_Stack_Size;
        . = ALIGN(8);
    } >RAM
}
```

Key linker symbols (`_sdata`, `_edata`, `_sbss`, `_ebss`) are referenced by the startup file to initialize RAM at reset.

## Startup File

The startup file runs before `main()`. It initializes the C runtime:

```c
/* startup_stm32f407vgtx.s — key sections (generated by CubeMX, shown simplified) */

/* Vector table — first 512 bytes of flash on Cortex-M */
/* Position 0: initial stack pointer
   Position 1: Reset_Handler address
   Positions 2+: exception and IRQ handlers */

/* Reset_Handler: */
/* 1. Copy .data section from FLASH to RAM */
/* 2. Zero-initialize .bss section */
/* 3. Call SystemInit() — sets up clocks */
/* 4. Call main() */
```

You typically do not modify the startup file. If you need to run code before `main()`:
```c
// Use __attribute__((constructor)) — runs after startup, before main
__attribute__((constructor))
void early_init(void) {
    // Runs after C runtime init, before main
}

// Or use CubeMX's HAL_MspInit (peripheral low-level init hook)
```

## Memory Map Analysis

After building, analyze the `.map` file or use `arm-none-eabi-size`:

```bash
# Summary: text (flash), data (initialized), bss (zero-init)
arm-none-eabi-size --format=berkeley build/my_firmware.elf
#    text    data     bss     dec     hex filename
#   45312    1024    8192   54528    d500 my_firmware.elf
# Flash used = text + data = 46336 bytes
# RAM used   = data + bss  = 9216 bytes (+ stack)

# Detailed breakdown by section and object
arm-none-eabi-nm --size-sort --print-size build/my_firmware.elf | tail -20

# Find what's eating flash
arm-none-eabi-objdump -h build/my_firmware.elf

# Interactive size visualization
python3 -m pip install bloaty
# or: https://github.com/google/bloaty
```

## Flashing and Debugging

### OpenOCD + GDB

```bash
# openocd.cfg — adjust for your programmer
source [find interface/stlink.cfg]
source [find target/stm32f4x.cfg]
# For J-Link: source [find interface/jlink.cfg]

# Flash
openocd -f openocd.cfg \
  -c "program build/my_firmware.elf verify reset exit"

# Debug (start OpenOCD as GDB server)
openocd -f openocd.cfg

# In another terminal — GDB client
arm-none-eabi-gdb build/my_firmware.elf
(gdb) target extended-remote :3333
(gdb) monitor reset halt
(gdb) load             # flash the binary
(gdb) continue

# Useful GDB commands for embedded
(gdb) info registers              # all CPU registers
(gdb) x/10xw 0x20000000          # read RAM at address
(gdb) x/10xw 0x40020000          # read peripheral register
(gdb) monitor reset halt          # reset and halt CPU
(gdb) monitor mdw 0x40020000     # OpenOCD: read word from address
```

### CMake Flash Target

```cmake
# Add to CMakeLists.txt for convenient flashing
find_program(OPENOCD openocd)
if(OPENOCD)
    add_custom_target(flash
        COMMAND ${OPENOCD}
            -f ${CMAKE_SOURCE_DIR}/openocd.cfg
            -c "program ${PROJECT_NAME}.elf verify reset exit"
        DEPENDS ${PROJECT_NAME}.elf
        COMMENT "Flashing ${PROJECT_NAME}.elf"
    )

    add_custom_target(debug
        COMMAND ${OPENOCD} -f ${CMAKE_SOURCE_DIR}/openocd.cfg
        COMMENT "Starting OpenOCD GDB server on :3333"
    )
endif()
```

```bash
# Build and flash
cmake --build build && cmake --build build --target flash
```

## Common Linker Errors

| Error | Cause | Fix |
|---|---|---|
| `undefined reference to 'foo'` | Missing source file or library | Add to `target_sources` or `target_link_libraries` |
| `region FLASH overflowed` | Binary too large | Reduce code size (-Os), remove unused features |
| `region RAM overflowed` | BSS + data + stack exceed RAM | Reduce stack size, move data to FLASH (const), use CCMRAM |
| `multiple definition of 'foo'` | Same symbol in two .c files | Check for duplicate function names or missing include guards |
| `cannot find -lnosys` | `nosys.specs` not available | Use `--specs=nosys.specs` not `-lnosys` separately |
| `_exit` undefined | Newlib needs syscall stubs | Add `nosys.specs` or implement syscall stubs |

## Toolchain Checklist

```
Toolchain file:
- [ ] CMAKE_TRY_COMPILE_TARGET_TYPE set to STATIC_LIBRARY
- [ ] MCU_FLAGS set with correct -mcpu, -mthumb, -mfpu

CMakeLists:
- [ ] -ffunction-sections and -fdata-sections enabled
- [ ] -Wl,--gc-sections in link options (removes unused code)
- [ ] -Wl,--print-memory-usage to track flash/RAM
- [ ] Correct linker script referenced (-T flag)
- [ ] -specs=nano.specs for smaller C library

Build outputs:
- [ ] .hex or .bin generated for flashing
- [ ] .map file generated for memory analysis
- [ ] arm-none-eabi-size output reviewed after each build

Flashing:
- [ ] openocd.cfg matches your programmer (ST-Link vs J-Link)
- [ ] verify flag used when flashing (confirms write)
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| No `-Wl,--gc-sections` | Unused functions bloat flash; GC removes them |
| `HAL_MAX_DELAY` / `portMAX_DELAY` in production | Explicit timeout — always |
| Missing `-ffunction-sections` | Linker cannot GC individual functions without it |
| Editing CubeMX-generated code outside USER CODE | Regeneration overwrites it |
| Flashing without verify | Always use `verify` — silent write failures exist |
| No `.map` file analysis | Review after each build — catch unexpected size growth |
| `-O0` in production builds | `-Os` for release — embedded flash is limited |

## Connected Skills

- `c-embedded` — always load for C/C++ language patterns
- `freertos` — FreeRTOS CMake integration (`Middlewares/Third_Party/FreeRTOS`)
- `stm32-hal` — STM32-specific HAL patterns that sit on top of this toolchain
- `esp32-idf` — IDF has its own CMake layer — this skill covers non-IDF projects
- `debug-trace` — GDB, OpenOCD, and core dump analysis for embedded
