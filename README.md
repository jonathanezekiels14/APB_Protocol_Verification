# AMBA APB Master – SystemVerilog Verification

A fully layered, OOP-based SystemVerilog verification environment for an AMBA APB Master controller. The testbench implements constrained-random stimulus generation, dual active drivers (bridge + slave), passive monitoring, a self-checking scoreboard, functional coverage collection, and a set of concurrent SVA assertions bound directly into the DUT.

---

## Repository Structure

```
.
├── src/
│   └── apb_master.sv                # DUT – AMBA APB Master RTL (FSM)
├── tb/
│   ├── defines.svh                  # Timescale, DATA_WIDTH, ADDR_WIDTH, num_of_transactions
│   ├── apb_package.sv               # Package wrapper – includes all TB classes
│   ├── apb_interface.sv             # Clocked interface (BRIDGE_DRV, SLAVE_DRV, MON modports)
│   ├── apb_transaction.sv           # Base + directed transaction classes (write, read, idle)
│   ├── apb_generator.sv             # Constrained-random generator (bridge + slave transactions)
│   ├── apb_bridge_driver.sv         # Active bridge-side driver + reset handling
│   ├── apb_slave_driver.sv          # Active slave-side driver + wait state injection
│   ├── apb_referencemodel.sv        # Golden reference model → ref_2_scb mailbox
│   ├── apb_monitor.sv               # Passive APB bus observer → mon_2_scb / mon_2_cov
│   ├── apb_scoreboard.sv            # Self-checking scoreboard (compare())
│   ├── apb_coverage.sv              # Functional coverage (cg_apb_protocol covergroup)
│   ├── apb_assertions.sv            # Concurrent SVA assertions (bound into DUT)
│   ├── apb_environment.sv           # Environment – builds all components, forks threads
│   ├── apb_test.sv                  # Base test + directed tests + regression suite
│   └── apb_top.sv                   # Top module – DUT instantiation + bind + TB entry
├── docs/
│   └── APB_Project_Report.docx      # Full verification report
├── logs/
│   ├── apb_log.log                  # Questa SIM simulation log
│   └── transcript                   # Questa SIM transcript
├── coverage/
│   └── apb.ucdb                     # Merged coverage database
└── README.md
```

---

## Design Overview

The DUT (`apb_master`) translates upstream user-side transfer requests into the AMBA APB protocol using a 3-state registered FSM.

### Parameters

| Parameter    | Value | Description            |
|---|---|---|
| `ADDR_WIDTH` | 5     | APB address bus width  |
| `DATA_WIDTH` | 8     | APB data bus width     |

### FSM States

```
PRESETn (async)
     │
     ▼
  ┌──────┐   transfer=1   ┌───────┐  always   ┌────────┐
  │ IDLE │ ─────────────▶ │ SETUP │ ─────────▶ │ ACCESS │
  │ 2'b00│                │ 2'b01 │            │ 2'b11  │
  └──────┘                └───────┘            └────┬───┘
     ▲                                              │
     └──────────────────────────────────────────────┘
                        PREADY = 1
```

### Inputs (User / Bridge Side)

| Signal       | Width | Description |
|---|---|---|
| `PCLK`       | 1     | APB clock — all registers update on rising edge |
| `PRESETn`    | 1     | Active-low asynchronous reset |
| `transfer`   | 1     | Initiates a transfer when high in IDLE state |
| `write_read` | 1     | `1` = Write, `0` = Read |
| `addr_in`    | 5     | Target address (constrained to word-aligned) |
| `wdata_in`   | 8     | Write data |
| `strb_in`    | 1     | Write strobe (DATA_WIDTH/8 bits) |
| `PRDATA`     | 8     | Read data from slave |
| `PREADY`     | 1     | Slave ready — extends ACCESS phase when low |
| `PSLVERR`    | 1     | Slave error response |

### Outputs (APB Bus / User Side)

| Signal          | Width | Description |
|---|---|---|
| `PSEL`          | 1     | Slave select — asserted in SETUP and ACCESS |
| `PENABLE`       | 1     | Enable — asserted in ACCESS phase only |
| `PADDR`         | 5     | APB address bus |
| `PWRITE`        | 1     | Write control |
| `PWDATA`        | 8     | Write data bus |
| `PSTRB`         | 1     | Write strobe output |
| `rdata_out`     | 8     | Read data to user (latched from PRDATA on PREADY) |
| `transfer_done` | 1     | One-cycle pulse on transaction completion |
| `error`         | 1     | Error flag — set when PSLVERR=1 alongside PREADY |

