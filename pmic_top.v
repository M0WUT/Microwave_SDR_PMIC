module pmic_top(
    input i_12V_voltageGood,
    input i_12V_currentGood,
    output o_12V_currentFault,
    output o_12V_railGood,
    output o_12V_voltageFault,

    input i_3V3_voltageGood,
    input i_3V3_currentGood,
    output o_3V3_currentFault,
    output o_3V3_railGood,
    output o_3V3_voltageFault,

    input i_5V_voltageGood,
    input i_5V_currentGood,
    output o_5V_currentFault,
    output o_5V_railGood,
    output o_5V_voltageFault,

    input i_3V3ADC_voltageGood,
    input i_3V3ADC_currentGood,
    output o_3V3ADC_currentFault,
    output o_3V3ADC_railGood,
    output o_3V3ADC_voltageFault,

    input i_fpgaPwrGood,
	output o_fpgaGood,
	output o_fpgaFault,

    output o_S1Good,
	output o_S1GoodLED,
    output o_S2Good,
	output o_S2GoodLED,
    output o_S3Good,
	output o_S3GoodLED,
	
	output o_uartTx,
	input i_uartRx,
	
	output o_uartError,
	output o_i2cError,
	
	inout i2c_sda,
	inout i2c_scl
);

wire clk;
// Internal Oscillator
defparam OSCH_inst.NOM_FREQ = "4.16"; //Clk Frequency in MHz
localparam OSCILLATOR_FREQUENCY = 4160000;
localparam STARTUP_DELAY_CLOCK_CYCLES = 1000; // 1s delay
localparam ERROR_DELAY_CLOCK_CYCLES = 3000;// 1s of error before system locks

wire slow_clock;
reg[11:0] r_clockDivider = 0;
assign slow_clock = r_clockDivider[11]; // Slow clock is roughly 1kHz

always @(posedge clk) begin
	r_clockDivider <= r_clockDivider + 1;
end

OSCH OSCH_inst(
	.STDBY(1'b0),
	.OSC(clk),
	.SEDSTDBY()
); 


//UART Transmitter
reg r_uartTxBegin = 0;
reg[7:0] r_uartTxData = 0;

wire w_uartTxBusy;
wire w_uartTxDone;

uart_tx #(
	.CLOCKS_PER_BIT(1000) // 4.16MHz clock / 1000 ~= 4kHz baudrate
	) uart_tx_inst (
	.i_clock(clk),
	.i_txBegin(r_uartTxBegin),
	.i_txData(r_uartTxData),
	.o_txBusy(w_uartTxBusy),
	.o_txSerial(o_uartTx),
	.o_txDone(w_uartTxDone)
); 
/*
// I2C Handler
reg r_i2cBegin = 0;
reg[7:0] r_i2cRegAddress = 0;
reg[6:0] r_i2cSlaveAddress;
reg [7:0] r_i2cTxData = 0;
wire[7:0] w_i2cRxData;
wire w_i2cDone;
reg r_i2cWriteEnable = 0;

i2c_handler i2c_inst1(
	.i_clk(clk),  // Input clock 
	.i_begin(r_i2cBegin),  // Logic high will begin I2C transaction
	.i_writeEnable(r_i2cWriteEnable),  // High to write i_txData to i_regAddress, Low to read from i_regAddress
	.i_i2cAddress(r_i2cSlaveAddress),  // 7 bit I2C address of slave
	.i_regAddress(r_i2cRegAddress),  // Register address within the slave
	.i_txData(r_i2cTxData),  // Data to write to the register, ignored if i_writeEnable is low when i_begin is asserted
	.i_bytesToTx(2'b1),
	.i_bytesToRx(2'd2),
	.i2c_scl(i2c_scl),  // SCL line, pass directly to IO
	.i2c_sda(i2c_sda),  // SDA line, pass directly to IO
	.o_done(w_i2cDone)  // Asserted high for 1 cycle of i_clk to indicate the I2C transaction is complete
);

reg[1:0] r_state = 0;
reg[12:0] r_delay = 0;
reg [6:0] r_i2cAddress [3:0];
reg [1:0] r_i2cAddressCounter = 0;

initial begin
	r_i2cAddress[0] = 7'h70;
	r_i2cAddress[1] = 7'h7C;
	r_i2cAddress[2] = 7'h73;
	r_i2cAddress[3] = 7'h72;
end

always @(negedge clk) begin
	case(r_state)
		0: begin
		  	r_i2cBegin <= 1'b1;
			r_i2cWriteEnable <= 1'b1;
			r_i2cRegAddress <= 8'h0A;
			r_i2cSlaveAddress <= r_i2cAddress[r_i2cAddressCounter];
			r_i2cTxData <= 8'h02;  // Take voltage reading
			r_delay <= 8191;
			r_state <= (w_i2cDone ? 1 : 0);
			
		end
		
		1: begin
			r_i2cBegin <= 1'b0;
			r_i2cWriteEnable <= 1'b0;
			if(r_delay == 0) begin
				r_state <= 2;
			end else begin
				r_delay <= r_delay - 1;
				r_state <= 1;
			end
		end

		2: begin
		  	r_i2cBegin <= 1;
			r_i2cWriteEnable <= 0;
			r_i2cRegAddress <= 0;  // Read voltage register
			r_state <= (w_i2cDone ? 0 : 2);
			r_i2cAddressCounter <= r_i2cAddressCounter + 1;
		end

	endcase
end
*/
/////////////
// Stage 1 //
/////////////

