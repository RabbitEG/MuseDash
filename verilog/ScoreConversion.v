module ScoreConversion (
    input [1:0] judgement_up,
    input [1:0] judgement_down,

    output reg [15:0] score
);

`define PERFECT 2'b00
`define GOOD 2'b01
`define MISS 2'b10
`define NO_NOTE 2'b11

`define PERFECT_SCORE 16'd2
`define GOOD_SCORE 16'd1
`define MISS_SCORE 16'd0
`define NO_NOTE_SCORE 16'd0

reg [15:0] score_up;
reg [15:0] score_down;

always @(*) begin
    case (judgement_up)
        `PERFECT: begin
            score_up = `PERFECT_SCORE;
        end
        `GOOD: begin
            score_up = `GOOD_SCORE;
        end
        `MISS: begin
            score_up = `MISS_SCORE;
        end
        `NO_NOTE: begin
            score_up = `NO_NOTE_SCORE;
        end
        default: begin
            score_up = `NO_NOTE_SCORE;
        end
    endcase
    
    case (judgement_down)
        `PERFECT: begin
            score_down = `PERFECT_SCORE;
        end
        `GOOD: begin
            score_down = `GOOD_SCORE;
        end
        `MISS: begin
            score_down = `MISS_SCORE;
        end
        `NO_NOTE: begin
            score_down = `NO_NOTE_SCORE;
        end
        default: begin
            score_down = `NO_NOTE_SCORE;
        end
    endcase

    score = score_up + score_down;
end
endmodule