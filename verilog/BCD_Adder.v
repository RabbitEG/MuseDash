module BCD_Adder(
    input [3:0]     a,
    input [3:0]     b,
    input           cin,
    
    output          cout,
    output[3:0]     s
);

wire [4:0] a_extend;
wire [4:0] b_extend;
wire [4:0] cin_extend;

assign a_extend[4]      = 1'b0;
assign a_extend[3:0]    = a;
assign b_extend[4]      = 1'b0;
assign b_extend[3:0]    = b;
assign cin_extend[4:1]  = 3'b000;
assign cin_extend[0]    = cin;

wire [4:0] temp;
wire [4:0] temp_out;

assign temp             = a_extend + b_extend + cin_extend;
assign temp_out         = (temp > 5'd9) ? (temp + 5'd6) : temp;
assign cout             = temp_out[4];
assign s                = temp_out[3:0];

endmodule