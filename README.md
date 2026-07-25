# UART on Sky130

A fully verified UART (Universal Asynchronous Receiver Transmitter) implemented and taped out on SkyWater 130nm (Sky130) open source process using open source EDA tools.

## Features

- Configurable baud rate via `baud_div` input
- 8-bit data, 1 start bit, 1 stop bit
- Full duplex TX and RX
- Loopback verified

## Tools used

| Tool | Purpose |
|------|--------|
| Icarus Verilog | RTL simulation |
| GTKWave | Waveform viewing |
| Yosys | Synthesis (468 cells) |
| OpenLane | Full RTL-to-GDSII flow |
| Magic | DRC verification |
| Netgen | LVS verification |
| KLayout | GDSII viewing |
| Sky130 PDK | SkyWater 130nm process |

## Results

| Check | Result |
|-------|--------|
| DRC violations | 0 |
| LVS | Clean |
| Antenna violations | 0 |
| Setup violations | 0 |
| Hold violations | 0 |
| Chip area | 0.0155 mm² |
| Critical path | 1.2 ns (8.8 ns slack at 100 MHz) |

## Directory structure

```
uart-sky130/
├── rtl/
│   ├── uart_top.v    # Top-level UART module
│   ├── uart_tx.v     # Transmitter
│   └── uart_rx.v     # Receiver
├── tb/
│   └── tb_uart.v     # Testbench
├── openlane_run/     # OpenLane flow outputs
├── .gitignore
└── README.md
```

## Flow

```
RTL (Verilog) → Simulation → Synthesis (Yosys) → PnR (OpenLane) → GDSII
```

## License

Open source — feel free to use and modify.
