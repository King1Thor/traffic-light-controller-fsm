## ZYBO Z7-10 Example Constraints
## Verify pin names with your board master XDC before programming.

## Clock
set_property PACKAGE_PIN K17 [get_ports Clk]
set_property IOSTANDARD LVCMOS33 [get_ports Clk]
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports Clk]

## Buttons
set_property PACKAGE_PIN K18 [get_ports Rst]
set_property IOSTANDARD LVCMOS33 [get_ports Rst]

set_property PACKAGE_PIN P16 [get_ports farmSensorRaw]
set_property IOSTANDARD LVCMOS33 [get_ports farmSensorRaw]

## LEDs for highwaySignal[1:0] and farmSignal[1:0]
set_property PACKAGE_PIN M14 [get_ports {farmSignal[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {farmSignal[0]}]

set_property PACKAGE_PIN M15 [get_ports {farmSignal[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {farmSignal[1]}]

set_property PACKAGE_PIN G14 [get_ports {highwaySignal[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {highwaySignal[0]}]

set_property PACKAGE_PIN D18 [get_ports {highwaySignal[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {highwaySignal[1]}]

## PMOD JB debug outputs
set_property PACKAGE_PIN V8 [get_ports {JB[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JB[0]}]

set_property PACKAGE_PIN W8 [get_ports {JB[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JB[1]}]

set_property PACKAGE_PIN U7 [get_ports {JB[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JB[2]}]

set_property PACKAGE_PIN V7 [get_ports {JB[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JB[3]}]
