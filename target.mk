MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

TARGET := target
LINKER_SCRIPT := $(TARGET).ld
BUILD_DIR := build

LD_FLAGS := --gc-sections -nostdlib
BUILD_FLAGS := -O ReleaseSmall -target thumb-freestanding -mcpu cortex_m3

SRC_DIRS := \
  src \

SRCS := $(shell find $(SRC_DIRS) -maxdepth 1 -name "*.zig")
OBJS := ${SRCS:%=$(BUILD_DIR)/%.o}

.PHONY: all
all: $(BUILD_DIR)/$(TARGET).elf

$(BUILD_DIR)/${TARGET}.elf: $(OBJS) $(LINKER_SCRIPT)
	@echo Linking $@...
	@mkdir -p $(dir $@)
	@zig build-exe ${BUILD_FLAGS} $(OBJS) --name $@ --script ${LINKER_SCRIPT}

$(BUILD_DIR)/%.zig.o: %.zig
	@echo Compiling $@...
	@mkdir -p $(dir $@)
	@zig build-obj $(BUILD_FLAGS) -femit-bin=$@ $<

$(BUILD_DIR)/debug.cfg:
	@mkdir -p $(dir $@)
	@cp openocd/debug.cfg $(BUILD_DIR)/debug.cfg

.PHONY: debug-deps
debug-deps: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/debug.cfg

.PHONY: upload
upload: $(BUILD_DIR)/$(TARGET).elf
	@echo Uploading $<...
	@openocd -f openocd/upload.cfg

.PHONY: erase
erase:
	@openocd -f openocd/erase.cfg

.PHONY: clean
clean:
	@echo Cleaning...
	@rm -rf $(BUILD_DIR) $(SRC_DIRS:%=%/zig-cache) zig-cache
