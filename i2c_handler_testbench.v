`timescale 1ns / 1ns

module i2c_handler_testbench;
	
	reg clk;
	reg r_begin;
	reg r_writeEnable;
	reg [6:0] r_address;
	reg [7:0] r_data;
	wire scl;
	wire sda;
	wire done; 
	wire w_wbEnable;
	
	i2c_handler dut(
	.i_clk(clk),  // Input clock 
	.i_begin(r_begin),  // Logic high will begin I2C transaction
	.i_writeEnable(1'b0),  // High to write i_txData to i_regAddress, Low to read from i_regAddress
	.i_i2cAddress(7'h60),  // 7 bit I2C address of slave
	.i_regAddress(8'h12),  // Register address within the slave
	.i_bytesToRx(2'd2),
	.i_txData(8'h34),  // Data to write to the register, ignored if i_writeEnable is low when i_begin is asserted
	.i2c_scl(scl),  // SCL line, pass directly to IO
	.i2c_sda(sda),  // SDA line, pass directly to IO
	.o_done(done),  // Asserted high for 1 cycle of i_clk to indicate the I2C transaction is complete
	.wbEnable (w_wbEnable),
	.i_wbAck(r_wbAck)
	);

	reg r_wbAck;
	PUR PUR_INST(.PUR(1'b1));
	GSR GSR_INST(.GSR(1'b1));
	assign ( pull1, strong0 ) scl = 1'b1;
	assign ( pull1, strong0 ) sda = 1'b1;
	
	always begin
		#1 clk = !clk;
	end
	
	always @(posedge w_wbEnable) begin
		#6 r_wbAck = 1;
		#2 r_wbAck = 0;
	end
	
	initial
	begin	  	
		r_wbAck = 0;
		clk = 1;
		r_address = 7'h12;
		r_data = 8'h34;	  
		r_begin = 0;
		r_writeEnable = 0;
		#20
		r_begin = 1'b1;
		#1 r_begin = 1'b0;
		#300
		$finish;
	end
	
endmodule