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

# Detect waveform viewer (prefer surfer, fallback to gtkwave)
WAVE_VIEWER := $(shell which surfer 2>/dev/null || which gtkwave 2>/dev/null)

.PHONY: all test sim wave demo clean help

# Default target: compile and run hardware testbench
all: test

# Compile simulation executable
$(SIM_BIN): $(SRC) $(TB)
	@echo "==> Compiling Verilog RTL & Testbench with $(IVERILOG)..."
	$(IVERILOG) -o $(SIM_BIN) $(SRC) $(TB)

# Run full hardware testbench
test: $(SIM_BIN)
	@echo "==> Running Hardware Simulation..."
	$(VVP) $(SIM_BIN)

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
		echo "    $(VCD_FILE) generated successfully. View with your preferred VCD viewer."; \
	fi

# Run end-to-end Neural Network Layer demonstration with Golden Model verification
demo: $(SIM_BIN)
	@echo "==> Running Quantized Neural Network Layer Demo..."
	$(PYTHON) demo_mlp_layer.py --show-relu

# Clean up simulation binaries and generated files
clean:
	@echo "==> Cleaning build artifacts and waveforms..."
	rm -f $(SIM_BIN) $(VCD_FILE) *.hex .stimulus_*.hex
	rm -rf __pycache__

# Help target
help:
	@echo "Simple Tensor Core Makefile targets:"
	@echo "  make test   - Compile and execute RTL verification testbench"
	@echo "  make sim    - Alias for 'make test'"
	@echo "  make demo   - Run Python INT8 Quantized Neural Network Layer demo"
	@echo "  make wave   - Generate waveform and open in surfer/gtkwave"
	@echo "  make clean  - Remove simulation binaries and generated VCD files"
	@echo "  make help   - Display this help message"
