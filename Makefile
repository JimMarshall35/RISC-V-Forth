# Toolchain
CC      = riscv-none-elf-gcc
OBJCOPY = riscv-none-elf-objcopy

# Targets
FORTH = Forth
QEMU_FORTH = QEMUForth
ASM_BENCHMARK = ASMBenchmark

# ===== Select startup file here =====
# Options: D6, D8, D8W
STARTUP ?= D6

STARTUP_FILE = SRC/Startup/startup_ch32v20x_$(STARTUP).S

# Flags

QEMU_LDFLAGS = -fno-use-linker-plugin -T qemu/baremetal.ld -march=rv32imafdc -mabi=ilp32 -nostdlib -static

CFLAGS = -march=rv32imac_zicsr_zifencei -mabi=ilp32 -msmall-data-limit=8 -msave-restore \
         -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections \
         -fno-common -Wunused -Wuninitialized -g

LDFLAGS = -T ch32/Link.ld -nostartfiles -Xlinker --gc-sections -Wl,-Map,"Forth.map" --specs=nano.specs --specs=nosys.specs

# Include paths

FORTH_INCLUDES = -IForth -Ich32 -Iqemu

INCLUDES = $(FORTH_INCLUDES)
# Source files

GEN_ASM = Forth/system.S
FORTH_SRC = Forth/system.forth

# full library

# FORTH
QEMU_SRC = $(wildcard qemu/*.S)
CH32_SRC = $(wildcard ch32/*.c) $(wildcard ch32/*.S)
FORTH_S := $(filter-out $(GEN_ASM), $(wildcard Forth/*.S Forth/*.s))

FORTH_SRCS = $(CH32_SRC) $(FORTH_S) $(GEN_ASM)
QEMU_SRCS = $(QEMU_SRC) $(FORTH_S) $(GEN_ASM)
ASM_BENCHMARK_SRCS = $(CH32_SRC) Forth/utils.S asm_benchmark/main.S

# Object files
FORTH_OBJS = $(FORTH_SRCS:.c=.o)
FORTH_OBJS := $(FORTH_OBJS:.S=.o)

QEMU_OBJS = $(QEMU_SRCS:.S=.o)

ASM_BENCHMARK_OBJS = $(ASM_BENCHMARK_SRCS:.S=.o)

# Default target
all: $(FORTH).elf $(QEMU_FORTH).elf $(ASM_BENCHMARK).elf

# Link
$(QEMU_FORTH).elf: $(QEMU_OBJS)
	$(CC) $(CFLAGS) $(QEMU_LDFLAGS) $(QEMU_OBJS) -o $@ 

$(FORTH).elf: $(FORTH_OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(FORTH_OBJS) -o $@ 

$(ASM_BENCHMARK).elf: $(ASM_BENCHMARK_OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(ASM_BENCHMARK_OBJS) -o $@ 

# Compile C
%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Compile ASM
%.o: %.S
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

Forth/system.o: $(GEN_ASM)

$(GEN_ASM): tools/Compiler.py $(FORTH_SRC)
	python3 tools/Compiler.py Forth/system.forth -a Forth/vm.S -o $@

# Clean
clean:
	rm -f $(ASM_BENCHMARK_OBJS) $(QEMU_OBJS) $(ASM_BENCHMARK).elf $(ASM_BENCHMARK).map $(QEMU_FORTH).elf $(QEMU_FORTH).map $(FORTH_OBJS) $(FORTH).elf $(FORTH).bin $(FORTH).map $(GEN_ASM)

.PHONY: all clean
