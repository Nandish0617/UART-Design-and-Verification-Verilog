# UART Design and Verification using Verilog HDL

## 📌 Project Overview

This project implements and verifies a Universal Asynchronous Receiver-Transmitter (UART) communication system using Verilog/SystemVerilog HDL.

The design includes a UART Transmitter (TX), UART Receiver (RX), and Baud Rate Generator. A SystemVerilog testbench was developed to verify data transmission, reception, and error detection under different test conditions.

The project focuses on RTL design, functional verification, and simulation-based validation of a digital communication interface.

## 🎯 Objectives

- Design a UART transmitter using Verilog HDL.
- Design a UART receiver using Verilog HDL.
- Implement a baud rate generator.
- Develop a SystemVerilog verification testbench.
- Verify correct transmission and reception of 8-bit data.
- Test multiple UART communication scenarios.
- Verify framing error detection.
- Analyze simulation waveforms and output results.

## 🏗️ Design Architecture

The UART system consists of the following major blocks:

### 1. Baud Rate Generator
Generates the timing/baud tick required for UART transmission and reception.

### 2. UART Transmitter
- Accepts 8-bit parallel data.
- Converts the data into serial format.
- Generates the UART frame consisting of:
  - Start bit
  - 8 data bits
  - Stop bit

### 3. UART Receiver
- Detects the start bit.
- Samples incoming serial data.
- Reconstructs the received 8-bit data.
- Indicates completion of reception.
- Detects framing errors.

### 4. Verification Testbench
The SystemVerilog testbench drives different test cases and checks the transmitter and receiver outputs automatically.

## 📂 Project Structure

```text
UART-Design-and-Verification/
│
├── rtl/
│   ├── baud_generator.sv
│   ├── uart_tx.sv
│   └── uart_rx.sv
│
├── testbench/
│   └── testbench.sv
│
├── screenshots/
│   ├── simulation_output.png
│   └── waveform.png
│
└── README.md