---

## Protocol Timing

| Phase      | PSEL | PENABLE | Duration | Notes |
|---|---|---|---|---|
| **IDLE**   | 0    | 0       | Until `transfer=1` | Master waits for upstream request |
| **SETUP**  | 1    | 0       | Exactly 1 cycle | PADDR/PWRITE/PWDATA must be stable |
| **ACCESS** | 1    | 1       | 1+ cycles | Extended while `PREADY=0` |

> All bus signals (PADDR, PWRITE, PWDATA, PSTRB) **must remain stable** during the entire ACCESS phase while PREADY=0.

---

## Known DUT Bugs

Three functional bugs were identified and root-caused through scoreboard mismatches and SVA failures:

### Bug 1 — Data Pipeline Lag (Off-by-One)
The APB output `always` block evaluates `case(state)` instead of `case(next_state)`. This causes PADDR, PWRITE, PWDATA, and PSTRB to be driven **one clock cycle late** — arriving during ACCESS instead of SETUP as required by the APB specification.

- **Evidence:** Log shows `EXPECTED ADDR: 8 vs ACTUAL ADDR: c` — a systematic one-transaction shift. SVA `A_IDLE` fires **1,314 times**.
- **Fix:** Change the APB output block to evaluate `case(next_state)` so signals are driven in the SETUP phase.

### Bug 2 — Wait State Instability (PWDATA changes during ACCESS)
A direct consequence of Bug 1 — PWDATA is updated during the ACCESS phase while PREADY=0, violating the APB rule that write data must remain stable during wait states. Triggers the `A_DATA_STABLE` SVA.

- **Fix:** Resolved automatically by fixing Bug 1.

### Bug 3 — PENABLE Held One Extra Cycle
`{PENABLE, PSEL}` is driven directly from the registered `next_state` bits. When PREADY=1 causes `next_state=IDLE`, the register update only occurs on the **next** posedge — leaving PENABLE asserted for one extra clock cycle, risking spurious double-reads.

- **Fix:** Use a combinational assignment `PENABLE = (state == ACCESS)` rather than the registered next_state bit.

---

## Testbench Architecture

A fully layered OOP environment with 7 mailboxes connecting all components. Active and passive threads run concurrently via `fork...join_none`.

```
┌─────────────────────────────────────────────────────────────┐
│              apb_regression_test  (t_base · t_write · t_read)│
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                      apb_environment                         │
│                                                              │
│  ┌──────────────┐ gen_2_bridge  ┌──────────────────────────┐│
│  │ apb_generator├───────────────▶   apb_bridge_driver       ││
│  │              ├────────────────▶  apb_slave_driver        ││
│  └──────────────┘ gen_2_slave   └──────────┬───────────────┘│
│                                  drvb/s_2_ref│               │
│  ┌───────────────────────┐  ◀───────────────┘               │
│  │  apb_referencemodel   │──────────────────────────────┐   │
│  └───────────────────────┘       ref_2_scb               │   │
│                                                          │   │
│  ┌────────────────────────────┐                          │   │
│  │      apb_interface         │                          │   │
│  │  BRIDGE_DRV · SLAVE_DRV    │                          │   │
│  │         · MON              │                          │   │
│  └────────────┬───────────────┘                          │   │
│               │                                          │   │
│  ┌────────────▼────────────┐   ┌──────────────────────┐  │   │
│  │     DUT  (apb_master)   │──▶│    apb_monitor       │  │   │
│  │   IDLE→SETUP→ACCESS FSM │   │  (passive observer)  │  │   │
│  └─────────────────────────┘   └──────┬───────────────┘  │   │
│                         mon_2_scb     │    mon_2_cov      │   │
│                    ┌──────────────────┘         │         │   │
│  ┌─────────────────▼──────────────┐  ┌──────────▼───────┐│   │
│  │        apb_scoreboard  ◀───────┼──┤  apb_coverage    ││   │
│  │  compare() → PASS / FAIL       │  │  cg_apb_protocol ││   │
│  └────────────────────────────────┘  └──────────────────┘│   │
│                                                           │   │
│  ┌──────────────────────────────────────────────────────┐ │   │
│  │  apb_assertions (bind) – ERR_SLAVE_BUSY · A_IDLE … │ │   │
│  └──────────────────────────────────────────────────────┘ │   │
└─────────────────────────────────────────────────────────────┘
```

### Transaction Classes

