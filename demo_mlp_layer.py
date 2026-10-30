#!/usr/bin/env python3
"""
Simple Tensor Core — End-to-End Neural Network Layer Demo
----------------------------------------------------------
Simulates a Quantized INT8 Linear / MLP Layer (E = A x B + D):
  - A (4x4): Input Activation Batch (4 samples x 4 features)
  - B (4x4): Quantized Layer Weights (4 inputs x 4 neurons)
  - D (4x4): Quantized Layer Biases (broadcast or per-neuron)
  - E (4x4): Layer Pre-activation Outputs (20-bit Accumulator)
  - Optional: ReLU(E) post-activation comparison

Executes the hardware Verilog model using Icarus Verilog via dynamic
hex stimulus injection (+load=<file>.hex) and verifies the hardware
output bit-for-bit against a Python golden reference model.
"""

import os
import sys
import argparse
import subprocess
import tempfile
import random

# ANSI Colors for terminal output
BOLD = "\033[1m"
GREEN = "\033[32m"
CYAN = "\033[36m"
YELLOW = "\033[33m"
RED = "\033[31m"
MAGENTA = "\033[35m"
RESET = "\033[0m"


def to_signed_8bit(val):
    """Clamps and converts integer to signed 8-bit range [-128, 127]."""
    v = max(-128, min(127, int(val)))
    return v


def to_hex_byte(val):
    """Converts signed 8-bit integer to 2-digit hex string."""
    return f"{(val & 0xFF):02x}"


def from_20bit_hex(hex_str):
    """Converts 20-bit hex string (5 hex digits) to signed integer."""
    val = int(hex_str, 16)
    if val >= (1 << 19):  # Sign bit set
        return val - (1 << 20)
    return val


def compute_golden_model(A, B, D):
    """Computes E = (A x B) + D using signed two's complement integer math."""
    E = [[0] * 4 for _ in range(4)]
    for i in range(4):
        for j in range(4):
            acc = 0
            for k in range(4):
                acc += A[i][k] * B[k][j]
            acc += D[i][j]
            E[i][j] = acc
    return E


def get_preset_matrices(preset_name, seed=None):
    """Generates 4x4 matrices A (activations), B (weights), D (biases)."""
    if seed is not None:
        random.seed(seed)

    if preset_name == "mlp":
        # Realistic INT8 Quantized MLP layer (4 input features, 4 neurons, batch size 4)
        A = [
            [ 45,  12, -28,  60],  # Sample 1: Strong feature 0 and 3
            [-18,  55,  30, -10],  # Sample 2: Strong feature 1 and 2
            [ 72, -40,  15, -35],  # Sample 3
            [ -8,  20, -50,  42],  # Sample 4
        ]
        B = [
            # Neuron 0, 1,   2,   3
            [  24,     -15,  32,   5],   # Weight from input 0
            [ -10,      40, -18,  22],   # Weight from input 1
            [  35,     -20,  12, -30],   # Weight from input 2
            [   8,      14, -25,  48],   # Weight from input 3
        ]
        D = [
            # Biases for neurons 0..3 broadcast across batch
            [ 15, -10,  25,  -5],
            [ 15, -10,  25,  -5],
            [ 15, -10,  25,  -5],
            [ 15, -10,  25,  -5],
        ]

    elif preset_name == "edge":
        # 2D Spatial Edge / Feature detector kernel representation
        A = [
            [  0,  30,  90, 120],
            [ 10,  40, 100, 120],
            [ 20,  50, 110, 125],
            [ 30,  60, 115, 127],
        ]
        B = [
            [ -1,  -2,  -1,   0],
            [  0,   0,   0,   1],
            [  1,   2,   1,   0],
            [  0,   0,   0,  -1],
        ]
        D = [
            [ 10,  10,  10,  10],
            [ 10,  10,  10,  10],
            [ 10,  10,  10,  10],
            [ 10,  10,  10,  10],
        ]

    elif preset_name == "identity":
        A = [
            [ 12, -34,  56, -78],
            [-90,  45, -23,  67],
            [ 89, -12,  34, -56],
            [-78,  90, -12,  34],
        ]
        B = [
            [  1,   0,   0,   0],
            [  0,   1,   0,   0],
            [  0,   0,   1,   0],
            [  0,   0,   0,   1],
        ]
        D = [
            [  5,  -5,  10, -10],
            [  5,  -5,  10, -10],
            [  5,  -5,  10, -10],
            [  5,  -5,  10, -10],
        ]

    elif preset_name == "random":
        A = [[random.randint(-128, 127) for _ in range(4)] for _ in range(4)]
        B = [[random.randint(-128, 127) for _ in range(4)] for _ in range(4)]
        D = [[random.randint(-128, 127) for _ in range(4)] for _ in range(4)]

    else:
        raise ValueError(f"Unknown preset: {preset_name}")

    return A, B, D


