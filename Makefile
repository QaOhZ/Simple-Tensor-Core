# ==============================================================================
# Simple Tensor Core — Build & Verification Automation
# ==============================================================================

IVERILOG    ?= iverilog
VVP         ?= vvp
PYTHON      ?= python3

SRC         := tensor_core.v
TB          := tb_tensor_core.v
SIM_BIN     := top_test
VCD_FILE    := waveform.vcd

AXIS_SRC    := axis_tensor_core.v
AXIS_TB     := tb_axis_tensor_core.v
AXIS_BIN    := axis_test
AXIS_VCD    := axis_waveform.vcd

# Detect waveform viewer (prefer surfer, fallback to gtkwave)
WAVE_VIEWER := $(shell which surfer 2>/dev/null || which gtkwave 2>/dev/null)

.PHONY: all test test-axis test-all sim wave wave-axis demo clean help

# Default target: compile and run full hardware test suites
all: test-all

# Compile baseline simulation executable
$(SIM_BIN): $(SRC) $(TB)
	@echo "==> Compiling Verilog RTL & Testbench with $(IVERILOG)..."
	$(IVERILOG) -o $(SIM_BIN) $(SRC) $(TB)

# Compile AXI4-Stream IP simulation executable
$(AXIS_BIN): $(SRC) $(AXIS_SRC) $(AXIS_TB)
	@echo "==> Compiling AXI4-Stream IP Wrapper & Testbench with $(IVERILOG)..."
	$(IVERILOG) -o $(AXIS_BIN) $(SRC) $(AXIS_SRC) $(AXIS_TB)

# Run baseline hardware testbench
test: $(SIM_BIN)
	@echo "==> Running Hardware Simulation..."
	$(VVP) $(SIM_BIN)

# Run AXI4-Stream IP testbench
test-axis: $(AXIS_BIN)
	@echo "==> Running AXI4-Stream IP Simulation..."
	$(VVP) $(AXIS_BIN)

# Run all verification suites
test-all: test test-axis

# Alias for test
sim: test

# Run simulation and launch interactive waveform viewer
wave: $(SIM_BIN)
	@echo "==> Generating waveform..."
	$(VVP) $(SIM_BIN)
	@if [ -n "$(WAVE_VIEWER)" ]; then \
		echo "==> Opening $(VCD_FILE) in $(WAVE_VIEWER)..."; \
		$(WAVE_VIEWER) $(VCD_FILE) & \
	else \
		echo "==> No waveform viewer (surfer / gtkwave) found on PATH."; \
		echo "    $(VCD_FILE) generated successfully."; \
	fi

# Launch AXI4-Stream waveform in viewer
wave-axis: $(AXIS_BIN)
	@echo "==> Generating AXI-Stream waveform..."
	$(VVP) $(AXIS_BIN)
	@if [ -n "$(WAVE_VIEWER)" ]; then \
		echo "==> Opening $(AXIS_VCD) in $(WAVE_VIEWER)..."; \
		$(WAVE_VIEWER) $(AXIS_VCD) & \
	else \
		echo "==> No waveform viewer (surfer / gtkwave) found on PATH."; \
		echo "    $(AXIS_VCD) generated successfully."; \
	fi

# Run end-to-end Neural Network Layer demonstration with Golden Model verification
demo: $(SIM_BIN)
	@echo "==> Running Quantized Neural Network Layer Demo (Linear + ReLU)..."
	$(PYTHON) demo_mlp_layer.py --show-relu
	$(PYTHON) demo_mlp_layer.py --relu

# Clean up simulation binaries and generated files
clean:
	@echo "==> Cleaning build artifacts and waveforms..."
	rm -f $(SIM_BIN) $(AXIS_BIN) $(VCD_FILE) $(AXIS_VCD) *.hex .stimulus_*.hex
	rm -rf __pycache__

# Help target
help:
	@echo "Simple Tensor Core Makefile targets:"
	@echo "  make test      - Compile and execute base RTL testbench"
	@echo "  make test-axis - Compile and execute AXI4-Stream IP testbench"
	@echo "  make test-all  - Run all RTL testbenches (Base + AXI-Stream)"
	@echo "  make demo      - Run Python INT8 Quantized MLP layer demo (Linear + Hardware ReLU)"
	@echo "  make wave      - Generate core waveform and open in surfer/gtkwave"
	@echo "  make wave-axis - Generate AXI-Stream waveform and open in surfer/gtkwave"
	@echo "  make clean     - Remove simulation binaries, VCDs, and temp files"
	@echo "  make help      - Display this help message"
