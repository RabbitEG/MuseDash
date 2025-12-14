`timescale 1ns/1ps

module ScoreConversion_tb();

reg [1:0] up;
reg [1:0] down;
wire [15:0] out;

ScoreConversion testbench_sc (
    .judgement_up (up),
    .judgement_down (down),

    .score (out)
);

`define PERFECT 2'b00
`define GOOD 2'b01
`define MISS 2'b10
`define NO_NOTE 2'b11

initial begin
    up = `PERFECT;
    down = `NO_NOTE;
    #10
    up = `GOOD;
    #10
    down = `PERFECT;
    #10
    up = `PERFECT;
end

endmodule