def format_matrix(mat, width=6, prefix="  "):
    lines = []
    for row in mat:
        formatted_row = " ".join(f"{val:{width}d}" for val in row)
        lines.append(f"{prefix}[ {formatted_row} ]")
    return "\n".join(lines)


def ensure_sim_compiled(sim_binary, project_dir):
    """Compiles the simulation binary if not present."""
    if not os.path.isfile(sim_binary):
        print(f"{YELLOW}[*] Simulation binary '{os.path.basename(sim_binary)}' not found. Compiling with iverilog...{RESET}")
        cmd = [
            "iverilog",
            "-o", sim_binary,
            os.path.join(project_dir, "tensor_core.v"),
            os.path.join(project_dir, "tb_tensor_core.v")
        ]
        res = subprocess.run(cmd, cwd=project_dir, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"{RED}[!] Compilation failed:{RESET}\n{res.stderr}")
            sys.exit(1)
        print(f"{GREEN}[+] Compilation successful.{RESET}\n")


def run_hardware_sim(sim_binary, hex_path, project_dir, relu=False):
    """Executes the simulator with the dynamic hex stimulus."""
    cmd = [sim_binary, f"+load={hex_path}"]
    if relu:
        cmd.append("+relu")
    res = subprocess.run(cmd, cwd=project_dir, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"{RED}[!] Simulator exited with code {res.returncode}:{RESET}\n{res.stderr}")
        sys.exit(1)
    return res.stdout


def parse_sim_output(stdout):
    """Extracts the 4x4 output matrix E from the custom run section."""
    marker = "MATRIX COMPUTATION COMPLETE: Custom-Terminal-Input"
    if marker not in stdout:
        raise RuntimeError("Could not find Custom-Terminal-Input in simulation output.")

    section = stdout.split(marker)[1]
    output_marker = "Output Matrix E (4x4):"
    if output_marker not in section:
        raise RuntimeError("Could not find Output Matrix in simulation output.")

    matrix_str = section.split(output_marker)[1].split("===")[0].strip()
    rows = [r.strip() for r in matrix_str.split("\n") if r.strip()]

    hw_E = []
    for row in rows[:4]:
        # Tokens look like: [0012e] [ffea7] [00186] [ffe4d]
        tokens = row.replace("[", "").replace("]", "").split()
        hw_E.append([from_20bit_hex(t) for t in tokens])

    return hw_E


