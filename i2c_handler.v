module i2c_handler(
	input i_clk,
	input i_begin,
	input i_writeEnable,
	input [6:0] i_i2cAddress,
	input [7:0] i_regAddress,
	input [7:0] i_txData,
	inout i2c_scl,
	inout i2c_sda
);

parameter I2C_BASE_ADDRESS = 8'h40; // Base address of I2C registers
localparam CONTROL_REG_OFFSET = 0;
localparam COMMAND_REG_OFFSET = 1;
localparam BR0_REG_OFFSET = 2;
localparam BR1_REG_OFFSET = 3;
localparam TX_REG_OFFSET = 4;
localparam STATUS_REG_OFFSET = 5;
localparam GEN_CALL_REG_OFFSET = 6;
localparam RX_REG_OFFSET = 7;
localparam IRQ_REG_OFFSET = 8;
localparam IRQ_EN_REG_OFFSET = 9;

reg r_wbBegin = 0;
reg r_wbWriteEnable = 0;
reg [7:0] r_wbAddress = 0;
reg [7:0] r_wbTxData = 0;
wire [7:0] w_wbRxData;
reg r_i2cWriteEnable = 0;
reg[7:0] r_i2cRegAddress = 0;
reg [7:0] r_i2cTxData = 0;

wishbone_handler wishbone_inst1(
	.i_clk(i_clk),
	.i_begin(r_wbBegin),
	.i_writeEnable(r_wbWriteEnable),
	.o_done(w_wbDone),
	.i_address(r_wbAddress),
	.i_writeData(r_wbTxData),
	.o_readData(w_wbRxData),
	.i2c_scl(i2c_scl),
	.i2c_sda(i2c_sda)
);

reg [3:0] r_state = 0;
localparam s_START = 0;
localparam s_INIT = 1;
localparam s_IDLE = 2;
localparam s_SENDING_SLAVE_ADDRESS = 3;
localparam s_SENDING_TX_COMMAND = 4;
localparam s_DONE = 5;

always @(posedge i_clk) begin
	case (r_state)
		s_START:
		begin
			r_wbAddress <= I2C_BASE_ADDRESS + CONTROL_REG_OFFSET;
			r_wbTxData <= 8'b10000000;
			r_wbWriteEnable <= 1'b1;
			r_wbBegin <= 1'b1;
			r_state <= s_INIT;		
		end  // case s_START
		
		s_INIT:
		begin
			r_wbBegin <= 1'b0;
			r_wbWriteEnable <= 1'b0;
			if (w_wbDone) begin

				r_state <= s_IDLE;
			end else begin
				r_state <= s_INIT;
			end	
		end  // case s_INIT
		
		s_IDLE:
		begin
			r_wbBegin <= 1'b0;
			r_wbWriteEnable <= 1'b0;
			if(i_begin) begin
				// Copy all data into local registers
				r_i2cRegAddress <= i_regAddress;
				r_i2cWriteEnable <= i_writeEnable;
				r_i2cTxData <= i_writeEnable ? i_txData : 0;
				
				// Start sending I2C slave address
				r_wbAddress <= I2C_BASE_ADDRESS + TX_REG_OFFSET;
				r_wbTxData <= {i_i2cAddress, ~i_writeEnable};
				r_wbWriteEnable <= 1'b1;
				r_wbBegin <= 1'b1;
				
				r_state <= s_SENDING_SLAVE_ADDRESS;
			end else begin
				r_state <= s_IDLE;
			end
		end  // case s_IDLE
		
		s_SENDING_SLAVE_ADDRESS:
		begin
			r_wbBegin <= 1'b0;
			r_wbWriteEnable <= 1'b0;
			if(w_wbDone) begin
				// Write to the WISHBONE command register to start the I2C transaction
				r_wbAddress <= I2C_BASE_ADDRESS + COMMAND_REG_OFFSET;
				r_wbTxData <= 8'h94; // Write with Start condition
				r_wbWriteEnable <= 1'b1;
				r_wbBegin <= 1'b1;
				r_state <= s_IDLE;
			end else begin
				r_state <= s_SENDING_SLAVE_ADDRESS;
			end
		end
	endcase
	
	
end




endmodule