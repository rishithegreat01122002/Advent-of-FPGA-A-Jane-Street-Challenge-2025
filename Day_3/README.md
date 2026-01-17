---

# Jane Street Logic Puzzle: "Battery Joltage" (FPGA Solution)

This repository contains a hardware-accelerated solution (Verilog) for the Jane Street "Battery Joltage" logic puzzle (Day 3).

Unlike typical software solutions that might parse strings or use recursion, this design focuses on **streaming data processing**, maximizing throughput and minimizing resource usage on an FPGA architecture.

## 🧩 The Challenge

We are given a large input file containing lines of digits ("battery banks"). For each bank, we must select a specific number of digits to form the largest possible number, preserving their original relative order (a subsequence).

* **Part 1:** Select **2 digits** to find the local maximum.
* **Part 2:** Select **12 digits** to find the global maximum subsequence.
* **Goal:** Calculate the sum of these maximums across all banks.

---

## 💡 Design Approach

### Part 1: The "Greedy Stream" (2 Digits)

**The Constraint:** We need to find the largest pair () where  appears before .

**The Thought Process:**
A naive approach would store the entire line in memory and loop through it. However, in hardware, memory is expensive. Since we only need 2 digits, we can solve this in **linear time ** with ** space**.

**The Design:**
We process the digits as a continuous stream (AXI-Stream interface). We maintain two registers:

1. `max_digit_seen`: The largest single digit found so far.
2. `max_pair_seen`: The largest valid pair found so far.

For every incoming digit , we calculate a candidate pair (`max_digit_seen`, ) and update our records. This allows us to find the answer with **zero latency**—the result is ready the exact clock cycle the line ends.

### Part 2: Monotonic Stack with Quota (12 Digits)

**The Constraint:** We need a 12-digit subsequence. A pure greedy approach fails here because picking a large digit early might consume "slots" we need later, or skipping a medium digit might leave us with too few digits to finish the sequence.

**The Thought Process:**
We need to "look ahead" or "backtrack." Since we can't look ahead indefinitely in a stream without buffering, we buffer one line at a time. The optimal algorithm is a **Monotonic Stack** (Nearest Greater Element), but with a strict length constraint.

**The Design:**

1. **Buffer:** Store the current line in Distributed RAM (LUT-based).
2. **Stack Logic:** We iterate through the buffer. Ideally, we want our selected digits to be in descending order (e.g., `987...`).
3. **The "Quota" Check:** If we see a new digit that is larger than the last one we picked, we want to swap them (pop the stack). However, we are only allowed to pop if:



This ensures we never discard a digit if it makes it impossible to reach the target length of 12.

## 🚀 How to Run (Xilinx Vivado)

1. **Download the Files:** Clone this repo to your local machine.
2. **Create Project:** Open Xilinx Vivado and create a new RTL Project.
* Add the files in `src/` as **Design Sources**.
* Add the files in `sim/` as **Simulation Sources**.


3. **Setup Input File:**
* Open the testbench file you want to run (e.g., `tb_battery_part2.v`).
* Locate the `$fopen` line (approx. line 45).
* **Crucial:** Change the path to the absolute path of `input.txt` on your computer:
```verilog
file_handle = $fopen("/home/username/projects/jane_street/input.txt", "r");

```




4. **Run Simulation:**
* Set the desired testbench as "Top".
* Click **Run Simulation > Run Behavioral Simulation**.
* Click the **"Run All"** button (or type `run -all` in the Tcl Console) to process the full file.


5. **View Results:**
* The final calculated sum will be printed in the Tcl Console:
```text
-------------------------------------------
FINAL TOTAL JOLTAGE (Part 2): 3121910778619
-------------------------------------------

```





---

## ⚡ Performance

* **Part 1 Latency:** 0 Cycles (Instantaneous upon `tlast`).
* **Part 2 Latency:**  cycles per line (linear processing time).
* **Resource Usage:** Minimal (Logic + Distributed RAM). No Block RAM (BRAM) or DSP slices required.
