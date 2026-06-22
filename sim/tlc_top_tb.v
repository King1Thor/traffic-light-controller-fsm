`timescale 1ns / 1ps
// Full-system self-checking testbench: highway default, farm-road request, and
// the pedestrian WALK phase.  Tiny prescaler/debounce so a cycle runs fast.
// Lamp bits {R,Y,G}: 100=red 010=yellow 001=green.
module tlc_top_tb;
    reg        Clk=0; reg [3:0] btn=0, sw=0;
    wire [2:0] highwayLights, farmLights;
    wire       walk, dontwalk, led6_r, led6_g, led6_b;
    wire [3:0] led;

    tlc_top #(.DIV_SLOW(4), .DIV_FAST(4), .DB_N(2)) dut (
        .Clk(Clk), .btn(btn), .sw(sw),
        .highwayLights(highwayLights), .farmLights(farmLights),
        .walk(walk), .dontwalk(dontwalk), .led(led),
        .led6_r(led6_r), .led6_g(led6_g), .led6_b(led6_b)
    );
    always #5 Clk=~Clk;
    localparam R=3'b100, Y=3'b010, G=3'b001;
    integer errors=0;

    task waitState(input [2:0] s); integer g; begin g=0;
        while (dut.state!==s && g<40000) begin @(posedge Clk); g=g+1; end
        if (dut.state!==s) begin $display("  FAIL: never reached S%0d",s); errors=errors+1; end
    end endtask
    task chk(input [2:0] hw, input [2:0] fm, input [127:0] nm); begin
        if (highwayLights!==hw||farmLights!==fm) begin
            $display("  FAIL [%0s] hw=%b farm=%b",nm,highwayLights,farmLights); errors=errors+1;
        end else $display("  ok   [%0s] highway=%s farm=%s",nm,
            hw==R?"RED":hw==Y?"YEL":"GRN", fm==R?"RED":fm==Y?"YEL":"GRN");
    end endtask

    initial begin
        btn[3]=1; repeat(8)@(posedge Clk); btn[3]=0; repeat(6)@(posedge Clk);
        waitState(3'd1); chk(G,R,"S1 highway GREEN (default)");

        // ---- farm-road request ----
        btn[0]=1; repeat(6)@(posedge Clk); btn[0]=0;
        $display("  >> farm-road button pressed");
        waitState(3'd4); chk(R,G,"S4 farm GREEN (served)");
        waitState(3'd1); chk(G,R,"back to highway GREEN");

        // ---- pedestrian request ----
        btn[1]=1; repeat(6)@(posedge Clk); btn[1]=0;
        $display("  >> pedestrian button pressed");
        waitState(3'd6);
        if (walk!==1'b1 || dontwalk!==1'b0 || highwayLights!==R || farmLights!==R) begin
            $display("  FAIL [S6 WALK] walk=%b dontwalk=%b hw=%b farm=%b",walk,dontwalk,highwayLights,farmLights);
            errors=errors+1;
        end else $display("  ok   [S6 WALK] WALK on, both roads RED");
        waitState(3'd7);
        if (walk!==1'b0) begin $display("  FAIL [S7] walk should be off"); errors=errors+1; end
        else $display("  ok   [S7 clearance] DON'T-WALK flashing, WALK off");
        waitState(3'd1); chk(G,R,"back to highway GREEN after WALK");

        $display("");
        if (errors==0) $display("TLC FULL SYSTEM (+pedestrian): ALL TESTS PASSED");
        else           $display("TLC: %0d CHECK(S) FAILED",errors);
        $finish;
    end
    initial begin #8_000_000; $display("TIMEOUT"); $finish; end
endmodule
