module Judgement (
    input               clk,
    input               clk_div,
    input               rst_n,
    input               clickup,
    input               clickdown,
    input [1:0]         left_noteup,
    input [1:0]         left_notedown,
    input [1:0]         right_noteup,
    input [1:0]         right_notedown,

    output reg [1:0]    resultup,
    output reg [1:0]    resultdown,
    output reg          accum_now
);

`define PERFECT 2'b00
`define GOOD 2'b01
`define MISS 2'b10
`define NO_NOTE 2'b11

`define NOTHING 2'b00
`define TAP 2'b01
`define HOLD_START 2'b10
`define HOLD_MIDDLE 2'b11

`define PUSHED 1'b0
`define NOT_PUSHED 1'b1

reg clk_div_delay;
reg clk_div_delay2;
reg clk_div_posedge;

reg [1:0] resultup_cond;
reg [1:0] resultdown_cond;

reg noteup_judged;
reg notedown_judged;

reg count2;
reg count2_delay;
reg count2_delay2;
reg count2_negedge;

reg [1:0] cur_noteup;
reg [1:0] cur_noteup_delay;
reg [1:0] cur_noteup_delay2;
reg [1:0] cur_notedown;
reg [1:0] cur_notedown_delay;
reg [1:0] cur_notedown_delay2;

reg [1:0] judge_noteup;
reg [1:0] judge_notedown;

reg [1:0] judge_state_up;
reg [1:0] judge_state_down;
reg [1:0] next_state_up;
reg [1:0] next_state_down;

reg clickup_prev;
reg clickup_prev2;
reg clickdown_prev;
reg clickdown_prev2;
reg clickup_posedge;
reg clickdown_posedge;

wire random;
LFSR random_gen (
    .clk (clk),
    .rst_n (rst_n),

    .random_num (random)
);

