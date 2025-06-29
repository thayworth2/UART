module mod_m_counter #(
parameter N = 8,
			 M = 163
)
(
input wire clk,
input wire reset,
output wire max_tick,
output wire [N-1:0] q

);

	reg [N-1:0] r_reg;
	wire [N-1:0] r_next;
	
	always@(posedge clk, posedge reset) begin
		if(reset) begin
			r_reg <= 0;
		end else begin
			r_reg <= r_next; 
		end
	end
	
	
	assign r_next = (r_reg==(M-1)) ? 0 : r_reg + 1;
	assign max_tick = (r_reg==(M-1)) ? 1'b1 : 1'b0;
	assign q = r_reg;
	
endmodule