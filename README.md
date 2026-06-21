# Traffic Light Controller (FSM) — Zybo Z7-10

A traffic-light controller for a **highway / farm-road intersection**, built as a
**6-state Moore finite-state machine** in Verilog and deployed on the Digilent
**Zybo Z7-10** FPGA. The highway has priority; the farm road only gets a green
when a vehicle is detected, and the highway always keeps a minimum green time.

**▶ Live demo:** open [`tlc-demo.html`](tlc-demo.html) (or host it — see below).

## State diagram

![Traffic Light FSM state diagram](state_diagram.svg)

## How it works

Two 2-bit signals drive the lights, one per road:

| Encoding | Meaning |
|---|---|
| `2'b01` | Red |
| `2'b10` | Yellow |
| `2'b11` | Green |

A 31-bit counter measures how long the machine has been in the current state; the
FSM compares it against per-phase thresholds to decide when to move on. A 3-flop
**synchronizer** cleans the asynchronous reset button and farm-road sensor before
they reach the logic.

### States

| State | Highway | Farm road | Leaves when |
|---|---|---|---|
| `S0` | Red | Red | 1 s all-red safety gap elapses |
| `S1` | **Green** | Red | ≥ 30 s **and** a farm-road car is detected |
| `S2` | **Yellow** | Red | 3 s |
| `S3` | Red | Red | 1 s all-red safety gap elapses |
| `S4` | Red | **Green** | ≥ 3 s **and** (car has left **or** 18 s cap reached) |
| `S5` | Red | **Yellow** | 3 s, then back to `S0` |

So with no traffic on the farm road the highway simply stays green; a waiting car
trips the sensor and, after the minimum green, the machine hands the intersection
over and back.

## Modules

| File | Role |
|---|---|
| `tlc_fsm.v` | the 6-state Moore FSM (next-state + output logic) |
| `tlc_controller_ver1.v` | top module: 31-bit counter + synchronizers + FSM, board I/O |
| `synchronizer.v` | 3-flop synchronizer for async inputs |
| `tlc_fsm_tb.v` | self-checking testbench (drives the counter to each threshold) |
| `tlc_controller.xdc` | Zybo Z7-10 pin constraints |

## Simulate (Icarus Verilog)

```bash
iverilog -g2012 -o run tlc_fsm.v tlc_fsm_tb.v
vvp run
```

Expected: every state and transition is checked, ending with
`TLC FSM: ALL TESTS PASSED`. (The testbench drives `Count` directly to each
threshold, so a full cycle is verified in a few hundred nanoseconds instead of the
real tens of seconds.)

## On the FPGA (Vivado, Zybo Z7-10)

Add the three RTL files, set the top module to `tlc_controller_ver1`, add
`tlc_controller.xdc`, and generate the bitstream. The highway/farm signals drive
the board LEDs (red = one LED, yellow = the other, green = both), the reset and
farm-sensor map to push-buttons, and the FSM state is exposed on PMOD JB for debug.

**Clock note:** the phase timing is calibrated for a **50 MHz** clock
(`50_000_000` counts = 1 s, and 30 s fits in the 31-bit counter). Pin `K17` on the
Zybo is the **125 MHz** system clock, so to get the intended real-time durations,
feed the controller a 50 MHz clock from a *Clocking Wizard* (MMCM) IP. Clocking
directly at 125 MHz runs every phase 2.5× faster (and 30 s would overflow the
31-bit counter, so it would also need a wider counter).

## Live demo

[`tlc-demo.html`](tlc-demo.html) runs the exact FSM in the browser over a drawn
intersection — highway cars flow on green, a farm car appears when you press
*Farm car waiting*, and a panel shows the current state, both light colors, the
time in state, and the condition being waited on. A speed control lets you watch a
full cycle quickly. To publish a shareable link, enable **GitHub Pages** (repo
Settings → Pages → deploy from `main`); the demo is then at
`https://<user>.github.io/traffic-light-controller-fsm/tlc-demo.html`.

## Board

![Zybo Z7-10](zyboz10.jpg)
