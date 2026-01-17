---

# Jane Street Electronic Trading Challenge - Day 1: The Safe

This repository contains a high-performance, FPGA-accelerated solution for the "North Pole Safe" puzzle (Day 1 of the Jane Street Electronic Trading Challenge).

Unlike a standard software approach that processes instructions sequentially (O(N)), this solution utilizes **SystemVerilog** to implement a **Parallel Prefix Sum (Scan)** architecture. It processes batches of instructions in a single clock cycle, exploiting hardware parallelism to achieve massive throughput.

## 🧠 Design Architecture

The core philosophy of this design is **Stream Processing**. Instead of updating the safe's dial one step at a time, the hardware swallows a "batch" of instructions (default: 8) every clock cycle and calculates their cumulative effect instantly.

### The Pipeline

The design is broken down into three pipelined stages to ensure high clock frequency:

1. **Stage 1: Normalization ("The Sanitizer")**
* **Problem:** Inputs are complex (`L35`, `R577`). "Left" subtracts, "Right" adds, and values can exceed the dial's size (100).
* **Hardware Solution:**
* **Modulo Reduction:** Large inputs (e.g., `R577`) are immediately reduced modulo 100 (`577 -> 77`) using 16-bit logic to prevent overflow.
* **Direction Unification:** "Left" moves are mathematically converted to "Right" moves (`L(x) == R(100-x)`). This eliminates the need for subtractors later in the chain, allowing us to use only adders.




2. **Stage 2: Parallel Prefix Sum ("The Crystal Ball")**
* **Problem:** To check if the dial hits `0` at step 3, we need to know the result of step 1 and step 2. In software, this forces a loop.
* **Hardware Solution:** We use a parallel prefix adder network. This combinational cloud calculates the absolute position of the dial for *every* step in the batch simultaneously relative to the current state.
* **Zero Detection:** A parallel comparator bank checks all 8 resulting positions against `0` instantly.


3. **Stage 3: State Update ("The Scorekeeper")**
* The global state is updated to the final position of the batch.
* The total count of "zeros" is updated using a population count (`$countones`) of the matches found in Stage 2.



### Part 1 vs. Part 2 Logic

* **Part 1 (`safe_cracker.sv`):** Counts only if the dial *lands* on 0 at the end of a rotation.
* **Part 2 (`safe_cracker_part2.sv`):** Implements "Method 0x434C49434B". It counts *every* time the dial clicks past 0.
* **Full Spins:** Integer division (`mag / 100`) counts how many times the dial spun completely.
* **Crossings:** Logic checks if the remainder of the move causes the dial to cross the 99->0 boundary.

## 🚀 How to Run

### Prerequisites

* **Xilinx Vivado** (for simulation and synthesis) or **Verilator** (for fast C++ simulation).
* The `input.txt` file must be present in the simulation directory.

### Simulation Steps (Vivado)

1. **Create Project:**
* Open Vivado and create a new RTL project.
* Add all files from `src/` and `sim/` to the project.


2. **Set Up Input File:**
* **Important:** You must update the file path in the testbench (`tb_safe_cracker.sv` or `tb_safe_cracker_part2.sv`) to point to the absolute location of `input.txt` on your machine.


```systemverilog
// Inside tb_safe_cracker_part2.sv
fd = $fopen("/absolute/path/to/your/repo/sim/input.txt", "r");

```


3. **Run Simulation:**
* Set `tb_safe_cracker_part2` as the top module.
* Run Behavioral Simulation.
* Check the Tcl Console or the standard output log for the result.



### Expected Output

```text
--- Starting Part 2 Simulation ---
----------------------------------------
PART 2 PASSWORD: [Your Answer Here]
----------------------------------------

```

---

## ⚙️ Scalability & Performance

* **Batch Size:** The architecture is parameterized by `BATCH_SIZE`. Increasing this width (e.g., to 16 or 32) linearly increases throughput, processing more lines of text per clock cycle.
* **Throughput:** Capable of processing 8 instructions per cycle. On a modest 100MHz FPGA clock, this equates to **800 million instructions per second**, far exceeding the requirements of the puzzle.
* **Efficiency:** Uses efficient bitwise logic for modulo 100 operations and leverages the FPGA's LUT structure for the adder chain.
