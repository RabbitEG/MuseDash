module LFSR(
    clk,
    rst_n,

    random_num
);

//==========================================================
//                      Declarations
//==========================================================
// Parameters, maybe changeable in future works
parameter           BITS = 13;

// Ports
input               clk;
input               rst_n;
output              random_num;

// Wires
wire                next_bit;

// Regs
reg     [BITS-1 :0] lfsr_reg;

//==========================================================
//                    Logic Instances
//==========================================================
assign random_num   = lfsr_reg[0];
// LFSR Algorithm
assign next_bit     = lfsr_reg[12]
                    ^ lfsr_reg[11]
                    ^ lfsr_reg[10]
                    ^ lfsr_reg[7]
                    ^ lfsr_reg[0];

// Bit Shift
always @(posedge clk) begin
    if(!rst_n) begin
        lfsr_reg = {{(BITS-1){1'b0}},1'b1};
    end else begin
        lfsr_reg = {lfsr_reg[BITS-2:0], next_bit};
    end
end

endmodule