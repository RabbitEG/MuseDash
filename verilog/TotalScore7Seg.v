module TotalScore7Seg (
    input [15:0] score_bcd,

    output reg [6:0] hex3,
    output reg [6:0] hex2,
    output reg [6:0] hex1,
    output reg [6:0] hex0
);

localparam zero = 7'b100_0000;
localparam one = 7'b111_1001;
localparam two = 7'b010_0100;
localparam three = 7'b011_0000;
localparam four = 7'b001_1001;
localparam five = 7'b001_0010;
localparam six = 7'b000_0010;
localparam seven = 7'b111_1000;
localparam eight = 7'b000_0000;
localparam nine = 7'b001_0000;

always @(*) begin
    case(score_bcd[15:12])
        4'd0:hex3=      zero;
        4'd1:hex3=      one;
        4'd2:hex3=      two;
        4'd3:hex3=      three;
        4'd4:hex3=      four;
        4'd5:hex3=      five;
        4'd6:hex3=      six;
        4'd7:hex3=      seven;
        4'd8:hex3=      eight;
        4'd9:hex3=      nine;
        default:hex3=   7'b011_0110;
    endcase
    case(score_bcd[11:8])
        4'd0:hex2=      zero;
        4'd1:hex2=      one;
        4'd2:hex2=      two;
        4'd3:hex2=      three;
        4'd4:hex2=      four;
        4'd5:hex2=      five;
        4'd6:hex2=      six;
        4'd7:hex2=      seven;
        4'd8:hex2=      eight;
        4'd9:hex2=      nine;
        default:hex2=    7'b011_0110;
    endcase
    case(score_bcd[7:4])
        4'd0:hex1=      zero;
        4'd1:hex1=      one;
        4'd2:hex1=      two;
        4'd3:hex1=      three;
        4'd4:hex1=      four;
        4'd5:hex1=      five;
        4'd6:hex1=      six;
        4'd7:hex1=      seven;
        4'd8:hex1=      eight;
        4'd9:hex1=      nine;
        default:hex1=    7'b011_0110;
    endcase
    case(score_bcd[3:0])
        4'd0:hex0=      zero;
        4'd1:hex0=      one;
        4'd2:hex0=      two;
        4'd3:hex0=      three;
        4'd4:hex0=      four;
        4'd5:hex0=      five;
        4'd6:hex0=      six;
        4'd7:hex0=      seven;
        4'd8:hex0=      eight;
        4'd9:hex0=      nine;
        default:hex0=    7'b011_0110;
    endcase
end
    
endmodule