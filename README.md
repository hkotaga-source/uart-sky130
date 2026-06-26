# UART on Sky130

A fully verified UART (Universal Asynchronous Receiver Transmitter) implemented 
and taped out on SkyWater 130nm (Sky130) open source process using open source EDA tools.

## Features
- Configurable baud rate via baud_div input
- 8-bit data, 1 start bit, 1 stop bit
- Full duplex TX and RX
- Loopback verified

## Tools Used
- Icarus Verilog — RTL simulation
- GTKWave — waveform viewing  
- Yosys — synthesis (468 cells)
- OpenLane — full RTL to GDSII flow
- Magic — DRC verification
- Netgen — LVS verification
- KLayout — GDSII viewing
- Sky130 PDK — SkyWater 130nm process

## Results
- DRC violations: 0
- LVS: Clean
- Antenna violations: 0
- Setup violations: 0
- Hold violations: 0
- Chip area: 0.0155 mm²
- Critical path: 1.2ns (8.8ns slack at 100MHz)

## Directory Structure

## Flow
RTL (Verilog) → Simulation → Synthesis (Yosys) → PnR (OpenLane) → GDSII
