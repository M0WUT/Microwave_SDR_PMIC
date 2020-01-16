`default_nettype none

// Either writes/reads a single byte to/from an I2C slave 


module i2c_handler(
	input wire i_clk,  // Input clock 
	input wire i_begin,  // Logic high will begin I2C transaction
	input wire i_writeEnable,  // High to write i_txData to i_regAddress, Low to read from i_regAddress
	input wire [6:0] i_i2cAddress,  // 7 bit I2C address of slave
	input wire [7:0] i_regAddress,  // Register address within the slave
	input wire [7:0] i_txData,  // Data to write to the register, ignored if i_writeEnable is low when i_begin is asserted
	inout wire i2c_scl,  // SCL line, pass directly to IO
	inout wire i2c_sda,  // SDA line, pass directly to IO
	output reg o_done  // Asserted high for 1 cycle of i_clk to indicate the I2C transaction is complete
	//output wire wbEnable,  // DEBUG
	//input wire i_wbAck
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


//EFB - module for hard peripherals in MachXO2
reg r_wbEnable = 0;
reg r_wbWriteEnable = 0;
reg [7:0] r_wbAddress = 0;
reg [7:0] r_wbTxData = 0;
wire [7:0] w_wbRxData;
wire w_wbAck;
//assign w_wbAck = i_wbAck;  // DEBUG
//assign wbEnable = r_wbEnable;  // DEBUG


efb efb_inst (
	.wb_clk_i(i_clk),
	.wb_rst_i(1'b0),
	.wb_cyc_i(r_wbEnable),
	.wb_stb_i(r_wbEnable), // Active high chip select for WISHBONE bus
    .wb_we_i(r_wbWriteEnable),
	.wb_adr_i(r_wbAddress),
	.wb_dat_i(r_wbTxData),
	.wb_dat_o(w_wbRxData),
	.wb_ack_o(w_wbAck),
    .i2c1_scl(i2c_scl),
	.i2c1_sda(i2c_sda),
	.i2c1_irqo()
);

reg [15:0] r_i2cTxData = 0;
reg r_i2cWriteEnable = 0;
wire [7:0] w_i2cRxData;
reg [1:0] r_i2cTxByteIndex = 0;


localparam s_START = 0;
localparam s_INIT = 1;
localparam s_IDLE = 2;
localparam s_TX_LOADING_SLAVE_ADDRESS = 3;
localparam s_TX_SENDING_SLAVE_ADDRESS = 4;
localparam s_CHECKING_TRRDY = 5;
localparam s_LOADING_DATA = 6;
localparam s_SENDING_DATA = 7;
localparam s_TX_STOP = 8;
localparam s_RX_LOADING_SLAVE_ADDRESS = 9;
localparam s_RX_SENDING_SLAVE_ADDRESS = 10;	  

reg[7:0] r_state = s_START;

always @(posedge i_clk) begin
	case (r_state)
		s_START: begin
			// Enable I2C Core
			r_wbAddress <= (I2C_BASE_ADDRESS + CONTROL_REG_OFFSET);
			r_wbTxData <= 8'h80;
			r_wbEnable <= 1'b1;
			r_wbWriteEnable <= 1'b1;
			r_state <= s_INIT;
		end  // case s_START

		s_INIT: begin
			// Wait for I2C Core to initialise before accepting transactions
			if(w_wbAck) begin
			  	r_state <= s_IDLE;
			end else begin
				r_state <= s_INIT;
			end
		end  // case s_INIT

		s_IDLE: begin
			// Idle state, wait for i_begin to be asserted to start transaction
		  	if(i_begin) begin
			  	// Copy all inputs to local versions
				r_i2cTxData <= (i_writeEnable ? {i_regAddress , i_txData} : {8'b0, i_regAddress});
				r_i2cWriteEnable <= i_writeEnable;
				r_i2cTxByteIndex <= i_writeEnable + 2'd1;  // Send 3 bytes if transmitting (Slave ADDR, Reg ADDR, Data), 2 if reading
				r_state <= s_TX_LOADING_SLAVE_ADDRESS;
			end else begin
				r_wbEnable <= 1'b0;
				r_wbWriteEnable <= 1'b0;
			  	r_state <= s_IDLE;
			end
		end  // case s_IDLE

		s_TX_LOADING_SLAVE_ADDRESS: begin
			// Write first byte (I2C Slave address + R/W bit to I2C TX Reg) over WISHBONE bus
			r_wbAddress <= (I2C_BASE_ADDRESS + TX_REG_OFFSET);
			r_wbTxData <= {i_i2cAddress, 1'b0};
			r_wbEnable <= 1'b1;
			r_wbWriteEnable <= 1'b1;

			if(w_wbAck) begin
				r_wbEnable <= 1'b0;
				r_wbWriteEnable <= 1'b0;
				r_state <= s_TX_SENDING_SLAVE_ADDRESS;
			end else begin
			  	r_state <= r_state;
			end
		end  // case s_TX_LOADING_SLAVE_ADDRESS

		s_TX_SENDING_SLAVE_ADDRESS: begin
		  	// Begin I2C Transaction
			r_wbAddress <= (I2C_BASE_ADDRESS + COMMAND_REG_OFFSET);
			r_wbTxData <= 8'h94; // Begin write, with START condition
			r_wbEnable <= 1'b1;
			r_wbWriteEnable <= 1'b1;

			if(w_wbAck) begin
				r_wbEnable <= 1'b0;
				r_wbWriteEnable <= 1'b0;
				r_state <= s_CHECKING_TRRDY;
			end else begin
			  	r_state <= r_state;
			end
		end  // case s_TX_SENDING_SLAVE_ADDRESS

		s_CHECKING_TRRDY: begin
			// Read Status Registers
			r_wbAddress <= (I2C_BASE_ADDRESS + STATUS_REG_OFFSET);
			r_wbEnable <= 1'b1;
			r_wbWriteEnable <= 1'b0;

			if(w_wbAck) begin
				r_wbEnable <= 1'b0;
				r_wbWriteEnable <= 1'b0;
				if(w_wbRxData[2]) begin  // TRRDY is asserted, I2C write is complete
					if(r_i2cTxByteIndex == 0) begin  // No more data to send
						r_state <= r_i2cWriteEnable ? s_TX_STOP : s_RX_LOADING_SLAVE_ADDRESS;
					end else begin  // Send next byte
					  	r_i2cTxByteIndex <= r_i2cTxByteIndex - 1;
						r_state <= s_LOADING_DATA;
					end
				end else begin
					r_state <= s_CHECKING_TRRDY; // Recheck TRRDY
				end

			end else begin
				r_state <= r_state;
			end
		end  // case s_CHECKING_TRRDY

		s_LOADING_DATA: begin
		  	// Put next data byte into TX Reg
			r_wbAddress <= (I2C_BASE_ADDRESS + TX_REG_OFFSET);
			r_wbTxData <= r_i2cTxData[(r_i2cTxByteIndex * 8)+:8];
			r_wbEnable <= 1'b1;
			r_wbWriteEnable <= 1'b1;

			if(w_wbAck) begin
				r_wbEnable <= 1'b0;
				r_wbWriteEnable <= 1'b0;
				r_state <= s_SENDING_DATA;
			end else begin
			  	r_state <= r_state;
			end
		end  // case s_LOADING_DATA

		s_SENDING_DATA: begin
		  	// Send next data byte
			r_wbAddress <= (I2C_BASE_ADDRESS + COMMAND_REG_OFFSET);
			r_wbTxData <= 8'h14;  // Write, no start condition
			r_wbEnable <= 1'b1;
			r_wbWriteEnable <= 1'b1;

			if(w_wbAck) begin
				r_wbEnable <= 1'b0;
				r_wbWriteEnable <= 1'b0;
				r_state <= s_CHECKING_TRRDY;
			end else begin
			  	r_state <= r_state;
			end
		end  // case s_SENDING_DATA

		s_TX_STOP: begin
		  	// Send next data byte
			r_wbAddress <= (I2C_BASE_ADDRESS + COMMAND_REG_OFFSET);
			r_wbTxData <= 8'h44;  // Send STOP condition
			r_wbEnable <= 1'b1;
			r_wbWriteEnable <= 1'b1;

			if(w_wbAck) begin
				r_wbEnable <= 1'b0;
				r_wbWriteEnable <= 1'b0;
				r_state <= s_IDLE;
			end else begin
			  	r_state <= r_state;
			end
		end  // case s_TX_STOP

		s_TX_STOP: begin
		  	// Send next data byte
			r_wbAddress <= (I2C_BASE_ADDRESS + COMMAND_REG_OFFSET);
			r_wbTxData <= 8'h44;  // Send STOP condition
			r_wbEnable <= 1'b1;
			r_wbWriteEnable <= 1'b1;

			if(w_wbAck) begin
				r_wbEnable <= 1'b0;
				r_wbWriteEnable <= 1'b0;
				r_state <= s_IDLE;
			end else begin
			  	r_state <= r_state;
			end
		end  // case s_TX_STOP

		s_RX_LOADING_SLAVE_ADDRESS: begin
			// Write first byte (I2C Slave address + R/W bit to I2C TX Reg) over WISHBONE bus
			r_wbAddress <= (I2C_BASE_ADDRESS + TX_REG_OFFSET);
			r_wbTxData <= {i_i2cAddress, 1'b1};  // Slave Address with Read
			r_wbEnable <= 1'b1;
			r_wbWriteEnable <= 1'b1;

			if(w_wbAck) begin
				r_wbEnable <= 1'b0;
				r_wbWriteEnable <= 1'b0;
				r_state <= s_RX_SENDING_SLAVE_ADDRESS;
			end else begin
			  	r_state <= r_state;
			end
		end  // case s_RX_LOADING_SLAVE_ADDRESS

		s_RX_SENDING_SLAVE_ADDRESS: begin
		  	// Begin I2C Transaction
			r_wbAddress <= (I2C_BASE_ADDRESS + COMMAND_REG_OFFSET);
			r_wbTxData <= 8'h94; // Begin write, with START condition
			r_wbEnable <= 1'b1;
			r_wbWriteEnable <= 1'b1;

			if(w_wbAck) begin
				r_wbEnable <= 1'b0;
				r_wbWriteEnable <= 1'b0;
				r_state <= s_IDLE;  // DEBUG
			end else begin
			  	r_state <= r_state;
			end
		end  // case s_RX_SENDING_SLAVE_ADDRESS




		







	endcase
end


endmodule