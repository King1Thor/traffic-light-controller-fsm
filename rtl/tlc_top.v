`timescale 1ns / 1ps
// ===========================================================================
//  Traffic Light Controller -- full board system (Zybo Z7-10).
//
//  Highway / farm-road intersection.  Highway stays green by default; when a
//  driver presses the farm-road button, the request is latched, the highway
//  finishes its minimum green, goes yellow, both turn red, then the farm road
//  gets its green, yellow, and control returns to the highway.
//
//  Board I/O
//    Clk            : 125 MHz system clock (K17)
//    btn[3]         : reset            btn[0] : farm-road car request
//    sw[0]          : demo speed (1 = ~15x faster so a full cycle is watchable)
//    highwayLights  : {R,Y,G} -> 3 external LEDs (PMOD)   farmLights : {R,Y,G}
//    led[3:0]       : seconds remaining in the current phase (binary countdown)
//    led6_g/led6_b  : on-board RGB phase indicator (green = highway, blue = farm)
// ===========================================================================
module tlc_top #(
    parameter integer DIV_SLOW = 125_000_000,
    parameter integer DIV_FAST = 8_333_333,
    parameter integer DB_N    = 1_250_000
)(
    input  wire        Clk,
    input  wire [3:0]  btn,
    input  wire [3:0]  sw,
    output wire [2:0]  highwayLights,   // {R,Y,G}
    output wire [2:0]  farmLights,      // {R,Y,G}
    output reg  [3:0]  led,             // countdown
    output wire        led6_g,
    output wire        led6_b
);
    // ---- reset (btn3), debounced ----
    wire rstLevel, rstRise;
    tlc_debounce #(.N(DB_N)) u_rstdb (.Clk(Clk), .Rst(1'b0), .btn(btn[3]), .level(rstLevel), .rise(rstRise));
    wire rst = rstLevel;

    // ---- farm-road button (btn0): debounced, with a request latch ----
    wire farmLevel, farmRise;
    tlc_debounce #(.N(DB_N)) u_farmdb (.Clk(Clk), .Rst(rst), .btn(btn[0]), .level(farmLevel), .rise(farmRise));

    // ---- 1 Hz (or fast) tick from the board clock ----
    wire tick;
    tlc_prescaler #(.DIV_SLOW(DIV_SLOW), .DIV_FAST(DIV_FAST)) u_ps (.Clk(Clk), .Rst(rst), .fast(sw[0]), .tick(tick));

    // ---- FSM + seconds counter ----
    wire [2:0] state;
    wire       RstCount;
    wire [1:0] highwaySignal, farmSignal;
    reg  [7:0] secs = 0;

    // latch a farm-road request from a quick button tap; clear once the farm
    // road actually gets its green (state S4).  Holding the button also works.
    reg farmReq = 0;
    always @(posedge Clk or posedge rst) begin
        if (rst)                 farmReq <= 1'b0;
        else if (state == 3'd4)  farmReq <= 1'b0;     // request served
        else if (farmRise)       farmReq <= 1'b1;     // car arrived
    end
    wire farmSensor = farmLevel | farmReq;

    always @(posedge Clk or posedge rst) begin
        if (rst)            secs <= 8'd0;
        else if (RstCount)  secs <= 8'd0;             // new phase: restart count
        else if (tick)      secs <= secs + 8'd1;      // one more second elapsed
    end

    tlc_fsm u_fsm (
        .state(state), .RstCount(RstCount),
        .highwaySignal(highwaySignal), .farmSignal(farmSignal),
        .secs(secs), .Clk(Clk), .Rst(rst), .farmSensor(farmSensor)
    );

    // ---- decode to discrete R/Y/G lamps ----
    tlc_lights u_lights (
        .highwaySignal(highwaySignal), .farmSignal(farmSignal),
        .highwayLights(highwayLights), .farmLights(farmLights)
    );

    // ---- live countdown: seconds left before this phase can advance ----
    reg [7:0] target;
    always @(*) begin
        case (state)
            3'd0: target = 8'd1;                       // S0 all-red
            3'd1: target = 8'd30;                      // S1 highway green (min)
            3'd2: target = 8'd3;                       // S2 highway yellow
            3'd3: target = 8'd1;                       // S3 all-red
            3'd4: target = farmSensor ? 8'd18 : 8'd3;  // S4 farm green (max/min)
            3'd5: target = 8'd3;                       // S5 farm yellow
            default: target = 8'd0;
        endcase
        if (target > secs) begin
            led = (target - secs > 8'd15) ? 4'd15 : (target - secs);
        end else
            led = 4'd0;
    end

    // ---- RGB phase indicator: green while highway has the road, blue for farm ----
    assign led6_g = (state==3'd0) || (state==3'd1) || (state==3'd2);
    assign led6_b = (state==3'd3) || (state==3'd4) || (state==3'd5);
endmodule
