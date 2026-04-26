# Toolchain
CC      = riscv-none-elf-gcc
OBJCOPY = riscv-none-elf-objcopy

# Targets
FORTH = Forth

# ===== Select startup file here =====
# Options: D6, D8, D8W
STARTUP ?= D6

STARTUP_FILE = SRC/Startup/startup_ch32v20x_$(STARTUP).S

# Flags
CFLAGS = -march=rv32imac_zicsr_zifencei -mabi=ilp32 -msmall-data-limit=8 -msave-restore \
         -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections \
         -fno-common -Wunused -Wuninitialized -g

LDFLAGS = -T SRC/Ld/Link.ld -nostartfiles -Xlinker --gc-sections -Wl,-Map,"Forth.map" --specs=nano.specs --specs=nosys.specs

# Include paths
LIBRARY_INCLUDES = \
	-ISRC/Core \
	-ISRC/Debug \
	-ISRC/Peripheral/inc
	

FORTH_INCLUDES = $(LIBRARY_INCLUDES) -IForth

INCLUDES = $(FORTH_INCLUDES)
# Source files

GEN_ASM = Forth/system.S
FORTH_SRC = Forth/system.forth

# full library
LIBRARY_C = \
	$(wildcard SRC/Core/*.c) \
	$(wildcard SRC/Debug/*.c) \
	$(wildcard SRC/Peripheral/src/*.c) \
	$(STARTUP_FILE) \

# FORTH
FORTH_C = $(wildcard Forth/*.c)  $(LIBRARY_C)
FORTH_S := $(filter-out $(GEN_ASM), $(wildcard Forth/*.S Forth/*.s))

FORTH_SRCS = $(FORTH_C) $(FORTH_S) $(GEN_ASM)

# Object files
FORTH_OBJS = $(FORTH_SRCS:.c=.o)
FORTH_OBJS := $(FORTH_OBJS:.S=.o)

# Default target
all: $(FORTH).elf #$(FORTH).elf

# Link
$(FORTH).elf: $(FORTH_OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(FORTH_OBJS) -o $@ 

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
	rm -f $(FORTH_OBJS) $(FORTH).elf $(FORTH).bin $(FORTH).map $(GEN_ASM)

.PHONY: all clean
