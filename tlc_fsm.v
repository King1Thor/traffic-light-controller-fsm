`timescale 1ns / 1ps

module tlc_fsm (
    output reg [2:0] state,
    output reg RstCount,
    output reg [1:0] highwaySignal,
    output reg [1:0] farmSignal,
    input wire [30:0] Count,
    input wire Clk,
    input wire Rst,
    input wire farmSensor
);

    // State encoding
    localparam S0 = 3'd0; // Highway red, farm red
    localparam S1 = 3'd1; // Highway green, farm red
    localparam S2 = 3'd2; // Highway yellow, farm red
    localparam S3 = 3'd3; // Highway red, farm red
    localparam S4 = 3'd4; // Highway red, farm green
    localparam S5 = 3'd5; // Highway red, farm yellow

    // Timing values based on 50 MHz clock
    localparam D0     = 31'd50_000_000;      // 1 second
    localparam D1_MIN = 31'd1_500_000_000;   // 30 seconds
    localparam D2     = 31'd150_000_000;     // 3 seconds
    localparam D3     = 31'd50_000_000;      // 1 second
    localparam D4_MIN = 31'd150_000_000;     // 3 seconds
    localparam D4_MAX = 31'd900_000_000;     // 18 seconds max
    localparam D5     = 31'd150_000_000;     // 3 seconds

    reg [2:0] nextState;

    // Sequential state register
    always @(posedge Clk or posedge Rst) begin
        if (Rst)
            state <= S0;
        else
            state <= nextState;
    end

    // Combinational next-state and output logic
    always @(*) begin
        nextState = state;
        RstCount = 1'b0;

        // Default lights: both red
        highwaySignal = 2'b01;
        farmSignal = 2'b01;

        case (state)
            S0: begin
                if (Count >= D0) begin
                    nextState = S1;
                    RstCount = 1'b1;
                end
            end

            S1: begin
                highwaySignal = 2'b11;
                farmSignal = 2'b01;

                if (Count >= D1_MIN && farmSensor) begin
                    nextState = S2;
                    RstCount = 1'b1;
                end
            end

            S2: begin
                highwaySignal = 2'b10;
                farmSignal = 2'b01;

                if (Count >= D2) begin
                    nextState = S3;
                    RstCount = 1'b1;
                end
            end

            S3: begin
                if (Count >= D3) begin
                    nextState = S4;
                    RstCount = 1'b1;
                end
            end

            S4: begin
                highwaySignal = 2'b01;
                farmSignal = 2'b11;

                if (Count >= D4_MIN && (!farmSensor || Count >= D4_MAX)) begin
                    nextState = S5;
                    RstCount = 1'b1;
                end
            end

            S5: begin
                highwaySignal = 2'b01;
                farmSignal = 2'b10;

                if (Count >= D5) begin
                    nextState = S0;
                    RstCount = 1'b1;
                end
            end

            default: begin
                nextState = S0;
                RstCount = 1'b1;
                highwaySignal = 2'b01;
                farmSignal = 2'b01;
            end
        endcase
    end

endmodule
