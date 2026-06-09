`timescale 1ns / 1ps

module synchronizer (
    output wire OutSignal,
    input wire InSignal,
    input wire Clk
);

    reg buff0;
    reg buff1;
    reg buff2;

    always @(posedge Clk) begin
        buff0 <= InSignal;
        buff1 <= buff0;
        buff2 <= buff1;
    end

    assign OutSignal = buff2;

endmodule
