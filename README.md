# UART Project

A simple UART (Universal Asynchronous Receiver/Transmitter) implementation in Verilog for the Basys 3 FPGA board. This project demonstrates a full transmit-and-receive data path with FIFO buffering, baud-rate generation, input debouncing, and LED status indicators.

---

## Table of Contents

1. [Features](#features)  
2. [Repository Layout](#repository-layout)  
3. [Top-Level I/O](#top-level-io)  
4. [Module Descriptions](#module-descriptions)  
5. [Prerequisites](#prerequisites)  
6. [Usage](#usage)  
   - [Simulation](#simulation)  
   - [Synthesis & Implementation](#synthesis--implementation)  
7. [Basys 3 Constraints](#basys-3-constraints)  
8. [License](#license)  

---

## Features

- **Baud-rate generator** (`mod_m_counter.v`)  
- **UART transmitter** (`uart_tx.v`)  
- **UART receiver** (`uart_rx.v`) with stop-bit & data-bit framing  
- **FIFO buffer** (`fifo.v`) for decoupling producer/consumer rates  
- **Debounce logic** (`debounce.v`) for noisy button inputs  
- **LED blink/status** (`led_blink.v`) for visual feedback  
- **Top-level integration** (`uart_top.v`) tying all pieces together  

---

## Repository Layout

```
├── debounce.v            # Debounce filter for push-buttons
├── fifo.v                # Simple FIFO for data buffering
├── led_blink.v           # Heartbeat/status LED flasher
├── mod_m_counter.v       # Generic modulo-N counter (baud generator)
├── uart_rx.v             # UART receiver (DBIT=8, SB_TICK=16)
├── uart_tx.v             # UART transmitter (DBIT=8, SB_TICK=16)
├── uart_top.v            # Top-level wrapper
├── constraints.xdc       # Basys3 pinout & IO standards
└── README.md             # This file
```

---

## Top-Level I/O

```verilog
module uart_top(
  input        clock,        // system clock (100 MHz)
  input        reset,        // active-high synchronous reset
  input        tx_fifo_wr,   // write-enable for TX FIFO
  input  [7:0] w_data,       // data bus into TX FIFO
  input        read_uart,    // pop-enable for RX FIFO / LED update
  input        rx,           // serial data input (RX pin)
  output       tx_full,      // high when TX FIFO is full
  output wire  tx,           // serial data output (TX pin)
  output [7:0] uart_led      // LED bank driven by RX data
);
```

---

## Module Descriptions

- **mod_m_counter.v**  
  Generates a tick at clock / M (e.g. M = 54 for 115200 baud @ 100 MHz).  

- **uart_tx.v**  
  Serializes 8-bit data from a FIFO, adding start & stop bits.  

- **uart_rx.v**  
  Samples incoming serial bits, reconstructs bytes, and raises rx_done_tick.  

- **fifo.v**  
  Parameterizable depth buffer with separate read/write pointers.  

- **debounce.v**  
  Filters mechanical push-button chatter for stable logic transitions.  

- **led_blink.v**  
  Simple counter to blink an LED at a visible rate (heart-beat).  

- **uart_top.v**  
  Instantiates all submodules, connects FIFOs, controls LEDs, and ties to board I/O.  

---

## Prerequisites

- **Vivado 2023.2** (or later)  
- **Basys 3** board files & device drivers  
- Basic familiarity with Verilog and FPGA synthesis  

---

## Usage

### Simulation

1. Create a testbench (e.g. tb_uart_top.v) that:  
   - Drives clock (100 MHz) and reset.  
   - Stimulates tx_fifo_wr & w_data to send bytes.  
   - Toggles rx to feed back transmitted bits (loopback).  
   - Monitors uart_led or RX-FIFO outputs.  

2. Run behavioral simulation:  
   ```tcl
   open_project uart_project
   add_files *.v tb_uart_top.v
   launch_simulation
   ```

3. Check waveforms: verify start/stop bits, data integrity, FIFO flags.

---

### Synthesis & Implementation

1. Open Vivado & create a new RTL project.  
2. Add all .v files and constraints.xdc.  
3. Set uart_top as the top module.  
4. Run Synthesis → Implementation → Generate Bitstream.  
5. Program Basys 3 via USB.

---

## Basys 3 Constraints

```xdc
## Clock & reset
set_property PACKAGE_PIN W5   [get_ports clock]
set_property IOSTANDARD LVCMOS33 [get_ports clock]
set_property PACKAGE_PIN U18  [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## UART pins
set_property PACKAGE_PIN A9   [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports rx]
set_property PACKAGE_PIN B9   [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]

## FIFO & control buttons
set_property PACKAGE_PIN T8   [get_ports tx_fifo_wr]
set_property IOSTANDARD LVCMOS33 [get_ports tx_fifo_wr]
set_property PACKAGE_PIN T9   [get_ports read_uart]
set_property IOSTANDARD LVCMOS33 [get_ports read_uart]

## LEDs
set_property PACKAGE_PIN U16  [get_ports {uart_led[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_led[*]}]
```

---

## License

This project is released under the MIT License. See LICENSE for details.
