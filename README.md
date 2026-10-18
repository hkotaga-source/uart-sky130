# UART on Sky130

A UART (Universal Asynchronous Receiver Transmitter) designed in Verilog and implemented through the full RTL-to-GDSII flow on the SkyWater 130nm (Sky130) open-source process, using open-source EDA tools. The design passes DRC, LVS, antenna and multi-corner timing signoff.

## Features

- Configurable baud rate via `baud_div` input (one bit lasts `baud_div + 1` clock cycles)
- 8-bit data, 1 start bit, 1 stop bit, LSB first
- Full duplex TX and RX
- 2-flop synchronizer on the `rx` input to prevent metastability
- Receiver samples each bit in the middle, rejects false start bits (glitches) and frames with a bad stop bit

## Tools used

| Tool | Purpose |
|------|--------|
| Icarus Verilog | RTL simulation |
| GTKWave | Waveform viewing |
| Yosys | Synthesis |
| OpenLane | Full RTL-to-GDSII flow |
| Magic | DRC verification |
| Netgen | LVS verification |
| KLayout | GDSII viewing |
| Sky130 PDK | SkyWater 130nm process (`sky130_fd_sc_hd` cells) |

## Verification

The testbench (`tb/tb_uart.v`) is self-checking and prints `ALL TESTS PASSED` or the number of failures. It runs 621 checks:

- Loopback (TX to RX) of edge-case bytes `00, FF, 55, AA` plus 200 random bytes, sent back to back
- Repeated at three baud settings (`baud_div` = 3, 10, 103)
- `busy` goes high when transmission starts
- A short glitch on `rx` does not produce a false byte
- A frame with a bad stop bit is rejected
- The receiver recovers and receives correctly after a bad frame

Every wait has a timeout, so a bug causes a failure instead of a hang.

Run it:

```
iverilog -o sim tb/tb_uart.v rtl/*.v
vvp sim
```

## Signoff results

Clock: 100 MHz (10 ns period). Results from `openlane_run/runs/uart_run/reports/`.

| Check | Result |
|-------|--------|
| Magic DRC violations | 0 |
| KLayout DRC violations | 0 |
| LVS | Clean (589 nets matched) |
| Antenna violations | 0 |
| Setup timing | Met at all corners, worst slack 1.46 ns (slow corner) |
| Hold timing | Met at all corners, worst slack 0.11 ns (fast corner) |
| Cells after synthesis | 454 |
| Die area | 0.0155 mm² |
| Core utilization | 40% |

> Note: these results are from the run before the `rx` synchronizer was added. Re-run OpenLane to update them for the current RTL.

## Reproducing the flow

The OpenLane configuration is in `openlane_run/config.json`. From the OpenLane environment:

```
./flow.tcl -design /path/to/uart-sky130/openlane_run -tag uart_run -overwrite
```

## Directory structure

```
uart-sky130/
├── rtl/
│   ├── uart_top.v        # Top-level UART module
│   ├── uart_tx.v         # Transmitter
│   └── uart_rx.v         # Receiver (with input synchronizer)
├── tb/
│   └── tb_uart.v         # Self-checking testbench
├── openlane_run/
│   ├── config.json       # OpenLane configuration
│   └── runs/uart_run/    # Signoff reports
├── .gitignore
└── README.md
```

## Flow

```
RTL (Verilog) → Simulation → Synthesis (Yosys) → Floorplan → Placement → CTS → Routing → Signoff (DRC, LVS, STA) → GDSII
```

## License

Open source — feel free to use and modify.
