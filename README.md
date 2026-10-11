# Homework 12 — MicroBlaze DMA Frame Capture

Frame capture system based on MicroBlaze, AXI DMA and BRAM.

## Task

The design receives an external frame:

- Resolution: `320 x 200`
- Pixel size: `8 bit`
- Frame size: `64,000 bytes`
- AXI4-Stream width: `32 bit`
- Number of AXI words per frame: `16,000`

Capture starts only after a button press handled by MicroBlaze.

---

## Architecture

```text
External 8-bit data
        |
        v
 frame_rx_axis
        |
        v
 Async FIFO
   8-bit -> 32-bit
        |
        v
 AXI4-Stream
        |
        v
 AXI DMA S2MM
        |
        v
 AXI BRAM Controller
        |
        v
 64 KiB BRAM