TARGET = final


# Configure micro-controller
MCU_FAMILY	= STM32F103xB
LDSCRIPT 	= stm32f1.ld
CPU			= cortex-m3
INSTR_SET	= thumb
FLOAT_ABI	= soft

# compiler option
OPT			:= -Os
CSTD		?= c11
CXXSTD		:= c++17

# Project specific configuration
BUILD_DIR 	:= build
BUILD_TYPE	?= Debug
SRC_DIR 	:= src
INC_DIRS	= include


PREFIX		?= arm-none-eabi
CC			:= $(PREFIX)-gcc
CXX			:= $(PREFIX)-g++
LD			:= $(PREFIX)-gcc
AR			:= $(PREFIX)-ar
AS			:= $(PREFIX)-as
SIZE		:= $(PREFIX)-size
OBJCOPY		:= $(PREFIX)-objcopy
OBJDUMP		:= $(PREFIX)-objdump
GDB			:= $(PREFIX)-gdb

# collect source files and generate object files
SRCS 		:= $(shell find $(SRC_DIR) -name '*.cpp' -or -name '*.c')	
OBJS 		:= $(addsuffix .o,$(basename $(SRCS)))			# replace .c with .o
OBJS 		:= $(addprefix $(BUILD_DIR)/,$(OBJS))			# replace .c with .o


# Define stm32 family macro
DEFS		+= -D$(MCU_FAMILY)

# header library include flsgs
INC_FLAGS 	= $(addprefix -I,$(INC_DIRS))


# Target-specific flags
CPU_FLAGS	?= -mfloat-abi=$(FLOAT_ABI) -m$(INSTR_SET) -mcpu=$(CPU)

CPPFLAGS	?=$(DEFS) $(INC_FLAGS)
CFLAGS		?=$(CPU_FLAGS) $(OPT)
CXXFLAGS 	:=$(CFLAGS) -fno-exceptions -fno-rtti
LDFLAGS		?=$(CPU_FLAGS)

# Do not link stdlib with executable
CFLAGS		+= -nostdlib -fno-tree-loop-distribute-patterns -fdata-sections -ffunction-sections
CXXFLAGS	+= -nostdlib -fno-tree-loop-distribute-patterns -fdata-sections -ffunction-sections
LDFLAGS		+= -nostdlib -fno-tree-loop-distribute-patterns 


# Warning options for C and CXX compiler
CFLAGS		+= -Wall -Wextra -Wundef -Wshadow -Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes
CXXFLAGS	+= -Wall -Wextra -Wundef -Wshadow -Wredundant-decls -Weffc++ -Werror


LDFLAGS		+= -T $(LDSCRIPT)
LDFLAGS		+= -Wl,-Map=$(basename $@).map

all: bin size
size: $(BUILD_DIR)/$(TARGET).size
elf: $(BUILD_DIR)/$(TARGET).elf
bin: $(BUILD_DIR)/$(TARGET).bin
hex: $(BUILD_DIR)/$(TARGET).hex
srec: $(BUILD_DIR)/$(TARGET).srec
list: $(BUILD_DIR)/$(TARGET).list


%.size: %.elf
	@$(SIZE) $<

%.bin: %.elf
	@echo "COPY " $< " => " $@
	@$(OBJCOPY) -Obinary $(*).elf $(*).bin

$(BUILD_DIR)/%.o:%.c
	@mkdir -p $(dir $@)
	@echo "CC" $< " ==> " $@
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ -c $<

$(BUILD_DIR)/%.o:%.cpp
	@mkdir -p $(dir $@)
	@echo "CXX" $< " ==> " $@
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ -c $<
	
$(BUILD_DIR)/$(TARGET).elf: $(OBJS)
	@echo "Linking sources into "$@
	@$(CC) $(LDFLAGS) -o $@ $^


flash: bin
	st-flash write $(BUILD_DIR)/$(TARGET).bin 0x8000000
	
debug: CFLAGS 		+= -g -gdwarf-2
debug: CXXFLAGS 	+= -g -gdwarf-2
debug: all

clean:
	rm -rf build
