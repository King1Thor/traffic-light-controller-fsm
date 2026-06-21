`timescale 1ns / 1ps
// Decodes a road's 2-bit signal into three discrete lamp outputs {R,Y,G},
// one bit per physical LED (active high).  01=red, 10=yellow, 11=green.
module tlc_lights (
    input  wire [1:0] highwaySignal,
    input  wire [1:0] farmSignal,
    output reg  [2:0] highwayLights,   // {R, Y, G}
    output reg  [2:0] farmLights       // {R, Y, G}
);
    function [2:0] ryg(input [1:0] s);
        case (s)
            2'b01:  ryg = 3'b100;  // RED
            2'b10:  ryg = 3'b010;  // YELLOW
            2'b11:  ryg = 3'b001;  // GREEN
            default: ryg = 3'b000; // off
        endcase
    endfunction
    always @(*) begin
        highwayLights = ryg(highwaySignal);
        farmLights    = ryg(farmSignal);
    end
endmodule
