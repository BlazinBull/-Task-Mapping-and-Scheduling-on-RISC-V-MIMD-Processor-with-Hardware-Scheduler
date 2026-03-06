# Quad-Core RISC-V MIMD Processor with Hardware Task Scheduling

A resource-efficient, FPGA-optimized quad-core RISC-V processor implementing the RV32I instruction set with a centralized Hardware Scheduler Engine (HSE) for deterministic task management. The architecture eliminates software scheduling overhead through hardware-level task coordination, making it ideal for real-time embedded systems and edge computing applications.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Why Hardware Scheduling?](#why-hardware-scheduling)
- [Getting Started](#getting-started)
- [Design Implementation](#design-implementation)
- [Performance Results](#performance-results)
- [Use Cases](#use-cases)
- [Known Limitations](#known-limitations)
- [Future Work](#future-work)
- [References](#references)
- [Authors](#authors)

## Overview

This quad-core RISC-V Multiple-Instruction Multiple-Data (MIMD) processor addresses critical challenges in real-time embedded systems:

- **Deterministic execution** — Hardware scheduler eliminates non-deterministic context switching overhead inherent in software RTOS
- **Resource efficiency** — Dual-port instruction memory organization reduces BRAM usage by 50% compared to dedicated-per-core designs
- **Zero-overhead scheduling** — Task dispatch, dependency resolution, and fault isolation occur entirely in hardware with single-cycle latency
- **Fault resilience** — Automatic fault detection and task isolation without system-wide reset

The system achieves **3.48× speedup** on multi-task workloads compared to single-core execution while maintaining compact FPGA resource footprint (4,212 LUTs, 158 FFs, 4 BRAM blocks).

## Architecture

### System-Level Block Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Quad-Core System                           │
│                                                                     │
│  ┌──────────────┐              ┌─────────────────────┐            │
│  │   MMIO       │─────────────▶│  Hardware Scheduler │            │
│  │   Config     │              │       (HSE)         │            │
│  └──────────────┘              └──────────┬──────────┘            │
│                                           │                        │
│                         ┌─────────────────┼─────────────────┐     │
│                         │                 │                 │     │
│                         ▼                 ▼                 ▼     │
│              ┌──────────────────────────────────────────────┐     │
│              │         IMEM Arbiter & Scheduler             │     │
│              │        (Dual-Port BRAM Interface)            │     │
│              └────────┬─────────────┬─────────────┬─────────┘     │
│                       │             │             │               │
│    ┌──────────────────┼─────────────┼─────────────┼────────────┐  │
│    │                  │             │             │            │  │
│    ▼                  ▼             ▼             ▼            │  │
│  ┌─────────┐      ┌─────────┐  ┌─────────┐  ┌─────────┐      │  │
│  │ CORE 0  │      │ CORE 1  │  │ CORE 2  │  │ CORE 3  │      │  │
│  │ RV32I   │      │ RV32I   │  │ RV32I   │  │ RV32I   │      │  │
│  │ ┌─────┐ │      │ ┌─────┐ │  │ ┌─────┐ │  │ ┌─────┐ │      │  │
│  │ │4 HW │ │      │ │4 HW │ │  │ │4 HW │ │  │ │4 HW │ │      │  │
│  │ │Tasks│ │      │ │Tasks│ │  │ │Tasks│ │  │ │Tasks│ │      │  │
│  │ └─────┘ │      │ └─────┘ │  │ └─────┘ │  │ └─────┘ │      │  │
│  └────┬────┘      └────┬────┘  └────┬────┘  └────┬────┘      │  │
│       │                │             │             │           │  │
│       └────────────────┼─────────────┼─────────────┘           │  │
│                        │             │                         │  │
│                        ▼             ▼                         │  │
│                 ┌──────────────────────────┐                  │  │
│                 │    DMEM Arbiter          │                  │  │
│                 │  (Fixed Priority Bus)    │                  │  │
│                 └─────────┬────────────────┘                  │  │
│                           ▼                                   │  │
│                 ┌──────────────────┐                          │  │
│                 │       DMEM       │                          │  │
│                 │  (Data Memory)   │                          │  │
│                 └──────────────────┘                          │  │
│                                                                │  │
└────────────────────────────────────────────────────────────────┘  │
```

### Key Components

**Hardware Scheduler Engine (HSE)**
- Maintains Task Control Blocks (TCBs) for all tasks across all cores
- Performs combinational priority comparison in a two-level tree (pairs → global best)
- Issues task dispatch signals to idle cores in a single clock cycle
- Handles fault detection, priority boosting, and task isolation without software intervention

**Dual-Port Instruction Memory (IMEM)**
- Two dual-port BRAM blocks serve all four cores
- IMEM Block 0: Core 0 & Core 1
- IMEM Block 1: Core 2 & Core 3
- Enables simultaneous instruction fetch from two cores per block
- Reduces BRAM usage from 4 blocks (dedicated) to 2 blocks (shared)

**RISC-V Cores (RV32I)**
- Each core supports 4 hardware task contexts (banked register sets + PCs)
- Zero-overhead context switching via pointer update (no save/restore)
- Cores report status to HSE: `core_idle`, `core_fault`, `core_task_done`

**Data Memory (DMEM) Arbiter**
- Fixed-priority bus arbiter manages shared data memory access
- Stall signals trigger latency hiding: HSE rotates core to non-blocked task
- Maintains throughput during memory contention

## Why Hardware Scheduling?

### The Problem: Software RTOS Overhead

Traditional multi-core systems rely on software-based Real-Time Operating Systems (RTOS) for task management. This introduces:

| Issue | Impact |
|-------|--------|
| **Context Switch Overhead** | 100–500 CPU cycles per switch to save/restore registers and stack |
| **Interrupt Jitter** | Unpredictable delay between interrupt assertion and handler execution |
| **Scheduling Latency** | Software loops to evaluate task priorities and select next task |
| **Non-Determinism** | Variable execution time due to cache misses, pipeline stalls, and OS state |

### The Solution: Hardware Scheduler Engine

The HSE replaces software scheduling with dedicated combinational logic:

| Feature | Software RTOS | Hardware Scheduler (HSE) |
|---------|---------------|--------------------------|
| **Context Switch Time** | 100–500 cycles | 1 cycle (pointer update) |
| **Task Dispatch Latency** | 50–200 cycles | 1 cycle (combinational) |
| **Determinism** | Variable (cache/pipeline dependent) | Cycle-accurate (pure hardware) |
| **Fault Handling** | ISR + software recovery | Hardware isolation + reallocation |
| **Overhead** | 5–20% CPU time | <1% logic area |

### Mathematical Representation

The scheduler evaluates task eligibility using bitwise logic:

**Eligibility Condition:**
```
t_valid[i] = (tcb_state[i] == READY) ∧ 
             (tcb_fault[i] ≠ ISOLATED) ∧ 
             (tcb_running_mask[i] == 0)
```

**Priority Comparison Tree:**
```
best01 = (eff_prio[0] >= eff_prio[1]) ? 0 : 1
best23 = (eff_prio[2] >= eff_prio[3]) ? 2 : 3
global_best = (eff_prio[best01] >= eff_prio[best23]) ? best01 : best23
```

**Effective Priority (with Fault Boost):**
```
eff_prio[i] = { base_prio[i],           if fault[i] = NONE
              { base_prio[i] + 7,       if fault[i] = CRITICAL
              { 0,                      if fault[i] = ISOLATED
```

This ensures faulty tasks receive priority boost for retry attempts before permanent isolation.

## Getting Started

### Prerequisites

- **Vivado Design Suite** 2024.2 or later
- **FPGA Board** PYNQ-Z2 (Zynq-7000 series) or compatible
- **RISC-V Toolchain** for compiling firmware (optional, for custom workloads)
- Basic knowledge of Verilog/SystemVerilog and FPGA workflows

### Installation

Clone the repository and navigate to the project directory:

```bash
git clone https://github.com/your-org/quad-core-riscv-mimd.git
cd quad-core-riscv-mimd
```

### Simulation

Run RTL simulation in Vivado:

```bash
vivado -mode batch -source scripts/run_simulation.tcl
```

Key signals to monitor:
- `scheduler/tcb_state[3:0]` — Task states (READY, RUNNING, ISOLATED)
- `scheduler/tcb_eff_prio[3:0]` — Effective priorities
- `scheduler/global_best` — Currently selected task ID
- `core[0-3]/core_idle` — Core availability
- `core[0-3]/core_fault` — Fault signals
- `core[0-3]/core_task_done` — Completion signals

### Synthesis & Implementation

Generate bitstream for FPGA deployment:

```bash
vivado -mode batch -source scripts/run_synthesis.tcl
vivado -mode batch -source scripts/run_implementation.tcl
vivado -mode batch -source scripts/generate_bitstream.tcl
```

Expected resource utilization (PYNQ-Z2):
- **LUTs:** 4,212
- **Flip-Flops:** 158
- **BRAM:** 4 blocks
- **DSP Slices:** 0

### Running on FPGA

Program the FPGA and load test workload:

```bash
# Program bitstream
vivado -mode batch -source scripts/program_fpga.tcl

# Load task firmware into IMEM via JTAG or memory interface
# (Refer to docs/firmware_loading.md for detailed instructions)
```

## Design Implementation

### Task Control Block (TCB) Structure

Each task maintains the following hardware registers:

| Register | Bit-Width | Purpose |
|----------|-----------|---------|
| `tcb_state` | 2-bit | Current state: READY (00), RUNNING (01), ISOLATED (11) |
| `tcb_base_prio` | 4-bit | Static priority assigned at reset (Task 0=8, Task 1=6, Task 2=4, Task 3=2) |
| `tcb_eff_prio` | 5-bit | Dynamic priority = base_prio OR base_prio+7 (CRIT) OR 0 (ISO) |
| `tcb_fault` | 2-bit | Fault status: NONE (00), CRITICAL (01), ISOLATED (10) |
| `tcb_fault_cnt` | 4-bit | Increments on each fault; triggers isolation at count ≥ 3 |
| `tcb_running_mask` | 4-bit | One-hot encoding: which core owns this task (bit[n]=1 if core n) |

### Scheduling Algorithm (Hardware Implementation)

The HSE operates through the following phases every clock cycle:

**Phase 1: Effective Priority Computation (Combinational)**
```verilog
always @(*) begin
    for (i = 0; i < 4; i = i + 1) begin
        if (tcb_fault[i] == FAULT_NONE)
            tcb_eff_prio[i] = tcb_base_prio[i];
        else if (tcb_fault[i] == FAULT_CRIT)
            tcb_eff_prio[i] = tcb_base_prio[i] + 7;  // Boost
        else
            tcb_eff_prio[i] = 0;  // Isolated
    end
end
```

**Phase 2: Eligibility Check (Combinational Wires)**
```verilog
wire t0_valid = (tcb_state[0] == READY) && 
                (tcb_fault[0] != FAULT_ISO) && 
                (tcb_running_mask[0] == 0);
// Repeated for t1_valid, t2_valid, t3_valid
```

**Phase 3: Global Best Selection (Two-Level Tree)**
```verilog
wire [1:0] best01 = (tcb_eff_prio[0] >= tcb_eff_prio[1]) ? 0 : 1;
wire [1:0] best23 = (tcb_eff_prio[2] >= tcb_eff_prio[3]) ? 2 : 3;
wire [1:0] global_best = (tcb_eff_prio[best01] >= tcb_eff_prio[best23]) 
                         ? best01 : best23;
```

**Phase 4: Core Dispatch (Combinational → Clocked Commit)**
```verilog
always @(*) begin
    for (n = 0; n < 4; n = n + 1) begin
        if (core_idle[n] && t_valid[n]) begin
            core_enable[n] = 1;
            core_task_valid[n] = 1;
        end
    end
end

always @(posedge clk) begin
    if (core_task_valid[n]) begin
        tcb_state[coreN_task_id] <= RUNNING;
        tcb_running_mask[coreN_task_id][n] <= 1;
    end
end
```

**Phase 5: Fault Handling (Clocked)**
```verilog
always @(posedge clk) begin
    for (i = 0; i < 4; i = i + 1) begin
        if ((tcb_running_mask[i] & core_fault) != 0) begin
            tcb_fault_cnt[i] <= tcb_fault_cnt[i] + 1;
            
            if (tcb_fault_cnt[i] < 3)
                tcb_fault[i] <= FAULT_CRIT;  // Priority boost
            else begin
                tcb_fault[i] <= FAULT_ISO;
                tcb_state[i] <= ISOLATED;    // Permanent removal
            end
        end
    end
end
```

**Phase 6: Task Completion (Clocked)**
```verilog
always @(posedge clk) begin
    for (i = 0; i < 4; i = i + 1) begin
        if ((tcb_running_mask[i] & core_task_done) != 0) begin
            tcb_state[i] <= READY;
            tcb_running_mask[i] <= 4'b0000;  // Release core
        end
    end
end
```

### Dual-Port IMEM Organization

Memory access pattern for 4 cores with 2 dual-port BRAM blocks:

```
Clock Cycle N:
  IMEM Block 0 (Dual-Port):
    Port A: Core 0 fetches instruction
    Port B: Core 1 fetches instruction
  
  IMEM Block 1 (Dual-Port):
    Port A: Core 2 fetches instruction
    Port B: Core 3 fetches instruction

Total IMEM Stalls = 0 (if cores access different blocks)
Contention Stalls = Occurs only when both cores in a pair access same address
```

**Resource Reduction:**
```
Traditional (4 dedicated):  4 BRAM blocks
Proposed (2 dual-port):     2 BRAM blocks
Savings:                    50% BRAM reduction
```

### Latency Hiding via Bus Arbiter

When a core is stalled due to DMEM contention:

1. **Detection:** `arb_stall` signal asserted for waiting core
2. **HSE Response:** Issues thread rotation pulse to stalled core
3. **Context Switch:** Core switches to alternate hardware task (different PC/register bank)
4. **Continuation:** Core executes non-blocked task while original task waits for bus
5. **Completion:** When bus becomes available, core returns to original task

This ensures **sustained instruction throughput** even under memory contention.

## Performance Results

### Speedup Analysis

Performance measured across single-core, dual-core, and quad-core configurations with identical 4-task workload:

| Configuration | Latency (cycles) | Instructions/Core | IMEM Stall (Total) | Speedup |
|---------------|------------------|-------------------|--------------------|---------|
| Single-Core   | 196              | 196               | 0                  | 1.00×   |
| Dual-Core     | 112              | 98, 98            | 24                 | 1.75×   |
| Quad-Core     | 56               | 49×4              | 68                 | **3.48×** |

**Speedup Formula:**
```
Speedup(N) = T_exec(1) / T_exec(N) = 196 / 56 = 3.48×
```

The quad-core achieves **near-linear scaling** (ideal = 4×, actual = 3.48×). The deviation is primarily due to:
- Instruction memory arbitration contention (68 stall cycles)
- Task granularity (uneven workload distribution)

### Comparison with Prior Work

**Single-Core Comparison:**

| Architecture | LUTs | Flip-Flops |
|--------------|------|------------|
| HwSA_RTOS [2] | 4,476 | 2,664 |
| A.P. FFT RISC-V [11] | 1,897 | 361 |
| MicroBlaze [12] | 1,913 | 1,627 |
| ARM Cortex-M3 [13] | 13,844 | 6,378 |
| **Proposed (Single-Core)** | **962** | **72** |

**Quad-Core Comparison:**

| Architecture | LUTs | Flip-Flops | BRAM |
|--------------|------|------------|------|
| LEON3 Fault-Tolerant [14] | 19,853 | 8,425 | — |
| HwSA_RTOS (4 instances) [9] | 12,866 | 8,367 | — |
| **Proposed (Quad-Core)** | **4,212** | **158** | **4** |

The proposed architecture achieves **67% lower LUT usage** and **98% lower flip-flop usage** compared to RTOS-based designs.

### IMEM Stall Reduction (Dual-Port vs Single-Port)

| Design | Total IMEM Stalls (Quad-Core) | Speedup |
|--------|-------------------------------|---------|
| Single-Port IMEM | 196 cycles | 3.06× |
| **Dual-Port IMEM** | **68 cycles** | **3.48×** |

Dual-port design reduces stalls by **65%**, improving overall speedup by **13.7%**.

## Use Cases

This architecture is optimized for:

1. **Real-Time Signal Processing**
   - Multi-channel audio/video processing
   - Sensor fusion in autonomous systems
   - Software-defined radio (SDR) baseband processing

2. **Edge AI Inference**
   - Parallel execution of multiple neural network layers
   - Multi-model inference pipelines
   - Low-latency object detection/classification

3. **Cyber-Physical Systems**
   - Industrial control systems with deterministic timing
   - Robotics motor control + vision processing
   - Aerospace/automotive safety-critical applications

4. **Embedded Control Systems**
   - Multi-task FPGA-based controllers
   - Hard real-time scheduling without RTOS overhead
   - Fault-tolerant operation with automatic task isolation

## Known Limitations

1. **Instruction Memory Contention**
   - Dual-port design reduces but does not eliminate IMEM arbitration stalls
   - Cores sharing the same IMEM block may experience fetch delays
   - Impact: ~12% performance loss compared to ideal linear scaling

2. **Fixed Priority Bus Arbiter**
   - DMEM access uses static priority (Core 0 > Core 1 > Core 2 > Core 3)
   - Lower-priority cores may experience starvation under heavy memory load
   - Mitigation: Latency hiding via thread rotation

3. **Limited to 4 Tasks per Core**
   - Each core supports 4 hardware task contexts (banked register sets)
   - Expanding beyond 4 requires additional register file BRAM

4. **Static Base Priorities**
   - Task priorities assigned at reset and remain fixed
   - Current design does not support runtime priority adjustment

5. **No Cache Hierarchy**
   - Direct BRAM access without L1/L2 caches
   - High memory bandwidth workloads may saturate bus arbiter

## Future Work

1. **Cached Instruction Memory**
   - Implement small instruction caches per core to reduce IMEM arbitration
   - Expected improvement: 15–25% latency reduction

2. **Dynamic Priority Adjustment**
   - Extend HSE to support runtime priority modification based on system state
   - Enable adaptive scheduling for time-varying workloads

3. **Round-Robin DMEM Arbiter**
   - Replace fixed-priority arbiter with round-robin or weighted fair queuing
   - Eliminate potential core starvation

4. **N-Core Scalability**
   - Generalize architecture to support 8-core, 16-core configurations
   - Investigate hierarchical scheduling for large core counts

5. **Hardware Performance Counters**
   - Add per-core counters for executed instructions, stall cycles, cache misses
   - Enable runtime profiling and workload characterization

6. **Power Gating**
   - Implement clock gating for idle cores to reduce dynamic power
   - Explore voltage-frequency scaling for energy efficiency

## References

[1] I. Zagan and V. G. Gaitan, "Custom Soft-Core RISC Processor Validation Based on Real-Time Event Handling Scheduler FPGA Implementation," *IEEE Access*, vol. 11, pp. 32661-32685, 2023.

[2] I. Zagan and V. Gaitan, "System verification and FPGA implementation of hardware preemptive scheduler for RISC-V processor," *IEEE Access*, vol. 13, pp. 103019–103032, 2025.

[3] M. Vaithianathan et al., "High-performance computing with FPGA-based parallel data processing systems," *Proc. ICSCNA*, 2024.

[4] S. Wu et al., "Task Mapping and Scheduling on RISC-V MIMD Processor With Vector Accelerator Using Model-Based Parallelization," *IEEE Access*, vol. 12, pp. 33739-33756, 2024.

[5] K. Kırali and C. B. Fidan, "Implementation of FPGA based 32-bit RISC-V processor," *Eng. Sci. Technol. Int. J.*, vol. 70, 2025.

[9] S. Shukla and K. C. Ray, "A Low-Overhead Reconfigurable RISC-V Quad-Core Processor Architecture for Fault-Tolerant Applications," *IEEE Access*, vol. 10, pp. 44111-44126, 2022.

[14] A. M. Keller and M. J. Wirthlin, "Benefits of complementary SEU mitigation for the LEON3 soft processor on SRAM-based FPGAs," *IEEE Trans. Nucl. Sci.*, vol. 64, no. 1, pp. 519–528, 2017.

## Authors

**Yash Suthar** and **Vedh Mungelwar**

---
