`timescale 1ps/1ps

module Judgement_tb();

`define NOTHING 2'b00
`define TAP 2'b01
`define HOLD_START 2'b10
`define HOLD_MIDDLE 2'b11

reg                 clk;
reg                 clk_div;
reg                 rst_n;
reg                 clickup;
reg                 clickdown;
reg [1:0]           left_noteup;
reg [1:0]           left_notedown;
reg [1:0]           right_noteup;
reg [1:0]           right_notedown;

wire [1:0]          resultup;
wire [1:0]          resultdown;
wire                accum_now;

Judgement u_Judgement(
    .clk(clk),
    .clk_div(clk_div),
    .rst_n(rst_n),
    .clickup(clickup),
    .clickdown(clickdown),
    .left_noteup(left_noteup),
    .left_notedown(left_notedown),
    .right_noteup(right_noteup),
    .right_notedown(right_notedown),

    .resultup(resultup),
    .resultdown(resultdown),
    .accum_now(accum_now)
);

always #5 clk = ~clk;
always #500 clk_div = ~clk_div;

initial begin
    clk = 1;
    clk_div = 1;
    rst_n = 0;
    clickup = 1;
    clickdown = 1;
    left_noteup = `NOTHING;
    left_notedown = `NOTHING;
    right_noteup = `NOTHING;
    right_notedown = `NOTHING;

    #5000
    rst_n = 1;

    // tap without click
    #1000
    right_noteup = `TAP;
    #1000
    right_noteup = `NOTHING;
    left_noteup = `TAP;
    #1000
    left_noteup = `NOTHING;

    // tap with click
    #2000
    right_noteup = `TAP;
    #960
    clickup = 0;
    #40
    right_noteup = `NOTHING;
    left_noteup = `TAP;
    #1000
    left_noteup = `NOTHING;
    clickup = 1;

    // hold (length=4) without click
    #2000
    right_noteup = `HOLD_START;
    #1000
    right_noteup = `HOLD_MIDDLE;
    left_noteup = `HOLD_START;
    #1000
    right_noteup = `HOLD_MIDDLE;
    left_noteup = `HOLD_MIDDLE;
    #1000
    right_noteup = `HOLD_MIDDLE;
    left_noteup = `HOLD_MIDDLE;
    #1000
    right_noteup = `NOTHING;
    left_noteup = `HOLD_MIDDLE;
    #1000
    left_noteup = `NOTHING;

    // hold (length=4) with click kept enough
    #1000
    right_noteup = `HOLD_START;
    #700
    clickup = 1'b0;
    #300
    right_noteup = `HOLD_MIDDLE;
    left_noteup = `HOLD_START;
    #1000
    right_noteup = `HOLD_MIDDLE;
    left_noteup = `HOLD_MIDDLE;
    #1000
    right_noteup = `HOLD_MIDDLE;
    left_noteup = `HOLD_MIDDLE;
    #700
    clickup = 1'b1;
    #300
    right_noteup = `NOTHING;
    left_noteup = `HOLD_MIDDLE;
    #1000
    left_noteup = `NOTHING;

    // hold (length=8) with click not kept enough
    #1000
    right_noteup = `HOLD_START;
    #700
    clickup = 1'b0;
    #300
    right_noteup = `HOLD_MIDDLE;
    left_noteup = `HOLD_START;
    #1000
    right_noteup = `HOLD_MIDDLE;
    left_noteup = `HOLD_MIDDLE;
    #1000
    right_noteup = `HOLD_MIDDLE;
    left_noteup = `HOLD_MIDDLE;
    #700
    clickup = 1'b1;
    #300
    right_noteup = `HOLD_MIDDLE;
    left_noteup = `HOLD_MIDDLE;
    #1000
    right_noteup = `HOLD_MIDDLE;
    left_noteup = `HOLD_MIDDLE;
    #1000
    right_noteup = `HOLD_MIDDLE;
    left_noteup = `HOLD_MIDDLE;
    #1000
    right_noteup = `HOLD_MIDDLE;
    left_noteup = `HOLD_MIDDLE;
    #1000
    right_noteup = `NOTHING;
    left_noteup = `HOLD_MIDDLE;
    #1000
    left_noteup = `NOTHING;




    
    #1000
    right_notedown = `TAP;
    #1000
    right_notedown = `NOTHING;
    left_notedown = `TAP;
    #1000
    left_notedown = `NOTHING;

    #2000
    right_notedown = `TAP;
    #960
    clickdown = 0;
    #40
    right_notedown = `NOTHING;
    left_notedown = `TAP;
    #1000
    left_notedown = `NOTHING;
    clickdown = 1;

    #2000
    right_notedown = `HOLD_START;
    #1000
    right_notedown = `HOLD_MIDDLE;
    left_notedown = `HOLD_START;
    #1000
    right_notedown = `HOLD_MIDDLE;
    left_notedown = `HOLD_MIDDLE;
    #1000
    right_notedown = `HOLD_MIDDLE;
    left_notedown = `HOLD_MIDDLE;
    #1000
    right_notedown = `NOTHING;
    left_notedown = `HOLD_MIDDLE;
    #1000
    left_notedown = `NOTHING;

    #1000
    right_notedown = `HOLD_START;
    #700
    clickdown = 1'b0;
    #300
    right_notedown = `HOLD_MIDDLE;
    left_notedown = `HOLD_START;
    #1000
    right_notedown = `HOLD_MIDDLE;
    left_notedown = `HOLD_MIDDLE;
    #1000
    right_notedown = `HOLD_MIDDLE;
    left_notedown = `HOLD_MIDDLE;
    #700
    clickdown = 1'b1;
    #300
    right_notedown = `NOTHING;
    left_notedown = `HOLD_MIDDLE;
    #1000
    left_notedown = `NOTHING;
    
    #1000
    right_notedown = `HOLD_START;
    #700
    clickdown = 1'b0;
    #300
    right_notedown = `HOLD_MIDDLE;
    left_notedown = `HOLD_START;
    #1000
    right_notedown = `HOLD_MIDDLE;
    left_notedown = `HOLD_MIDDLE;
    #1000
    right_notedown = `HOLD_MIDDLE;
    left_notedown = `HOLD_MIDDLE;
    #700
    clickdown = 1'b1;
    #300
    right_notedown = `HOLD_MIDDLE;
    left_notedown = `HOLD_MIDDLE;
    #1000
    right_notedown = `HOLD_MIDDLE;
    left_notedown = `HOLD_MIDDLE;
    #1000
    right_notedown = `HOLD_MIDDLE;
    left_notedown = `HOLD_MIDDLE;
    #1000
    right_notedown = `HOLD_MIDDLE;
    left_notedown = `HOLD_MIDDLE;
    #1000
    right_notedown = `NOTHING;
    left_notedown = `HOLD_MIDDLE;
    #1000
    left_notedown = `NOTHING;
end

endmodule