# Toolchain
CC      = riscv-none-elf-gcc
OBJCOPY = riscv-none-elf-objcopy

# Targets
EXAMPLE = USART_Printf

# ===== Select startup file here =====
# Options: D6, D8, D8W
STARTUP ?= D6

STARTUP_FILE = SRC/Startup/startup_ch32v20x_$(STARTUP).S

# Flags
CFLAGS = -march=rv32imac_zicsr_zifencei -mabi=ilp32 -msmall-data-limit=8 -msave-restore \
         -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections \
         -fno-common -Wunused -Wuninitialized -g

LDFLAGS = -T SRC/Ld/Link.ld -nostartfiles -Xlinker --gc-sections -Wl,-Map,"USART_Printf.map" --specs=nano.specs --specs=nosys.specs

# Include paths
LIBRARY_INCLUDES = \
	-ISRC/Core \
	-ISRC/Debug \
	-ISRC/Peripheral/inc
	

EXAMPLE_INCLUDES = $(LIBRARY_INCLUDES) -IUSART_Printf/User

INCLUDES = $(EXAMPLE_INCLUDES)
# Source files

GEN_ASM = USART_Printf/User/system.S
FORTH_SRC = USART_Printf/User/system.forth

# full library
LIBRARY_C = \
	$(wildcard SRC/Core/*.c) \
	$(wildcard SRC/Debug/*.c) \
	$(wildcard SRC/Peripheral/src/*.c) \
	$(STARTUP_FILE) \

# example
EXAMPLE_C = $(wildcard USART_Printf/User/*.c)  $(LIBRARY_C)
EXAMPLE_S := $(wildcard USART_Printf/User/*.S USART_Printf/User/*.s)

EXAMPLE_SRCS = $(EXAMPLE_C) $(EXAMPLE_S) $(GEN_ASM)

# Object files
EXAMPLE_OBJS = $(EXAMPLE_SRCS:.c=.o)
EXAMPLE_OBJS := $(EXAMPLE_OBJS:.S=.o)

# Default target
all: $(EXAMPLE).elf #$(FORTH).elf

# Link
$(EXAMPLE).elf: $(EXAMPLE_OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(EXAMPLE_OBJS) -o $@ 

# Compile C
%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Compile ASM
%.o: %.S
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

USART_Printf/User/system.o: $(GEN_ASM)

$(GEN_ASM): tools/Compiler.py $(FORTH_SRC)
	python3 tools/Compiler.py USART_Printf/User/system.forth -a USART_Printf/User/vm.S -o $@

# Clean
clean:
	rm -f $(EXAMPLE_OBJS) $(EXAMPLE).elf $(EXAMPLE).bin $(EXAMPLE).map $(GEN_ASM)

.PHONY: all clean
