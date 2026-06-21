`timescale 1ns / 1ps
// Synchronizes and debounces a push button, and emits a one-clock `rise` pulse
// on a clean press.  `level` is the debounced steady state (held = 1).
module tlc_debounce #(parameter integer N = 1_250_000)( // ~10 ms @ 125 MHz
    input  wire Clk,
    input  wire Rst,
    input  wire btn,
    output reg  level,
    output wire rise
);
    reg s0=0, s1=0;                   // synchronizer
    always @(posedge Clk) begin s0 <= btn; s1 <= s0; end

    reg [21:0] cnt = 0;
    reg level_q = 0;
    initial level = 0;
    always @(posedge Clk or posedge Rst) begin
        if (Rst) begin cnt <= 0; level <= 0; level_q <= 0; end
        else begin
            level_q <= level;
            if (s1 != level) begin
                if (cnt >= N-1) begin level <= s1; cnt <= 0; end
                else            cnt <= cnt + 1;
            end else cnt <= 0;
        end
    end
    assign rise = (level & ~level_q);   // rising edge of the clean level
endmodule
