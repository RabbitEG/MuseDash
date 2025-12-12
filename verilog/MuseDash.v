module MuseDash #(
    parameter div_cnt = 1875000 
    // div_cnt = 50,000,000 / (bpm * 4 / 60) / 2 = 375,000,000 / bpm;
) (
    input           clk,
    input           rst_n,//rst_n要不用开关吧
    input           restart,
    input           clickup,
    input           clickdown,

    output          LCD_E,           //1602使能引脚，1时读取信息，1->0（下降沿）执行命令  
    output          LCD_RS,          //1602数据——H/命令——L  选择端  
    output          LCD_RW,          //1602写——L/读——H  选择端  
    output [7:0]    LCD_DATA,        //1602数据传输端口  
    output          LCD_ON,
    //output          LCD_BLON,
    output [6:0]    TotalScore_7Seg_3,
    output [6:0]    TotalScore_7Seg_2,
    output [6:0]    TotalScore_7Seg_1,
    output [6:0]    TotalScore_7Seg_0,
    output [6:0]    CurrentJudgeUp_7Seg_1,
    output [6:0]    CurrentJudgeUp_7Seg_0,
    output [6:0]    CurrentJudgeDown_7Seg_1,
    output [6:0]    CurrentJudgeDown_7Seg_0
);

`define PERFECT 2'b00
`define GOOD 2'b01
`define MISS 2'b10
`define NO_NOTE 2'b11

wire clk_div;

wire address_rst_n;
wire textlcd_rst_n;
wire accum_rst_n;
wire queue_rst_n;
wire judgement_rst_n;

wire clickup_debounced;
wire clickdown_debounced;
wire restart_debounced;

wire accum_now;

wire restart_and_rst_n_debounced;

wire [1:0] cur_resultup;
wire [1:0] cur_resultdown;
wire [1:0] rom_notedown;
wire [1:0] rom_noteup;
wire [15:0] queue_noteup_bit0;
wire [15:0] queue_noteup_bit1;
wire [15:0] queue_notedown_bit0;
wire [15:0] queue_notedown_bit1;
wire [1:0] prev_noteup;
wire [1:0] prev_notedown;
wire [1:0] next_noteup;
wire [1:0] next_notedown;
wire [15:0] total_score;
wire [15:0] cur_score;
wire [11:0] rom_addr;

//clk_div
Clk_Div #(
    .div_cnt(div_cnt)
) clock_divider (
    .clk (clk),
    .rst_n (rst_n),

    .clk_div (clk_div)
);

//address
Address_Generator addr_gen(
    .clk_div (clk_div),
    .rst_n (address_rst_n),

    .address (rom_addr)
);

//7seg
CurrentJudge7Seg cur_judgeup_7seg(
    .judgement (cur_resultup),

    .hex1 (CurrentJudgeDown_7Seg_1),
    .hex0 (CurrentJudgeDown_7Seg_0)
);
CurrentJudge7Seg cur_judgedown_7seg(
    .judgement (cur_resultdown),

    .hex1 (CurrentJudgeUp_7Seg_1),
    .hex0 (CurrentJudgeUp_7Seg_0)
);
TotalScore7Seg total_score_7seg(
    .score_bcd (total_score),

    .hex3 (TotalScore_7Seg_3),
    .hex2 (TotalScore_7Seg_2),
    .hex1 (TotalScore_7Seg_1),
    .hex0 (TotalScore_7Seg_0)
);

//TextLCD
TextLCD textlcd(
    .clk (clk),
    .rst_n (textlcd_rst_n),
    .noteup_bit0 (queue_noteup_bit0),
    .noteup_bit1 (queue_noteup_bit1),
    .notedown_bit0 (queue_notedown_bit0),
    .notedown_bit1 (queue_notedown_bit1),

    .LCD_E (LCD_E),
    .LCD_RS (LCD_RS),
    .LCD_RW (LCD_RW),
    .LCD_DATA (LCD_DATA),
    .LCD_ON (LCD_ON)
);

//Debouncers
Debouncer restart_debouncer(
    .clk (clk),
    .rst_n (rst_n),
    .click_in (restart),

    .click_out (restart_debounced)
);
Debouncer clickup_debouncer(
    .clk (clk),
    .rst_n (rst_n),
    .click_in (clickup),

    .click_out (clickup_debounced)
);
Debouncer clickdown_debouncer(
    .clk (clk),
    .rst_n (rst_n),
    .click_in (clickdown),

    .click_out (clickdown_debounced)
);

//Judgement to Score
Judgement judge(
    .clk (clk),
    .clk_div (clk_div),
    .rst_n (judgement_rst_n),
    .clickup (clickup_debounced),
    .clickdown (clickdown_debounced),
    .left_noteup (prev_noteup),
    .left_notedown (prev_notedown),
    .right_noteup (next_noteup),
    .right_notedown (next_notedown),

    .resultup (cur_resultup),
    .resultdown (cur_resultdown),
    .accum_now (accum_now)
);
ScoreConversion score_convesion(
    .judgement_up (cur_resultup),
    .judgement_down (cur_resultdown),

    .score (cur_score)
);

//Accumulator
Accumulator accum(
    .clk (clk),
    .rst_n (accum_rst_n),
    .accum_now (accum_now),
    .score (cur_score),

    .score_accum (total_score)
);

//Queue
Queue note_queue(
    .clk_div (clk_div),
    .noteup (rom_noteup),
    .notedown (rom_notedown),
    .rst_n (queue_rst_n),

    .noteup_bit0 (queue_noteup_bit0),
    .noteup_bit1 (queue_noteup_bit1),
    .notedown_bit0 (queue_notedown_bit0),
    .notedown_bit1 (queue_notedown_bit1)
);

//ROM
ROM chart(
    .addr (rom_addr),
    
    .noteup (rom_noteup),
    .notedown (rom_notedown)
);

// logic
assign prev_noteup = {queue_noteup_bit1[0],queue_noteup_bit0[0]};
assign prev_notedown = {queue_notedown_bit1[0],queue_notedown_bit0[0]};
assign next_noteup = {queue_noteup_bit1[1],queue_noteup_bit0[1]};
assign next_notedown = {queue_notedown_bit1[1],queue_notedown_bit0[1]};

assign restart_and_rst_n_debounced = !restart_debounced || !rst_n;

assign address_rst_n = !restart_and_rst_n_debounced;
assign accum_rst_n = !restart_and_rst_n_debounced;
assign queue_rst_n = !restart_and_rst_n_debounced;
assign textlcd_rst_n = !restart_and_rst_n_debounced;
assign judgement_rst_n = !restart_and_rst_n_debounced;

//assign LCD_BLON = 1'b1;

endmodule