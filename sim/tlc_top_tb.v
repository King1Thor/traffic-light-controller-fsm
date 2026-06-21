`timescale 1ns / 1ps
// ===========================================================================
//  Full-system self-checking testbench for tlc_top.
//  Uses a tiny prescaler/debounce (via parameters) so one "second" is a few
//  clocks.  Walks a full cycle, exercises the farm-road button press, and
//  checks the discrete R/Y/G lamp outputs at each phase.
//  Lamp bits are {R,Y,G}: 100=red, 010=yellow, 001=green.
// ===========================================================================
module tlc_top_tb;
    reg        Clk=0;
    reg  [3:0] btn=0, sw=0;
    wire [2:0] highwayLights, farmLights;
    wire [3:0] led;
    wire       led6_g, led6_b;

    // 1 "second" = 4 clocks; debounce = 2 clocks  (fast for simulation)
    tlc_top #(.DIV_SLOW(4), .DIV_FAST(4), .DB_N(2)) dut (
        .Clk(Clk), .btn(btn), .sw(sw),
        .highwayLights(highwayLights), .farmLights(farmLights),
        .led(led), .led6_g(led6_g), .led6_b(led6_b)
    );

    always #5 Clk = ~Clk;

    localparam R=3'b100, Y=3'b010, G=3'b001;
    integer errors=0;

    task waitState(input [2:0] s);
        integer guard; begin guard=0;
        while (dut.state!==s && guard<20000) begin @(posedge Clk); guard=guard+1; end
        if (dut.state!==s) begin $display("  FAIL: state never reached S%0d",s); errors=errors+1; end
        end
    endtask
    task chk(input [2:0] hw, input [2:0] fm, input [127:0] nm); begin
        if (highwayLights!==hw || farmLights!==fm) begin
            $display("  FAIL [%0s] hw=%b farm=%b (want hw=%b farm=%b)",nm,highwayLights,farmLights,hw,fm);
            errors=errors+1;
        end else $display("  ok   [%0s] highway=%s farm=%s",nm,
            hw==R?"RED":hw==Y?"YEL":"GRN", fm==R?"RED":fm==Y?"YEL":"GRN");
    end endtask

    initial begin
        // reset via btn3
        btn[3]=1; repeat(8) @(posedge Clk); btn[3]=0; repeat(6) @(posedge Clk);

        waitState(3'd0); chk(R,R,"S0 all-red");
        waitState(3'd1); chk(G,R,"S1 highway GREEN (default)");

        // no car yet: highway stays green past the 30 s minimum
        repeat(200) @(posedge Clk);
        chk(G,R,"S1 holds (no farm car)");

        // a driver presses the farm-road button (a quick tap -> latched request)
        btn[0]=1; repeat(6) @(posedge Clk); btn[0]=0;
        $display("  >> farm-road button pressed (car waiting)");

        waitState(3'd2); chk(Y,R,"S2 highway YELLOW");
        waitState(3'd3); chk(R,R,"S3 all-red");
        waitState(3'd4); chk(R,G,"S4 farm GREEN  <-- request served");
        waitState(3'd5); chk(R,Y,"S5 farm YELLOW");
        waitState(3'd0); chk(R,R,"S0 back to all-red (cycle complete)");
        waitState(3'd1); chk(G,R,"S1 highway GREEN again");

        $display("");
        if (errors==0) $display("TLC FULL SYSTEM: ALL TESTS PASSED");
        else           $display("TLC FULL SYSTEM: %0d CHECK(S) FAILED",errors);
        $finish;
    end

    initial begin #5_000_000; $display("TIMEOUT"); $finish; end
endmodule
