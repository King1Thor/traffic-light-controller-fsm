`timescale 1ns / 1ps
// 6-state Moore FSM for a highway / farm-road intersection.
// `secs` is the number of elapsed seconds in the current state (from the
// seconds counter in the top).  Highway has priority; the farm road only gets
// a green when a car is detected (farmSensor), with a minimum highway green and
// a maximum farm green.  Outputs the state, a counter-reset strobe, and the
// 2-bit signal for each road (01=red, 10=yellow, 11=green).
module tlc_fsm (
    output reg [2:0] state,
    output reg       RstCount,
    output reg [1:0] highwaySignal,
    output reg [1:0] farmSignal,
    input  wire [7:0] secs,
    input  wire       Clk,
    input  wire       Rst,
    input  wire       farmSensor
);
    localparam S0=3'd0, S1=3'd1, S2=3'd2, S3=3'd3, S4=3'd4, S5=3'd5;

    // phase durations, in seconds
    localparam T0     = 8'd1;    // all-red safety gap
    localparam T1_MIN = 8'd30;   // highway green minimum
    localparam T2     = 8'd3;    // highway yellow
    localparam T3     = 8'd1;    // all-red safety gap
    localparam T4_MIN = 8'd3;    // farm green minimum
    localparam T4_MAX = 8'd18;   // farm green maximum
    localparam T5     = 8'd3;    // farm yellow

    localparam RED=2'b01, YEL=2'b10, GRN=2'b11;
    reg [2:0] nextState;
    initial state = S0;

    always @(posedge Clk or posedge Rst)
        if (Rst) state <= S0; else state <= nextState;

    always @(*) begin
        nextState     = state;
        RstCount      = 1'b0;
        highwaySignal = RED;
        farmSignal    = RED;
        case (state)
            S0: if (secs >= T0)                       begin nextState=S1; RstCount=1'b1; end
            S1: begin highwaySignal=GRN; farmSignal=RED;
                    if (secs >= T1_MIN && farmSensor) begin nextState=S2; RstCount=1'b1; end end
            S2: begin highwaySignal=YEL; farmSignal=RED;
                    if (secs >= T2)                   begin nextState=S3; RstCount=1'b1; end end
            S3: if (secs >= T3)                       begin nextState=S4; RstCount=1'b1; end
            S4: begin highwaySignal=RED; farmSignal=GRN;
                    if (secs >= T4_MIN && (!farmSensor || secs >= T4_MAX))
                                                      begin nextState=S5; RstCount=1'b1; end end
            S5: begin highwaySignal=RED; farmSignal=YEL;
                    if (secs >= T5)                   begin nextState=S0; RstCount=1'b1; end end
            default:                                  begin nextState=S0; RstCount=1'b1; end
        endcase
    end
endmodule
