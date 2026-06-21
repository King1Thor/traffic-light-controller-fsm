`timescale 1ns / 1ps
// ===========================================================================
//  Self-checking testbench for tlc_fsm.
//  The real timing constants are huge (seconds at 50 MHz), so instead of
//  waiting them out we drive Count directly to each threshold and verify the
//  state, the highway/farm light outputs, and the farm-sensor logic across a
//  full cycle.  Encoding: 2'b01 = RED, 2'b10 = YELLOW, 2'b11 = GREEN.
// ===========================================================================
module tlc_fsm_tb;
    reg  [30:0] Count;
    reg         Clk, Rst, farmSensor;
    wire [2:0]  state;
    wire        RstCount;
    wire [1:0]  highwaySignal, farmSignal;

    // mirror the DUT's timing constants
    localparam D0=31'd50_000_000, D1_MIN=31'd1_500_000_000, D2=31'd150_000_000,
               D3=31'd50_000_000, D4_MIN=31'd150_000_000, D4_MAX=31'd900_000_000,
               D5=31'd150_000_000;
    localparam RED=2'b01, YEL=2'b10, GRN=2'b11;

    tlc_fsm uut (.state(state), .RstCount(RstCount),
                 .highwaySignal(highwaySignal), .farmSignal(farmSignal),
                 .Count(Count), .Clk(Clk), .Rst(Rst), .farmSensor(farmSensor));

    always #5 Clk = ~Clk;

    integer errors = 0;
    task step; begin @(posedge Clk); #1; end endtask

    task check(input [2:0] s, input [1:0] hw, input [1:0] fm, input [255:0] name);
    begin
        if (state!==s || highwaySignal!==hw || farmSignal!==fm) begin
            $display("  FAIL [%0s] state=%0d hw=%b farm=%b (want state=%0d hw=%b farm=%b)",
                     name, state, highwaySignal, farmSignal, s, hw, fm);
            errors = errors + 1;
        end else
            $display("  ok   [%0s] state=S%0d  highway=%s  farm=%s", name, state,
                     hw==RED?"RED":hw==YEL?"YEL":hw==GRN?"GRN":"??",
                     fm==RED?"RED":fm==YEL?"YEL":fm==GRN?"GRN":"??");
    end endtask

    initial begin
        Clk=0; Rst=1; Count=0; farmSensor=0;
        step; step; Rst=0; step;
        check(3'd0, RED, RED, "reset -> S0");

        // S0 -> S1 once the 1 s all-red interval elapses
        Count = D0; step;
        check(3'd1, GRN, RED, "S0->S1 highway green");

        // S1 holds for green: stays even past the 30 s minimum if no farm car
        Count = D1_MIN; farmSensor = 0; step;
        check(3'd1, GRN, RED, "S1 holds (no farm car)");
        // a car arrives on the farm road -> advance to highway yellow
        farmSensor = 1; step;
        check(3'd2, YEL, RED, "S1->S2 highway yellow");

        // S2 -> S3 (all red) after the 3 s yellow
        Count = D2; step;
        check(3'd3, RED, RED, "S2->S3 all red");

        // S3 -> S4 farm road gets green
        Count = D3; step;
        check(3'd4, RED, GRN, "S3->S4 farm green");

        // S4 holds while a car is still present and max not reached
        Count = D4_MIN; farmSensor = 1; step;
        check(3'd4, RED, GRN, "S4 holds (car present)");
        // car leaves -> farm yellow
        farmSensor = 0; step;
        check(3'd5, RED, YEL, "S4->S5 farm yellow");

        // S5 -> back to S0
        Count = D5; step;
        check(3'd0, RED, RED, "S5->S0 cycle complete");

        // extra: S4 also ends on the 18 s max even if the car never leaves
        Count = D0; step;            // S0->S1
        Count = D1_MIN; farmSensor=1; step;   // S1->S2
        Count = D2; step;            // S2->S3
        Count = D3; step;            // S3->S4
        Count = D4_MAX; farmSensor = 1; step; // car still there but max reached
        check(3'd5, RED, YEL, "S4->S5 on 18 s max (car still present)");

        $display("");
        if (errors==0) $display("TLC FSM: ALL TESTS PASSED");
        else           $display("TLC FSM: %0d CHECK(S) FAILED", errors);
        $finish;
    end
endmodule
