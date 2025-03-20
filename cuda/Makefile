TARGET = cutracer
BUILD_DIR = build

SRC = src/main.cu

NVCC = nvcc
NVCC_FLAGS = -O3 -arch=sm_86 --use_fast_math

all: $(BUILD_DIR)/$(TARGET)

$(BUILD_DIR)/$(TARGET): $(SRC)
	mkdir -p $(BUILD_DIR)
	$(NVCC) $(NVCC_FLAGS) -o $(BUILD_DIR)/$(TARGET) $(SRC)

run: $(BUILD_DIR)/$(TARGET)
	./$(BUILD_DIR)/$(TARGET)

clean:
	rm -rf $(BUILD_DIR)