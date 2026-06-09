`timescale 1ns / 1ps

module tlc_controller_ver1 (
    output wire [1:0] highwaySignal,
    output wire [1:0] farmSignal,
    output wire [3:0] JB,
    input wire Clk,
    input wire Rst,
    input wire farmSensorRaw
);

    wire RstSync;
    wire RstCount;
    wire farmSensorSync;

    reg [30:0] Count;

    // Debug outputs
    assign JB[3] = RstCount;

    // Synchronize asynchronous push-button inputs
    synchronizer syncRst (
        .OutSignal(RstSync),
        .InSignal(Rst),
        .Clk(Clk)
    );

    synchronizer syncSensor (
        .OutSignal(farmSensorSync),
        .InSignal(farmSensorRaw),
        .Clk(Clk)
    );

    // FSM instance
    tlc_fsm FSM (
        .state(JB[2:0]),
        .RstCount(RstCount),
        .highwaySignal(highwaySignal),
        .farmSignal(farmSignal),
        .Count(Count),
        .Clk(Clk),
        .Rst(RstSync),
        .farmSensor(farmSensorSync)
    );

    // Counter with reset from FSM
    always @(posedge Clk or posedge RstSync) begin
        if (RstSync)
            Count <= 31'd0;
        else if (RstCount)
            Count <= 31'd0;
        else
            Count <= Count + 31'd1;
    end

endmodule
