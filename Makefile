CXX = g++
CXXFLAGS = -std=c++17 -O3 -Wall -fopenmp

SRC_DIR = src
BUILD_DIR = build
SRCS = $(SRC_DIR)/main.cpp
OBJS = $(BUILD_DIR)/main.o
TARGET = $(BUILD_DIR)/rtrace

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(OBJS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

run: $(TARGET)
	./$(TARGET)

clean:
	rm -rf $(BUILD_DIR)
