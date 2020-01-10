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
localparam STARTUP_DELAY_CLOCK_CYCLES = OSCILLATOR_FREQUENCY; // 1s delay
localparam ERROR_DELAY_CLOCK_CYCLES = OSCILLATOR_FREQUENCY * 2; // 1s of error before system locks

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

// I2C Handler
reg r_i2cReadBegin = 0;
reg[6:0] r_i2cAddress = 8'h60;
wire[7:0] w_i2cRxData;

i2c_handler i2c_inst1(
	.i_clk(clk),
	.i_begin(1'b1), // DEBUG: continually transmit
	.i_writeEnable(1'b0),  // DEBUG: always read to minimise risk of bork
	.i_i2cAddress(7'h12),
	.i2c_scl(i2c_scl),
	.i2c_sda(i2c_sda)
);

reg[15:0] r_counter = 0;
always @(posedge clk) begin
	r_counter <= r_counter + 1;
	if(r_counter == 16'hFFFF) begin
		r_i2cReadBegin <= 1'b1;
	end else begin
		r_uartTxBegin <= 1'b0;
	end
end

/////////////
// Stage 1 //
/////////////

rail_monitor #(
    .STARTUP_DELAY(STARTUP_DELAY_CLOCK_CYCLES),
    .ERROR_DELAY(ERROR_DELAY_CLOCK_CYCLES)
    ) monitor_12V (
	.i_clk(clk),
	.i_voltageGood(i_12V_voltageGood),
    .i_currentGood(i_12V_currentGood),
    .o_railGood(o_12V_railGood),
    .o_voltageFault(o_12V_voltageFault),
    .o_currentFault(o_12V_currentFault)
);

rail_good_generator #(.STARTUP_DELAY(STARTUP_DELAY_CLOCK_CYCLES)) S1(
	.i_clk(clk),
	.i_rail1(o_12V_railGood),
	.i_rail2(1'b1),
	.i_rail3(1'b1),
	.i_rail4(1'b1),
	.i_rail5(1'b1),
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
	.i_clk(clk),
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
	.i_clk(clk),
	.i_voltageGood(i_3V3_voltageGood),
    .i_currentGood(i_3V3_currentGood),
    .o_railGood(o_3V3_railGood),
    .o_voltageFault(o_3V3_voltageFault),
    .o_currentFault(o_3V3_currentFault)
);

endmodule
