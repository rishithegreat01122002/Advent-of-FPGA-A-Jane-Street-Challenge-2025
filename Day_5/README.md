# 🍽️ Cafeteria Inventory System - Hardware Implementation

This project implements a high-performance hardware engine to solve the **Range Query** and **Range Union** problems for large-scale inventory management. It is designed to handle ingredient IDs up to  (quadrillions) with high throughput and hardware efficiency.

---

## 🏗️ Architecture Overview

The system is split into two specialized hardware engines designed to exploit FPGA-native parallelism and pipelining.

### Part 1: Systolic Filtering Pipeline (Streaming)

Designed for the **"Freshness Check,"** this engine processes a stream of available IDs against a database of ranges.

* **Parallel Matchers**: Turns the database into spatial hardware. Multiple comparators check an ID against different ranges simultaneously.


* **Pipelining**: Comparison logic is broken into stages (`RANGES_PER_STAGE`). This keeps the logic path shallow, allowing for extremely high clock frequencies ().


* 
**Throughput**: Achieves an Ideal IPC of 1; it can ingest and process one ID every single clock cycle.



### Part 2: Sort-and-Merge Union Engine (Range Union)

Designed to calculate the **"Total Fresh Footprint,"** this engine finds the unique count of integers covered by overlapping or adjacent ranges.

* **Bubble Sort FSM**: Organizes ranges by their start address. This is a prerequisite for the merging phase and is highly area-efficient for ASIC flows.
* **Interval Merging**: Iterates through sorted ranges and merges those that overlap or touch (e.g., `10-14` and `15-20` become `10-20`) to prevent double-counting.
* **Phantom-Range Filtering**: Strictly ignores uninitialized or "zeroed" ranges (like `0-0`) that might be introduced by artifacts in the input file (e.g., trailing blank lines).

---

## 🚀 Design Principles

* **Scalability**:
* **IDs**: The 64-bit datapath handles  scale values found in the input file without bit-width overflow.
* 
**Ranges**: While optimized for ~200 ranges, the architecture can scale to 1000x ranges by swapping the Bubble Sort for a **Bitonic Merge Sort** tree and using **BRAM** for storage.




* 
**Efficiency**: Both parts use resource sharing (shared accumulators and subtractors) to minimize area, making them ideal for **TinyTapeout** or open-source ASIC flows.


* 
**Language Features**: Utilizes SystemVerilog **Packed Structs** and **Generate Loops** to algorithmically build hardware, creating more elegant and maintainable code than standard Verilog.


## 🚦 How to Run

1. **Configure File Path**: In both testbenches, ensure the `$fopen` path points to your `input.txt` location (e.g., `/home/rishi/...`).
2. **Clock Setup**: Standard simulation uses a **10ns** clock period.
3. **Expected Results**:
* **Part 1**: Check simulation logs for the total count of available IDs that fall within fresh ranges.
* **Part 2**: The verified result for the provided input is **344,378,119,285,354**.
* *Note: If you see `344378119285355`, ensure the Phantom Range Filter is active to ignore the blank line artifact.*

