`timescale 1ns / 1ps

module tlc_fsm_tb;

    reg [30:0] Count;
    reg Clk;
    reg Rst;
    reg farmSensor;

    wire [2:0] state;
    wire RstCount;
    wire [1:0] highwaySignal;
    wire [1:0] farmSignal;

    tlc_fsm uut (
        .state(state),
        .RstCount(RstCount),
        .highwaySignal(highwaySignal),
        .farmSignal(farmSignal),
        .Count(Count),
        .Clk(Clk),
        .Rst(Rst),
        .farmSensor(farmSensor)
    );

    always begin
        #5 Clk = ~Clk;
    end

    initial begin
        Clk = 0;
        Rst = 1;
        Count = 0;
        farmSensor = 0;

        #20;
        Rst = 0;

        // Simulate vehicle detected on farm road
        #100;
        farmSensor = 1;

        // Release sensor later
        #1000;
        farmSensor = 0;

        #5000;
        $stop;
    end

    always @(posedge Clk) begin
        if (RstCount)
            Count <= 0;
        else
            Count <= Count + 1;
    end

endmodule
