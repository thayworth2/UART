module uart_rx
#(parameter DBIT = 8,
			   SB_TICK = 16
)
(
input wire clk, reset,
input wire rx, s_tick,
output reg rx_done_tick,
output wire [7:0]dout
);

	// setting up the states
	localparam [1:0] 
			idle = 2'b00,
			start = 2'b01,
			data = 2'b10,
			stop = 2'b11;

		// setting up registers and synchronous logic/registers
		reg [1:0] state_reg, state_next;
		reg [3:0] s_reg, s_next;
		reg [2:0] n_reg, n_next;
		reg [7:0] b_reg, b_next;
			
		always@(posedge clk, posedge reset) begin
			if(reset) begin
				state_reg = idle;
				s_reg = 0;
				n_reg = 0;
				b_reg = 0;
			end
			else begin
				state_reg = state_next;
				s_reg = s_next;
				n_reg = n_next;
				b_reg = b_next;
			end
		end
			
		// next state logic
		always@(*) begin
			// define next state as current state unless something changes
			state_next = state_reg;
			s_next = s_reg;
			n_next = n_reg;
			b_next = b_reg;
			case(state_reg)
				idle:
					if(rx == 0)begin
						s_next = 0;
						state_next = start;
					end
				start:
					if(s_tick == 1)begin
						if(s_reg == 7) begin
							s_next = 0;
							n_next = 0;
							state_next = data;
						end else begin
							s_next = s_reg + 1;
						end
					end
				data:
					if(s_tick) begin
						if(s_reg == 15) begin
							s_next = 0;
							b_next = {rx, b_reg[7:1]};
							if(n_reg == (DBIT -1)) begin
								state_next = stop;
							end else begin
								n_next = n_reg + 1;
							end
						end else begin
							s_next = s_reg + 1;
						end
					end
				stop:
					if(s_tick == 1) begin
						if(s_reg == (SB_TICK-1))begin
							rx_done_tick = 1;
							state_next = idle;
						end else begin
							s_next = s_reg + 1;
						end
					end
			endcase
		end
		// output logic
		assign dout = b_reg;
			
		

endmodule