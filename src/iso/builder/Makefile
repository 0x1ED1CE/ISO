ISO_DIR       = F:/etc/projects/iso/v10
BOOTSTRAP_DIR = $(ISO_DIR)/src/lua
BUILD_DIR     = $(ISO_DIR)/src/iso/builder
LIB_DIR       = $(ISO_DIR)/src/iso/lib
BIN_DIR       = $(ISO_DIR)/bin

all: build

build: \
	$(BUILD_DIR)/main.iso \
	$(BUILD_DIR)/builder.iso \
	$(LIB_DIR)/string.iso \
	$(LIB_DIR)/console.iso \
	$(LIB_DIR)/system.iso \
	
	cd $(BOOTSTRAP_DIR); \
	./iso.bat -i \
	$(BUILD_DIR)/main.iso \
	$(BUILD_DIR)/builder.iso \
	$(LIB_DIR)/string.iso \
	$(LIB_DIR)/system.iso \
	$(LIB_DIR)/console.iso \
	-e $(BIN_DIR)/build.bin;
	
	cd $(BOOTSTRAP_DIR); \
	./iso.bat -d \
	$(BIN_DIR)/build.bin;
	
	cd $(BOOTSTRAP_DIR); \
	./iso.bat -i \
	$(BUILD_DIR)/main.iso \
	$(BUILD_DIR)/builder.iso \
	$(LIB_DIR)/string.iso \
	$(LIB_DIR)/system.iso \
	$(LIB_DIR)/console.iso \
	-s $(BIN_DIR)/build.s;
clean:
	#$(RM) $(BIN_DIR)/build.bin