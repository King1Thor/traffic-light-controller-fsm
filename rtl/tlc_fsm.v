`timescale 1ns / 1ps
// ===========================================================================
//  8-state Moore FSM: highway / farm-road intersection + pedestrian crossing.
//  Highway is the default green.  A farm-road car or a pedestrian press is
//  latched (in the top) and served at the next safe all-red point; pedestrians
//  get priority so people don't wait through a vehicle cycle.
//    S0 all-red    S1 hwy green   S2 hwy yellow   S3 all-red (decision)
//    S4 farm green S5 farm yellow S6 WALK         S7 flashing DON'T-WALK
//  Signals: 01=red, 10=yellow, 11=green.  `secs` = seconds in current state.
// ===========================================================================
module tlc_fsm (
    output reg [2:0] state,
    output reg       RstCount,
    output reg [1:0] highwaySignal,
    output reg [1:0] farmSignal,
    input  wire [7:0] secs,
    input  wire       Clk,
    input  wire       Rst,
    input  wire       farmSensor,
    input  wire       pedReq
);
    localparam S0=3'd0, S1=3'd1, S2=3'd2, S3=3'd3, S4=3'd4, S5=3'd5, S6=3'd6, S7=3'd7;

    // phase durations, in seconds
    localparam T0=8'd1, T1_MIN=8'd30, T2=8'd3, T3=8'd1,
               T4_MIN=8'd3, T4_MAX=8'd18, T5=8'd3,
               T6_WALK=8'd8, T7_FLASH=8'd5;

    localparam RED=2'b01, YEL=2'b10, GRN=2'b11;
    reg [2:0] nextState;
    initial state = S0;

    always @(posedge Clk or posedge Rst)
        if (Rst) state <= S0; else state <= nextState;

    always @(*) begin
        nextState     = state;
        RstCount      = 1'b0;
        highwaySignal = RED;     // both roads red unless a state says otherwise
        farmSignal    = RED;
        case (state)
            S0: if (secs >= T0) begin nextState=S1; RstCount=1'b1; end
            S1: begin highwaySignal=GRN;            // highway green (default rest)
                    if (secs >= T1_MIN && (farmSensor || pedReq))
                        begin nextState=S2; RstCount=1'b1; end end
            S2: begin highwaySignal=YEL;
                    if (secs >= T2) begin nextState=S3; RstCount=1'b1; end end
            S3: if (secs >= T3) begin RstCount=1'b1; // all-red: decide who goes next
                    if (pedReq)          nextState=S6;   // pedestrians first
                    else if (farmSensor) nextState=S4;
                    else                 nextState=S1; end
            S4: begin farmSignal=GRN;
                    if (secs >= T4_MIN && (!farmSensor || secs >= T4_MAX))
                        begin nextState=S5; RstCount=1'b1; end end
            S5: begin farmSignal=YEL;
                    if (secs >= T5) begin nextState=S3; RstCount=1'b1; end end
            S6: if (secs >= T6_WALK)  begin nextState=S7; RstCount=1'b1; end // WALK
            S7: if (secs >= T7_FLASH) begin nextState=S0; RstCount=1'b1; end // clear
            default: begin nextState=S0; RstCount=1'b1; end
        endcase
    end
endmodule
