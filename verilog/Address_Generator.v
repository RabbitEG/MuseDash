module Address_Generator (
    input clk_div,
    input rst_n,

    output reg [11:0] address
);

always @(posedge clk_div or negedge rst_n) begin
    if(!rst_n) begin
        address <= 12'd0;
    end else if(address == 12'd4095) begin
        address <= address;
    end else begin
        address <= address + 12'd1;
    end
end
    
endmodule