def main():
    parser = argparse.ArgumentParser(
        description="Simple Tensor Core — End-to-End Neural Network Layer Demonstration",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--preset",
        choices=["mlp", "edge", "identity", "random"],
        default="mlp",
        help="Matrix scenario preset",
    )
    parser.add_argument("--seed", type=int, default=None, help="Random seed for repeatable random runs")
    parser.add_argument("--relu", action="store_true", help="Enable hardware ReLU activation (+relu)")
    parser.add_argument("--show-relu", action="store_true", help="Display post-activation ReLU(E) values")
    parser.add_argument("--sim-binary", default="./top_test", help="Path to compiled iverilog executable")
    args = parser.parse_args()

    project_dir = os.path.dirname(os.path.abspath(__file__))
    sim_binary = os.path.abspath(os.path.join(project_dir, args.sim_binary))

    print(f"\n{BOLD}{CYAN}==================================================================={RESET}")
    print(f"{BOLD}{CYAN}      SIMPLE TENSOR CORE — QUANTIZED NEURAL NETWORK LAYER DEMO      {RESET}")
    print(f"{BOLD}{CYAN}==================================================================={RESET}")
    op_desc = "E = ReLU((A x B) + D)" if args.relu else "E = (A x B) + D"
    print(f" Target Operation: {BOLD}{op_desc}{RESET}")
    print(f" Precision Mode  : {BOLD}8-bit Signed (INT8) x INT8 -> 20-bit Accumulator{RESET}")
    print(f" Hardware ReLU   : {BOLD}{'ENABLED (On-Chip)' if args.relu else 'DISABLED (Linear Pass)'}{RESET}")
    print(f" Scenario Preset : {BOLD}{args.preset.upper()}{RESET}\n")

    # 1. Generate Input Matrices
    A, B, D = get_preset_matrices(args.preset, args.seed)

    # 2. Golden Reference Calculation
    E_ref = compute_golden_model(A, B, D)
    if args.relu:
        E_ref = [[max(0, val) for val in row] for row in E_ref]

    # 3. Create stimulus hex file (48 bytes: 16x A, 16x B, 16x D)
    # Note: Use a relative filename without spaces because Verilog $value$plusargs("%s")
    # splits on whitespace.
    hex_filename = f".stimulus_{random.randint(10000, 99999)}.hex"
    hex_path = os.path.join(project_dir, hex_filename)
    try:
        with open(hex_path, "w") as f:
            for row in A:
                for val in row:
                    f.write(f"{to_hex_byte(val)}\n")
            for row in B:
                for val in row:
                    f.write(f"{to_hex_byte(val)}\n")
            for row in D:
                for val in row:
                    f.write(f"{to_hex_byte(val)}\n")

        # 4. Compile simulator if needed
        ensure_sim_compiled(sim_binary, project_dir)

        # 5. Run Hardware Simulation
        print(f"{CYAN}[*] Injecting stimulus into Verilog systolic core via {hex_filename}...{RESET}")
        sim_stdout = run_hardware_sim(sim_binary, hex_filename, project_dir, relu=args.relu)
        hw_E = parse_sim_output(sim_stdout)

    finally:
        if os.path.exists(hex_path):
            os.remove(hex_path)

    # 6. Display Input Matrices
    print(f"\n{BOLD}1. Input Activations A (Batch x Features):{RESET}")
    print(format_matrix(A))

    print(f"\n{BOLD}2. Layer Weights B (Features x Neurons):{RESET}")
    print(format_matrix(B))

    print(f"\n{BOLD}3. Layer Biases D (Per-Neuron):{RESET}")
    print(format_matrix(D))

    # 7. Display Results & Verification
    print(f"\n{BOLD}4. Hardware Tensor Core Output E (20-bit Signed):{RESET}")
    print(format_matrix(hw_E, width=8))

    print(f"\n{BOLD}5. Python Reference Model E_golden:{RESET}")
    print(format_matrix(E_ref, width=8))

    # Compare Hardware vs Reference
    mismatches = 0
    for i in range(4):
        for j in range(4):
            if hw_E[i][j] != E_ref[i][j]:
                mismatches += 1
                print(f"{RED}[FAIL] Element [{i}][{j}]: Hardware={hw_E[i][j]} != Expected={E_ref[i][j]}{RESET}")

    if mismatches == 0:
        print(f"\n{BOLD}{GREEN}[PASS] Verification Successful: 16/16 elements match bit-for-bit with Golden Model!{RESET}")
    else:
        print(f"\n{BOLD}{RED}[FAIL] Verification Failed: {mismatches} mismatches detected!{RESET}")
        sys.exit(1)

    # Optional: Display ReLU output
    if args.show_relu:
        relu_out = [[max(0, val) for val in row] for row in hw_E]
        print(f"\n{BOLD}6. Post-Activation ReLU(E) = max(0, E):{RESET}")
        print(format_matrix(relu_out, width=8))

    print(f"\n{BOLD}{CYAN}==================================================================={RESET}\n")


if __name__ == "__main__":
    main()
