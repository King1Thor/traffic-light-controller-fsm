# Traffic Light Controller — Full System with Pedestrian Crossing (Zybo Z7-10)

A complete, board-ready traffic-light controller for a **highway / farm-road
intersection with a pedestrian crossing**, built around an **8-state Moore FSM**
in Verilog and running on the Digilent **Zybo Z7-10** FPGA. The highway is the
default green; a farm-road car or a pedestrian press is latched and served safely
at the next all-red. Real-time timing comes from the 125 MHz board clock.

**Live demo:** open [`tlc-demo.html`](tlc-demo.html) (host it for a shareable link).

## State diagram

![Traffic Light FSM](state_diagram.svg)

## What happens when someone presses a button

**Farm-road car button (BTN0):** the press is debounced and **latched** (a tap is
enough). The highway keeps its green until it has been green for at least **30 s**,
then goes **YELLOW → all-RED → farm GREEN** ("request served"), holds the farm
green 3–18 s depending on traffic, then **YELLOW → all-RED → highway GREEN**.

**Pedestrian button (BTN1):** also latched, and given **priority** at the decision
point so people don't wait through a vehicle cycle. The highway finishes its
minimum green, everything goes red, the **WALK** light turns on for **8 s**, then
the **DON'T-WALK** light **flashes** for a **5 s** clearance, and control returns
to the highway. All vehicle lights stay red the entire time pedestrians cross.

A press never instantly flips red to green — it *requests* the change, and the FSM
hands the intersection over safely after the minimum green, like a real
demand-actuated signal with a pedestrian phase.

### Phases (8 states)

| State | Highway | Farm | Pedestrian | Duration |
|---|---|---|---|---|
| `S0` | Red | Red | Don't-walk | 1 s all-red |
| `S1` | **Green** | Red | Don't-walk | >= 30 s, until a car/pedestrian waits |
| `S2` | **Yellow** | Red | Don't-walk | 3 s |
| `S3` | Red | Red | Don't-walk | 1 s (decision point) |
| `S4` | Red | **Green** | Don't-walk | 3 s min / 18 s max |
| `S5` | Red | **Yellow** | Don't-walk | 3 s |
| `S6` | Red | Red | **WALK** | 8 s |
| `S7` | Red | Red | Don't-walk **flashing** | 5 s clearance |

At `S3` the priority is **pedestrian → farm car → back to highway**.

## What you see on the bare board (nothing wired)

- **RGB LED LD6** shows the **highway light in true colour**: **green → yellow →
  red** as the highway cycles, and **blue** while pedestrians are crossing.
- **The 4 LEDs (LD0–LD3)** are a **binary countdown** of seconds left in the phase.
- **BTN0** = farm-road car, **BTN1** = pedestrian, **BTN3** = reset.
- **SW0 up** = demo speed (~15× faster) so you don't wait 30 s per cycle.

So right after programming: LD6 is green (highway). Flip **SW0 up**, press **BTN1**
— watch the countdown finish, LD6 turn **blue** (people walking), then return to
green. Press **BTN0** to see the highway go green → yellow → red and the farm road
take over.

## The full intersection (wire 8 LEDs to Pmod JA)

For the real thing, wire LEDs (each: JA pin → 330 Ω → LED → GND):

| Pmod JA | Light |   | Pmod JA | Light |
|---|---|---|---|---|
| JA1 | Highway RED    | | JA4 | Farm RED |
| JA2 | Highway YELLOW | | JA7 | Farm YELLOW |
| JA3 | Highway GREEN  | | JA8 | Farm GREEN |
| JA9 | WALK           | | JA10| DON'T-WALK |

## System architecture

```
 125 MHz Clk -> tlc_prescaler -> tick (1 Hz, or ~15x for demo via sw[0])
 btn[3] -> debounce -> reset
 btn[0] -> debounce -> farm request latch -> farmSensor ┐
 btn[1] -> debounce -> ped  request latch -> pedReq     ┤
                              seconds counter -> tlc_fsm (8-state Moore)
                                                    | state, signals
                                                    v
                                  tlc_lights -> highwayLights / farmLights {R,Y,G}
                                  walk / dontwalk lamps   RGB LD6 (true colour)
                                  led[3:0] countdown
```

| File | Role |
|---|---|
| `rtl/tlc_top.v` | board top: clock, buttons, lights, RGB, countdown, pedestrian |
| `rtl/tlc_fsm.v` | 8-state Moore FSM (highway + farm + pedestrian), timed in seconds |
| `rtl/tlc_prescaler.v` | 125 MHz -> 1-second tick (or ~15x faster for demos) |
| `rtl/tlc_debounce.v` | synchronize + debounce a push button, with edge detect |
| `rtl/tlc_lights.v` | decode a road's signal to discrete R/Y/G lamps |
| `sim/tlc_top_tb.v` | self-checking testbench (farm + pedestrian) |
| `xdc/tlc_top.xdc` | Zybo Z7-10 pin constraints |

## Simulate

```bash
iverilog -g2012 -o run sim/tlc_top_tb.v rtl/*.v
vvp run     # -> TLC FULL SYSTEM (+pedestrian): ALL TESTS PASSED
```

## Build on the FPGA (Vivado, Zybo Z7-10)

Add `rtl/*.v` as design sources and `sim/tlc_top_tb.v` as a sim source, set the top
module to **`tlc_top`**, add `xdc/tlc_top.xdc`, then Synthesis → Implementation →
**Generate Bitstream** → program. The design self-initializes (power-on register
values), so it starts in all-red without a reset press, and timing runs directly
off the 125 MHz clock via the prescaler — no MMCM/Clocking-Wizard IP needed.

> The Pmod **JA** pins are the standard Zybo Z7-10 assignments; if your board
> revision flags one, swap it for the JA pin in your board's master XDC.

## Live demo

[`tlc-demo.html`](tlc-demo.html) runs the logic in the browser. Host it via GitHub
Pages (repo Settings → Pages → deploy from `main`) for a link.

## Board

![Zybo Z7-10](zyboz10.jpg)