rail_monitor #(
    .STARTUP_DELAY(STARTUP_DELAY_CLOCK_CYCLES),
    .ERROR_DELAY(ERROR_DELAY_CLOCK_CYCLES)
    ) monitor_12V (
	.i_clk(slow_clock),
	.i_voltageGood(i_12V_voltageGood),
    .i_currentGood(i_12V_currentGood),
    .o_railGood(o_12V_railGood),
    .o_voltageFault(o_12V_voltageFault),
    .o_currentFault(o_12V_currentFault)
);

rail_good_generator #(.STARTUP_DELAY(STARTUP_DELAY_CLOCK_CYCLES)) S1(
	.i_clk(slow_clock),
	.i_rail1(o_12V_railGood),
	.i_rail2(1'b1),
	.i_rail3(1'b1),
	.o_allGood(o_S1Good)
);

assign o_S1GoodLED = o_S1Good;

/////////////
// Stage 2 //
/////////////

rail_monitor #(
    .STARTUP_DELAY(STARTUP_DELAY_CLOCK_CYCLES),
    .ERROR_DELAY(ERROR_DELAY_CLOCK_CYCLES)
    )
	monitor_5V(
	.i_clk(slow_clock),
	.i_voltageGood(i_5V_voltageGood),
    .i_currentGood(i_5V_currentGood),
    .o_railGood(o_5V_railGood),
    .o_voltageFault(o_5V_voltageFault),
    .o_currentFault(o_5V_currentFault)
);

rail_monitor #(
    .STARTUP_DELAY(STARTUP_DELAY_CLOCK_CYCLES),
    .ERROR_DELAY(ERROR_DELAY_CLOCK_CYCLES)
    )
	monitor_3V3(
	.i_clk(slow_clock),
	.i_voltageGood(i_3V3_voltageGood),
    .i_currentGood(i_3V3_currentGood),
    .o_railGood(o_3V3_railGood),
    .o_voltageFault(o_3V3_voltageFault),
    .o_currentFault(o_3V3_currentFault)
);

rail_good_generator #(.STARTUP_DELAY(STARTUP_DELAY_CLOCK_CYCLES)) S2(
	.i_clk(slow_clock),
	.i_rail1(o_5V_railGood),
	.i_rail2(o_3V3_railGood),
	.i_rail3(o_S1Good),
	.o_allGood(o_S2Good)
);

assign o_S2GoodLED = o_S2Good;

/////////////
// Stage 3 //
/////////////

rail_monitor #(
    .STARTUP_DELAY(STARTUP_DELAY_CLOCK_CYCLES),
    .ERROR_DELAY(ERROR_DELAY_CLOCK_CYCLES)
    )
	monitor_3V3ADC(
	.i_clk(slow_clock),
	.i_voltageGood(i_3V3ADC_voltageGood),
    .i_currentGood(i_3V3ADC_currentGood),
    .o_railGood(o_3V3ADC_railGood),
    .o_voltageFault(o_3V3ADC_voltageFault),
    .o_currentFault(o_3V3ADC_currentFault)
);

rail_monitor #(
    .STARTUP_DELAY(STARTUP_DELAY_CLOCK_CYCLES),
    .ERROR_DELAY(ERROR_DELAY_CLOCK_CYCLES)
    )
	monitor_FPGA(
	.i_clk(slow_clock),
	.i_voltageGood(1'b1),
    .i_currentGood(i_fpgaPwrGood),
    .o_railGood(o_fpgaGood),
    .o_voltageFault(),
    .o_currentFault(o_fpgaFault)
);

rail_good_generator #(.STARTUP_DELAY(STARTUP_DELAY_CLOCK_CYCLES)) S3(
	.i_clk(slow_clock),
	.i_rail1(o_3V3ADC_railGood),
	.i_rail2(o_fpgaGood),
	.i_rail3(o_S2Good),
	.o_allGood(o_S3Good)
);

assign o_S3GoodLED = o_S3Good;


endmodule