always @(posedge clk_div or negedge rst_n) begin
    if(!rst_n) begin
        count2 <= 1'b0;
    end else begin
        count2 <= !count2;
    end
    if(!rst_n) begin
        resultup <= `NO_NOTE;
        resultdown <= `NO_NOTE;
    end else if(count2 == 1'b1) begin
        resultup <= resultup_cond;
        resultdown <= resultdown_cond;
    end else begin
        resultup <= resultup;
        resultdown <= resultdown;
    end
end

always @(*) begin
    clickup_posedge = (clickup_prev2 == `NOT_PUSHED) && (clickup == `PUSHED);
    clickdown_posedge = (clickdown_prev2 == `NOT_PUSHED) && (clickdown == `PUSHED);
    clk_div_posedge = clk_div && (!clk_div_delay2);
    count2_negedge = !count2 && count2_delay;

    if(judge_state_up == `GOOD && !noteup_judged) begin
        resultup_cond = `MISS;
    end else if(judge_state_up == `PERFECT && random) begin
        resultup_cond = `GOOD;
    end else begin
        resultup_cond = judge_state_up;
    end
    if(judge_state_down == `GOOD && !notedown_judged) begin
        resultdown_cond = `MISS;
    end else if(judge_state_down == `PERFECT && random) begin
        resultdown_cond = `GOOD;
    end else begin
        resultdown_cond = judge_state_down;
    end
    
    accum_now = clk_div_posedge && count2 == 1'b0;
end

// FSM
always @(*) begin
    case(judge_state_up) // synopsys parallel case
    `PERFECT: begin
        if(cur_noteup == `NOTHING && cur_noteup_delay == `NOTHING && cur_noteup_delay2 == `NOTHING) begin
            next_state_up = `NO_NOTE;
        end else if((cur_noteup == `TAP || cur_noteup == `HOLD_START) && (clk_div != count2) && (!noteup_judged)) begin
            next_state_up = `GOOD;
        end else if((cur_noteup == `HOLD_MIDDLE) && (clickup == `NOT_PUSHED) && (count2 == 1'b0)) begin
            next_state_up = `MISS;
        end else if(noteup_judged) begin
            next_state_up = `PERFECT;
        end else if(cur_noteup == `NOTHING) begin
            next_state_up = `NO_NOTE;
        end else begin
            next_state_up = `PERFECT;
        end
    end
    `GOOD: begin
        if(cur_noteup == `NOTHING && cur_noteup_delay == `NOTHING && cur_noteup_delay2 == `NOTHING) begin
            next_state_up = `NO_NOTE;
        end else if((clk_div == count2 && !noteup_judged) || cur_noteup == `HOLD_MIDDLE) begin
            next_state_up = `PERFECT;
        end else if(noteup_judged) begin
            next_state_up = `GOOD;
        end else if(cur_noteup == `NOTHING) begin
            next_state_up = `NO_NOTE;
        end else begin 
            next_state_up = `GOOD;
        end
    end        
    `MISS: begin
        if(cur_noteup == `NOTHING && cur_noteup_delay == `NOTHING && cur_noteup_delay2 == `NOTHING) begin
            next_state_up = `NO_NOTE;
        end else if(cur_noteup == `TAP || cur_noteup == `HOLD_START)begin
            next_state_up = `GOOD;
        end else if(cur_noteup == `HOLD_MIDDLE && (!noteup_judged))begin
            next_state_up = `PERFECT;
        end else if(noteup_judged) begin
            next_state_up = `MISS;
        end else if(cur_noteup == `NOTHING) begin
            next_state_up = `NO_NOTE;
        end else begin
            next_state_up = `MISS;
        end
    end    
    `NO_NOTE: begin
        if(cur_noteup == `TAP || cur_noteup == `HOLD_START) begin
            next_state_up = `GOOD;
        end else if(cur_noteup == `HOLD_MIDDLE) begin
            next_state_up = `PERFECT;
        end else begin
            next_state_up = `NO_NOTE;
        end
    end
    default: begin
        next_state_up = `NO_NOTE;
    end
    endcase

    case(judge_state_down)
    `PERFECT: begin
        if(cur_notedown == `NOTHING && cur_notedown_delay == `NOTHING && cur_notedown_delay2 == `NOTHING) begin
            next_state_down = `NO_NOTE;
        end else if((cur_notedown == `TAP || cur_notedown == `HOLD_START) && (clk_div != count2) && (!notedown_judged)) begin
            next_state_down = `GOOD;
        end else if((cur_notedown == `HOLD_MIDDLE) && (clickdown == `NOT_PUSHED) && (count2 == 1'b0)) begin
            next_state_down = `MISS;
        end else if(notedown_judged) begin
            next_state_down = `PERFECT;
        end else if(cur_notedown == `NOTHING) begin
            next_state_down = `NO_NOTE;
        end else begin
            next_state_down = `PERFECT;
        end
    end
    `GOOD: begin
        if(cur_notedown == `NOTHING && cur_notedown_delay == `NOTHING && cur_notedown_delay2 == `NOTHING) begin
            next_state_down = `NO_NOTE;
        end else if((clk_div == count2 && !notedown_judged) || cur_notedown == `HOLD_MIDDLE) begin
            next_state_down = `PERFECT;
        end else if(notedown_judged) begin
            next_state_down = `GOOD;
        end else if(cur_notedown == `NOTHING) begin
            next_state_down = `NO_NOTE;
        end else begin 
            next_state_down = `GOOD;
        end
    end        
    `MISS: begin
        if(cur_notedown == `NOTHING && cur_notedown_delay == `NOTHING && cur_notedown_delay2 == `NOTHING) begin
            next_state_down = `NO_NOTE;
        end else if(cur_notedown == `TAP || cur_notedown == `HOLD_START)begin
            next_state_down = `GOOD;
        end else if(cur_notedown == `HOLD_MIDDLE && (!notedown_judged))begin
            next_state_down = `PERFECT;
        end else if(notedown_judged) begin
            next_state_down = `MISS;
        end else if(cur_notedown == `NOTHING) begin
            next_state_down = `NO_NOTE;
        end else begin
            next_state_down = `MISS;
        end
    end    
    `NO_NOTE: begin
        if(cur_notedown == `TAP || cur_notedown == `HOLD_START) begin
            next_state_down = `GOOD;
        end else if(cur_notedown == `HOLD_MIDDLE) begin
            next_state_down = `PERFECT;
        end else begin
            next_state_down = `NO_NOTE;
        end
    end
    default: begin
        next_state_down = `NO_NOTE;
    end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    clickup_prev <= clickup;
    clickup_prev2 <= clickup_prev;
    clickdown_prev <= clickdown;
    clickdown_prev2 <= clickdown_prev;
    count2_delay <= count2;
    count2_delay2 <= count2_delay;
    cur_noteup_delay <= cur_noteup;
    cur_noteup_delay2 <= cur_noteup_delay;
    cur_notedown_delay <= cur_notedown;
    cur_notedown_delay2 <= cur_notedown_delay;
    if(!rst_n) begin
        clk_div_delay <= 1'b0;
        clk_div_delay2 <= 1'b0;
        judge_state_up <= `NO_NOTE;
        judge_state_down <= `NO_NOTE;
    end else begin
        clk_div_delay <= clk_div;
        clk_div_delay2 <= clk_div_delay;
        judge_state_up <= next_state_up;
        judge_state_down <= next_state_down;
    end
end


always @(posedge clk) begin
    if(!rst_n) begin
        noteup_judged <= 1'b0;
    end else begin
         if(cur_noteup == `NOTHING && cur_noteup_delay == `NOTHING && cur_noteup_delay2 == `NOTHING) begin
            noteup_judged <= 1'b0;
        end else if(clk_div_posedge && count2_negedge) begin
            noteup_judged <= 1'b0;
        end else if(clickup_posedge && (cur_noteup == `TAP || cur_noteup == `HOLD_START)) begin
            noteup_judged <= 1'b1;
        end else if(count2 == 1'b1 && cur_noteup == `HOLD_MIDDLE) begin
            noteup_judged <= 1'b1;
        end else if(!noteup_judged && cur_noteup == `HOLD_MIDDLE && clickup == `NOT_PUSHED && count2 == 1'b0) begin
            noteup_judged <= 1'b1;
        end else begin
            noteup_judged <= noteup_judged;
        end
    end
    if(!rst_n) begin
        notedown_judged <= 1'b0;
    end else begin
         if(cur_notedown == `NOTHING && cur_notedown_delay == `NOTHING && cur_notedown_delay2 == `NOTHING) begin
            notedown_judged <= 1'b0;
        end else if(clk_div_posedge && count2_negedge) begin
            notedown_judged <= 1'b0;
        end else if(clickdown_posedge && (cur_notedown == `TAP || cur_notedown == `HOLD_START)) begin
            notedown_judged <= 1'b1;
        end else if(count2 == 1'b1 && cur_notedown == `HOLD_MIDDLE) begin
            notedown_judged <= 1'b1;
        end else if(!notedown_judged && cur_notedown == `HOLD_MIDDLE && clickdown == `NOT_PUSHED && count2 == 1'b0) begin
            notedown_judged <= 1'b1;
        end else begin
            notedown_judged <= notedown_judged;
        end
    end
    if(count2 == 1'b1 || (count2_negedge && !clk_div_posedge)) begin
        cur_noteup <= left_noteup;
        cur_notedown <= left_notedown;
    end else if(clk_div_posedge) begin
        cur_noteup <= `NOTHING;
        cur_notedown <= `NOTHING;
    end else begin
        cur_noteup <= right_noteup;
        cur_notedown <= right_notedown;
    end
end

// cur_noteup = count2 ? left_noteup : right_notup;

endmodule