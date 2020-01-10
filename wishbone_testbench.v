`timescale 1ns / 1ns

module wishbone_testbench;
	
	reg clk;
	reg r_begin;
	reg r_writeEnable;
	reg [6:0] r_address;
	reg [7:0] r_data;
	
	wishbone_handler dut(
	.i_clk(clk),
	.i_begin(r_begin),	 
	.i_writeEnable(r_writeEnable),
	.o_done(),
	.i_address(r_address),
	.i_writeData(r_data),
	.o_readData(),
	.i2c_scl(),
	.i2c_sda()
	);

	always begin
		#1 clk = !clk;
	end
	
	initial
	begin	  
		clk = 0;
		r_address = 7'h12;
		r_data = 8'h34;	 
		r_begin = 0;
		r_writeEnable = 1'b1;
		#5 r_begin = 1;
		#1 r_begin = 0;
		#20 $finish;
	end
	
endmodule