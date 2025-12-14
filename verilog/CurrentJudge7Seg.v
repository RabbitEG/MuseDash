module CurrentJudge7Seg (
    input [1:0] judgement,

    output reg [6:0] hex1,
    output reg [6:0] hex0
);

`define PERFECT 2'b00
`define GOOD 2'b01
`define MISS 2'b10
`define NO_NOTE 2'b11

always @(*) begin
    case (judgement)
        `PERFECT: begin
            //Shown PF
            hex1 = 7'b000_1100;
            hex0 = 7'b000_1110;
        end
        `GOOD: begin
            //Shown GD
            hex1 = 7'b100_0010;
            hex0 = 7'b100_0000;
        end
        `MISS: begin
            //Shown FL
            hex1 = 7'b000_1110;
            hex0 = 7'b100_0111;
        end
        `NO_NOTE: begin
            //Shown --
            hex1 = 7'b011_1111;
            hex0 = 7'b011_1111;
        end
        default: begin
            //Shown Nothing
            hex1 = 7'b111_1111;
            hex0 = 7'b111_1111;
        end
    endcase
end
endmodule