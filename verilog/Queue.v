module Queue(
    input clk_div,
    input [1:0] noteup,
    input [1:0] notedown,
    input rst_n,
    
    output reg [15:0]   noteup_bit0,
    output reg [15:0]   noteup_bit1,
    output reg [15:0]   notedown_bit0,
    output reg [15:0]   notedown_bit1
);

always @(posedge clk_div or negedge rst_n) begin
    if(!rst_n) begin
        noteup_bit0     <= 'd0;
        noteup_bit1     <= 'd0;
        notedown_bit0   <= 'd0;
        notedown_bit1   <= 'd0;
    end else begin
        noteup_bit0     <= {noteup[0],noteup_bit0[15:1]};
        noteup_bit1     <= {noteup[1],noteup_bit1[15:1]};
        notedown_bit0   <= {notedown[0],notedown_bit0[15:1]};
        notedown_bit1   <= {notedown[1],notedown_bit1[15:1]};
    end
end

endmodule