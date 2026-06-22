`timescale 1ns / 1ps
// ===========================================================================
//  Traffic Light Controller -- full system with pedestrian crossing (Zybo Z7-10)
//
//  Highway / farm-road intersection plus a pedestrian WALK phase.
//    btn[3] reset   btn[0] farm-road car request   btn[1] pedestrian WALK request
//    sw[0]  demo speed (1 = ~15x faster)
//  Outputs (Pmod JA): highway R/Y/G, farm R/Y/G, WALK, DON'T-WALK.
//  On-board: 4 LEDs = countdown; RGB LD6 = highway light in true colour
//            (green -> yellow -> red), blue while pedestrians cross.
// ===========================================================================
module tlc_top #(
    parameter integer DIV_SLOW = 125_000_000,   // 1 s @ 125 MHz
    parameter integer DIV_FAST = 8_333_333,     // ~1/15 s (demo)
    parameter integer DB_N     = 1_250_000      // ~10 ms debounce
)(
    input  wire        Clk,
    input  wire [3:0]  btn,
    input  wire [3:0]  sw,
    output wire [2:0]  highwayLights,   // {R,Y,G}
    output wire [2:0]  farmLights,      // {R,Y,G}
    output wire        walk,            // pedestrian WALK lamp
    output wire        dontwalk,        // pedestrian DON'T-WALK lamp
    output reg  [3:0]  led,             // seconds-remaining countdown
    output wire        led6_r,
    output wire        led6_g,
    output wire        led6_b
);
    // ---- reset (btn3) ----
    wire rstLevel; tlc_debounce #(.N(DB_N)) u_rstdb (.Clk(Clk), .Rst(1'b0), .btn(btn[3]), .level(rstLevel), .rise());
    wire rst = rstLevel;

    // ---- farm-road button (btn0) and pedestrian button (btn1) ----
    wire farmLevel, farmRise, pedLevel, pedRise;
    tlc_debounce #(.N(DB_N)) u_farmdb (.Clk(Clk), .Rst(rst), .btn(btn[0]), .level(farmLevel), .rise(farmRise));
    tlc_debounce #(.N(DB_N)) u_peddb  (.Clk(Clk), .Rst(rst), .btn(btn[1]), .level(pedLevel),  .rise(pedRise));

    // ---- tick (1 Hz, or fast for demo) and a slow blink for DON'T-WALK ----
    wire tick;
    tlc_prescaler #(.DIV_SLOW(DIV_SLOW), .DIV_FAST(DIV_FAST)) u_ps (.Clk(Clk), .Rst(rst), .fast(sw[0]), .tick(tick));
    reg blink = 0; always @(posedge Clk or posedge rst) if (rst) blink<=0; else if (tick) blink<=~blink;

    // ---- FSM + seconds counter ----
    wire [2:0] state; wire RstCount; wire [1:0] highwaySignal, farmSignal;
    reg  [7:0] secs = 0;

    // latch a farm-road request (tap or hold); cleared when the farm gets green (S4)
    reg farmReq = 0;
    always @(posedge Clk or posedge rst)
        if (rst)                farmReq <= 1'b0;
        else if (state==3'd4)   farmReq <= 1'b0;
        else if (farmRise)      farmReq <= 1'b1;
    wire farmSensor = farmLevel | farmReq;

    // latch a pedestrian request; cleared when the WALK phase starts (S6)
    reg pedReq = 0;
    always @(posedge Clk or posedge rst)
        if (rst)                pedReq <= 1'b0;
        else if (state==3'd6)   pedReq <= 1'b0;
        else if (pedRise)       pedReq <= 1'b1;

    always @(posedge Clk or posedge rst)
        if (rst)            secs <= 8'd0;
        else if (RstCount)  secs <= 8'd0;
        else if (tick)      secs <= secs + 8'd1;

    tlc_fsm u_fsm (
        .state(state), .RstCount(RstCount),
        .highwaySignal(highwaySignal), .farmSignal(farmSignal),
        .secs(secs), .Clk(Clk), .Rst(rst), .farmSensor(farmSensor), .pedReq(pedReq)
    );

    tlc_lights u_lights (
        .highwaySignal(highwaySignal), .farmSignal(farmSignal),
        .highwayLights(highwayLights), .farmLights(farmLights)
    );

    // ---- pedestrian lamps ----
    assign walk     = (state==3'd6);                          // WALK during S6
    assign dontwalk = (state==3'd6) ? 1'b0 :
                      (state==3'd7) ? blink : 1'b1;            // flash during clear, else solid

    // ---- live countdown ----
    reg [7:0] target;
    always @(*) begin
        case (state)
            3'd0: target=8'd1;  3'd1: target=8'd30; 3'd2: target=8'd3;  3'd3: target=8'd1;
            3'd4: target=farmSensor?8'd18:8'd3;     3'd5: target=8'd3;
            3'd6: target=8'd8;  3'd7: target=8'd5;  default: target=8'd0;
        endcase
        led = (target>secs) ? ((target-secs>8'd15)?4'd15:(target-secs)) : 4'd0;
    end

    // ---- RGB LD6: highway light in true colour; blue while pedestrians cross ----
    wire pedPhase = (state==3'd6)||(state==3'd7);
    wire hwGreen  = (state==3'd1);
    wire hwYellow = (state==3'd2);
    assign led6_r = pedPhase ? 1'b0 : (hwYellow | ~(hwGreen|hwYellow));  // yellow or red
    assign led6_g = pedPhase ? 1'b0 : (hwGreen  |  hwYellow);            // green or yellow
    assign led6_b = (state==3'd6) ? 1'b1 : (state==3'd7) ? blink : 1'b0; // walk = blue
endmodule