| Class | Constraint | Purpose |
|---|---|---|
| `apb_bridge_transaction` (base) | 50% R / 50% W | Fully random baseline |
| `apb_trans_write` | `write_read = 1` | Write-only directed test |
| `apb_trans_read` | `write_read = 0` | Read-only directed test |
| `apb_trans_idle` | `transfer = 0` | Idle coverage (disabled in current regression) |
| `apb_slave_transaction` | PSLVERR 5%, wait 80% zero | Slave response model |

---

## SVA Assertions

| Assertion | Property | Result |
|---|---|---|
| `ERR_SLAVE_BUSY` | PSEL&&PENABLE&&!PREADY \|=> $stable(PADDR)&&$stable(PWRITE) | ✅ Covered |
| `A_DATA_STABLE` | PSEL&&PENABLE&&PWRITE&&!PREADY \|=> $stable(PWDATA)&&$stable(PSTRB) | ✅ Covered |
| `A_CHECK_ACCESS` | PSEL&&!PENABLE \|=> PSEL&&PENABLE | ✅ Covered |
| `A_IDLE` | $rose(transfer) \|=> PSEL | ❌ **1,314 failures** (Bug 1) |
| `A_PREADY_CAME` | PSEL&&!PENABLE \|=> ##[1:100] PREADY | ✅ Covered |

---

## Simulation Results

```
─────────────────────────────────────────────
          Regression Summary
─────────────────────────────────────────────
Total Scoreboard Comparisons : 3,000
Passed                       : 172   (5.7%)
Failed                       : 2,828 (94.3%)
SVA A_IDLE Failures          : 1,314
 *** 3 Functional Bugs Found ***
─────────────────────────────────────────────
Simulation End Time          : 316,030 ns
Overall Code Coverage        : 90.55%
─────────────────────────────────────────────
```

| Test | Class | Constraint | Transactions | Pass | Fail |
|---|---|---|---|---|---|
| t0 | `apb_test` (base) | 50% R / 50% W | 1,000 | 37 | 963 |
| t1 | `apb_write_test` | Write only | 1,000 | 0 | 1,000 |
| t2 | `apb_read_test` | Read only | 1,000 | 135 | 865 |

> All failures are directly attributable to the 3 documented RTL bugs. No testbench defects were found.

---

## Coverage Report

Generated from `apb.ucdb` — Questa SIM v10.6c, July 16, 2026.

| Coverage Type  | Bins | Hits | Misses | Coverage |
|---|---|---|---|---|
| Statements     | 46   | 45   | 1      | **97.82%** |
| Branches       | 31   | 30   | 1      | **96.77%** |
| FEC Conditions | 10   | 9    | 1      | **90.00%** |
| Toggles        | 148  | 135  | 13     | **91.21%** |
| FSMs           | 7    | 6    | 1      | **87.50%** |
| FSM States     | 3    | 3    | 0      | **100.00%** |
| FSM Transitions| 4    | 3    | 1      | **75.00%** |
| Assertions     | 5    | 4    | 1      | **80.00%** |
| **Total**      | —    | —    | —      | **90.55%** |

> The missed FSM transition is IDLE→IDLE (idle test disabled). The missed assertion is `A_IDLE` (Bug 1). All three FSM states were visited.

---

## How to Run

### Prerequisites
- Mentor Questa SIM — tested on v10.6c
- SystemVerilog-2012 compatible simulator

### Compile & Simulate

```bash
# Compile (order matters — interface and package first)
vlog -sv tb/apb_interface.sv \
        tb/apb_package.sv \
        src/apb_master.sv \
        tb/apb_top.sv

# Run simulation with coverage + assertions
vsim work.top -coverage -assertdebug -c \
  -do "coverage save -onexit -assert -directive -cvg -codeAll apb.ucdb; run -all; exit"

# Generate HTML coverage report
vcover report -html apb.ucdb -htmldir covReport -details
```

### Run Specific Test

```bash
# Override default test by passing +UVM_TESTNAME or editing apb_top.sv
vsim work.top -coverage -c \
  +define+TEST=apb_write_test \
  -do "run -all; exit"
```

### View Coverage
Open `covReport/index.html` in a browser after running the coverage commands above.

---

## Tool Information

| Item | Details |
|---|---|
| Simulator | Mentor Questa SIM v10.6c |
| Language | SystemVerilog (IEEE 1800-2012) |
| Protocol | AMBA 3 APB |
| Coverage DB | `apb.ucdb` |
| Simulation End Time | 316,030 ns |
| Clock Period | 20 ns |
| Regression Tests | 3 (t_base, t_write, t_read) |
| Total Transactions | 3,000 |
