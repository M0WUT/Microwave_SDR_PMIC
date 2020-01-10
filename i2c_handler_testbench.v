`timescale 1ns / 1ns

module i2c_handler_testbench;
	
	reg clk;
	reg r_begin;
	reg r_writeEnable;
	reg [6:0] r_address;
	reg [7:0] r_data;
	
	i2c_handler dut(
	.i_clk(clk),
	.i_begin(r_begin),
	.i_writeEnable(r_writeEnable),
	.i_i2cAddress(r_address)
);


	always begin
		#1 clk = !clk;
	end
	
	initial
	begin	  	
		clk = 1;
		r_address = 7'h12;
		r_data = 8'h34;	  
		r_begin = 0;
		r_writeEnable = 1;
		#50
		r_begin = 1'b1;
		#1 r_begin = 1'b0;
		#50
		$finish;
	end
	
endmodule