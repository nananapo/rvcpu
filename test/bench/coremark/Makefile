TOOLCHAIN_PREFIX = riscv32-unknown-elf-
BIN2HEX = python3 ../../bin2hex.py
ARCH = rv32im_zicsr

OUTPUT_DIR = ./output

CC = $(TOOLCHAIN_PREFIX)gcc
LD = $(TOOLCHAIN_PREFIX)ld
OBJDUMP = $(TOOLCHAIN_PREFIX)objdump
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy

CFLAGS = \
	-g -O3 \
	-fno-stack-protector \
	-fno-zero-initialized-in-bss \
	-ffreestanding \
	-fno-builtin \
	-nostdlib \
	-nodefaultlibs \
	-nostartfiles \
	-march=$(ARCH) \
	# -mno-strict-align \

LDFLAGS = \
	-static \
	-Tlink.ld \
	-L/opt/riscv32/riscv32-unknown-elf/lib/ \
	# -lc \
	# -nostartfiles \

ITERATIONS = 400
CLOCKS_PER_SEC = 27000000
FLAGS_STR = ""

PORT_DIR = barebones
SRCS = \
	core_list_join.c \
	core_main.c \
	core_matrix.c \
	core_state.c \
	core_util.c \
	$(PORT_DIR)/core_portme.c \
	$(PORT_DIR)/ee_printf.c \

OBJS = $(SRCS:.c=.o) entry.o

CORE_CFLAGS = \
	-DITERATIONS=$(ITERATIONS) \
	-DCLOCKS_PER_SEC=$(CLOCKS_PER_SEC) \
	-I./ \
	-I$(PORT_DIR)/ \
	-DFLAGS_STR=\"$(FLAGS_STR)\" \
	# -DCORE_DEBUG=1 \

ELF_FILE = $(OUTPUT_DIR)/temp.elf
BIN_FILE = $(OUTPUT_DIR)/code.bin
DUMP_FILE = $(OUTPUT_DIR)/code.bin.dump

all: $(OBJS)
	-@mkdir output
	$(LD) $(OBJS) $(LDFLAGS) -o $(ELF_FILE)
	$(OBJCOPY) -O binary $(ELF_FILE) $(BIN_FILE)
	echo $(BIN_FILE) | $(BIN2HEX)
	$(OBJDUMP) -d $(ELF_FILE) > $(DUMP_FILE)

re: clean all

clean:
	rm -rf $(OBJS)
	rm -rf $(OUTPUT_DIR)/
	
%.o: %.c
	$(CC) $(CFLAGS) $(CORE_CFLAGS) -o $@ -c $<
entry.o:
	$(CC) $(CFLAGS) $(CORE_CFLAGS) -o entry.o -c entry.S
