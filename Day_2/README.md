---

# North Pole Gift Shop - Invalid ID Scanner

This repository contains a high-performance, synthesizable **SystemVerilog** solution for the "North Pole Gift Shop" puzzle (Day 2).

The project implements a hardware-accelerated scanner that processes streams of numerical ranges to identify "Invalid Product IDs" based on repeating digit patterns. Unlike software solutions that rely on string manipulation or expensive division/modulo operations, this design exploits **FPGA parallelism** to check patterns in zero clock cycles per number.
## 🧠 Design & Architecture

### The Core Problem

The challenge requires parsing a string of ranges (e.g., `11-22, 95-115`) and summing up every number within those ranges that exhibits a specific "repeating pattern."

### Hardware Architecture

The design achieves high efficiency using a **Dual-Representation Pipeline**:

1. **Parallel Counters:**
The design maintains two counters that increment in lockstep every clock cycle:
* **Binary Counter (64-bit):** Used for range bounds checking (`Start <= End`) and arithmetic summation.
* **BCD Counter (Decimal):** Used for pattern matching. BCD (Binary Coded Decimal) allows access to individual decimal digits (nibbles) without division logic.


2. **Combinational Pattern Matcher:**
Instead of iterating through digits, the design uses a **Generate Block** to create a matrix of parallel comparators at compile time.
* **Part 1:** Generates comparators for every even length  to check `UpperHalf == LowerHalf`.
* **Part 2:** Generates comparators for every length  and every valid divisor . It uses a "Shift-Check" technique: `Digits[L-1 : k] == Digits[L-1-k : 0]`. If a number matches itself shifted by , it proves the pattern repeats.


3. **Dynamic Length Tracking:**
The logic automatically detects when the number of digits increases (e.g., `99`  `100`) by monitoring the BCD carry chain. This ensures the pattern matcher always checks the correct bit-range.

## 🚀 How to Run

### Prerequisites

* **Simulator:** Vivado XSim, Verilator, or ModelSim.
* **Synthesis Tool (Optional):** Vivado, Quartus, or Yosys (if targeting hardware).

### Simulation Steps (Vivado Example)

1. **Add Sources:**
* Add `rtl/gift_shop_solver.sv` (or `_part2.sv`) as a **Design Source**.
* Add `sim/tb_gift_shop.sv` (or `_part2.sv`) as a **Simulation Source**.


2. **Prepare Input:**
* Copy your puzzle input string into `input.txt`.
* **Crucial Step:** Open the testbench file (`tb_gift_shop...sv`) and update the `INPUT_FILE_PATH` parameter to point to the **absolute path** of your `input.txt` file.


3. **Run Simulation:**
* Run **Behavioral Simulation**.
* The testbench will stream the file byte-by-byte into the RTL.
* Wait for the "FINAL RESULT" message in the console.



### Synthesis Parameters

The design is fully parameterized for scalability. You can modify the `MAX_DIGITS` parameter in the module instantiation to support larger numbers without rewriting any logic.

```systemverilog
// Example: Scale to support up to 100-digit numbers
gift_shop_solver #(.MAX_DIGITS(100)) dut (...);

```

## 📊 Performance

* **Throughput:** 1 Number Processed per Clock Cycle.
* **Latency:** Pattern checking is purely combinational (0 cycles).
* **Synthesizability:** Fully synthesizable SystemVerilog (no `real` types or dynamic loops).
