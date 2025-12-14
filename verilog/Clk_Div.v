module Clk_Div #(
    parameter div_cnt = 2500000 // 50MHz to 10Hz (100ms)
    // div_cnt = 50,000,000 / (bpm * 4 / 60) / 2 = 375,000,000 / bpm;
)(
    input clk,
    input rst_n,

    output reg clk_div
);

reg [24:0] cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt <= 'd0;
        clk_div <= 'd0;
    end
    else if(cnt == div_cnt - 1) begin
        clk_div <= ~clk_div;
        cnt <= 'd0;
    end
    else
        cnt <= cnt + 'd1;
end

endmodule