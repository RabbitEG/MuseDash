module Debouncer(
	input clk,
	input rst_n,
	input click_in,

	output reg click_out 
);
	
	parameter count_limit = 10; // debounce counter limit
	parameter count_width = 4; // debounce counter width

	reg [count_width-1:0] counter; // debounce counter
	reg counting; // debounce counting flag

	wire start = (click_out ^ click_in) & ~counting; // debounce start flag

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			click_out <= 0;
			counting <= 0;
		end
		else if (start) begin
			counting <= 1;
		end
		else if (~|counter) begin
			counting <= 0; // when counter reaches 0, input is stable
			click_out <= click_in;
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			counter <= count_limit;
		end
		else if (counting) begin
			counter <= counter - 1;
		end
		else begin
			counter <= count_limit; // when counting is done, reset counter
		end
	end

endmodule

// module Debouncer (
//     input clk,
//     input rst_n,
//     input click_in,

//     output reg click_out
// );

// always @(*) begin
//     click_out = click_in;
// end
    
// endmodule