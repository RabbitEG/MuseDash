module Accumulator(
    input               clk,
    input               rst_n,
    input               accum_now,
    input [15:0]        score,

    output reg [15:0]   score_accum
);

wire        cin;
wire        carry_from_one;
wire        carry_from_ten;
wire        carry_from_hundred;
assign      cin = 1'b0;

reg [3:0]   thousand;
reg [3:0]   hundred;
reg [3:0]   ten;
reg [3:0]   one;

reg [3:0]   accum_thousand;
reg [3:0]   accum_hundred;
reg [3:0]   accum_ten;
reg [3:0]   accum_one;
reg [15:0]  accum;

wire[3:0]   sum_thousand;
wire[3:0]   sum_hundred;
wire[3:0]   sum_ten;
wire[3:0]   sum_one;
reg [15:0]  sum;

BCD_Adder one_adder(
    .a      (one),
    .b      (accum_one),
    .cin    (cin),

    .cout   (carry_from_one),
    .s      (sum_one)
);
BCD_Adder ten_adder(
    .a      (ten),
    .b      (accum_ten),
    .cin    (carry_from_one),

    .cout   (carry_from_ten),
    .s      (sum_ten)
);
BCD_Adder hundred_adder(
    .a      (hundred),
    .b      (accum_hundred),
    .cin    (carry_from_ten),

    .cout   (carry_from_hundred),
    .s      (sum_hundred)
);
BCD_Adder thousand_adder(
    .a      (thousand),
    .b      (accum_thousand),
    .cin    (carry_from_hundred),

    //.cout   (carry_from_thousand),
    .s      (sum_thousand)
);

always @(*) begin
    accum_thousand  = accum[15:12];
    accum_hundred   = accum[11:8];
    accum_ten       = accum[7:4];
    accum_one       = accum[3:0];
    thousand        = score[15:12];
    hundred         = score[11:8];
    ten             = score[7:4];
    one             = score[3:0];
    sum             = {sum_thousand, sum_hundred, sum_ten, sum_one};
    score_accum     = accum;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin accum <= 16'd0; end
    else if(accum_now)
    begin accum <= sum; end
    else
    begin accum <= accum; end
end

endmodule