## ===========================================================================
##  Traffic Light Controller -- full system constraints for Zybo Z7-10.
##  All onboard pins are from the Digilent Zybo Z7-10 master XDC.
##  The six traffic LEDs go to Pmod JA (external LEDs on a breadboard); verify
##  the JA pins against your board's master XDC if synthesis complains.
## ===========================================================================

## ---- 125 MHz system clock ----
set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS33 } [get_ports { Clk }]
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { Clk }]

## ---- Push buttons : btn[0]=farm-road car request, btn[3]=reset ----
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]
set_property -dict { PACKAGE_PIN P16 IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]
set_property -dict { PACKAGE_PIN K19 IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]
set_property -dict { PACKAGE_PIN Y16 IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]

## ---- Slide switches : sw[0]=demo speed (1 = ~15x faster) ----
set_property -dict { PACKAGE_PIN G15 IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]
set_property -dict { PACKAGE_PIN W13 IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]
set_property -dict { PACKAGE_PIN T16 IOSTANDARD LVCMOS33 } [get_ports { sw[3] }]

## ---- On-board LEDs : seconds-remaining countdown (binary) ----
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN M15 IOSTANDARD LVCMOS33 } [get_ports { led[1] }]
set_property -dict { PACKAGE_PIN G14 IOSTANDARD LVCMOS33 } [get_ports { led[2] }]
set_property -dict { PACKAGE_PIN D18 IOSTANDARD LVCMOS33 } [get_ports { led[3] }]

## ---- RGB LED LD6 : phase indicator (green = highway has road, blue = farm) ----
set_property -dict { PACKAGE_PIN F17 IOSTANDARD LVCMOS33 } [get_ports { led6_g }]
set_property -dict { PACKAGE_PIN M17 IOSTANDARD LVCMOS33 } [get_ports { led6_b }]

## ---- Pmod JA : the six traffic-light LEDs (external, on a breadboard) ----
## highwayLights = {R,Y,G}      farmLights = {R,Y,G}
set_property -dict { PACKAGE_PIN N15 IOSTANDARD LVCMOS33 } [get_ports { highwayLights[2] }] ;# JA1  Highway RED
set_property -dict { PACKAGE_PIN L14 IOSTANDARD LVCMOS33 } [get_ports { highwayLights[1] }] ;# JA2  Highway YELLOW
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports { highwayLights[0] }] ;# JA3  Highway GREEN
set_property -dict { PACKAGE_PIN K14 IOSTANDARD LVCMOS33 } [get_ports { farmLights[2] }]    ;# JA4  Farm RED
set_property -dict { PACKAGE_PIN N16 IOSTANDARD LVCMOS33 } [get_ports { farmLights[1] }]    ;# JA7  Farm YELLOW
set_property -dict { PACKAGE_PIN L15 IOSTANDARD LVCMOS33 } [get_ports { farmLights[0] }]    ;# JA8  Farm GREEN
