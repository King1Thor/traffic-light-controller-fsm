`timescale 1ns / 1ps
// Generates a one-clock-wide `tick` pulse at a fixed rate from the board clock.
//   fast = 0 : DIV_SLOW cycles  -> real time   (1 tick = 1 second @ 125 MHz)
//   fast = 1 : DIV_FAST cycles  -> sped up for watching the demo on the bench
module tlc_prescaler #(
    parameter integer DIV_SLOW = 125_000_000,   // 1 s  at 125 MHz
    parameter integer DIV_FAST = 8_333_333      // 1/15 s (15x faster) for demo
)(
    input  wire Clk,
    input  wire Rst,
    input  wire fast,
    output reg  tick
);
    reg [31:0] cnt = 0;
    initial tick = 1'b0;
    wire [31:0] top = fast ? (DIV_FAST-1) : (DIV_SLOW-1);
    always @(posedge Clk or posedge Rst) begin
        if (Rst)            begin cnt <= 0; tick <= 1'b0; end
        else if (cnt >= top) begin cnt <= 0; tick <= 1'b1; end
        else                 begin cnt <= cnt + 1; tick <= 1'b0; end
    end
endmodule
