module wishbone_handler(
	input i_clk,
	input i_writeEnable,
	input i_begin,
	output o_done,
	input [7:0] i_address,
	input [7:0] i_writeData,
	output reg [7:0] o_readData,
	inout i2c_scl,
	inout i2c_sda
);

reg[1:0] r_state = 0; 
localparam s_IDLE = 0;
localparam s_BUSY = 1;
localparam s_DONE = 2;

reg r_enable = 0;  // Enables transaction on WISHBONE bus
reg r_writeEnable;  // 1 = Write, 0 = Read
reg[7:0] r_address = 0;
reg[7:0] r_txData = 0;
wire[7:0] w_rxData;
wire w_ack;
assign o_done = (r_state == s_DONE) && w_ack;


//I2C Transmitter
efb efb_inst (
	.wb_clk_i(i_clk),
	.wb_rst_i(1'b0),
	.wb_cyc_i(r_enable),
	.wb_stb_i(r_enable), // Active high chip select for WISHBONE bus
    .wb_we_i(r_writeEnable),
	.wb_adr_i(r_address),
	.wb_dat_i(r_txData),
	.wb_dat_o(w_rxData),
	.wb_ack_o(w_ack), 
    .i2c1_scl(i2c_scl),
	.i2c1_sda(i2c_sda),
	.i2c1_irqo()
);

always @(posedge i_clk) begin
	
	case (r_state)
		s_IDLE:
		begin
			if (i_begin) begin
				r_address <= {1'b0, i_address};
				r_txData <= i_writeData;
				r_enable <= 1'b1;
				r_writeEnable <= i_writeEnable;
				r_state <= s_BUSY;
			end else begin
				r_address <= 0;
				r_txData <= 0;
				r_enable <= 1'b0;
				r_writeEnable <= 1'b0;
				r_state <= s_IDLE;
			end
		end  // case s_IDLE
		
		s_BUSY:
		begin
				r_address <= r_address;
				r_txData <= r_txData;
				r_enable <= 1'b1;
				r_writeEnable <= r_writeEnable;
				r_state <= s_DONE;
		end  // case s_BUSY
		
		s_DONE:
		begin
			if (w_ack) begin
				r_state <= s_IDLE;
			end else begin	
				r_state <= s_DONE;
			end
			
		end  // case s_DONE
	endcase
end


endmodule