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
	
	output o_UARTError,
	output o_I2CError
);

wire clk;
// Internal Oscillator
defparam OSCH_inst.NOM_FREQ = "4.0";
OSCH OSCH_inst(
	.STDBY(1'b0),
	.OSC(clk),
	.SEDSTDBY()
); 

reg[18:0] clockDivider;
wire slowClock;
always@(posedge clk) begin
	clockDivider <= clockDivider + 1;
end
assign slowClock = clockDivider[17];



wire[18:0] outputLEDs;
reg[7:0] counter = 0;
assign outputLEDs = (1 << counter);

assign o_fpgaFault = outputLEDs[0];
assign o_fpgaGood = outputLEDs[1];
assign o_3V3ADC_currentFault = outputLEDs[2];
assign o_3V3ADC_railGood = outputLEDs[3];
assign o_3V3ADC_voltageFault = outputLEDs[4];
assign o_5V_currentFault = outputLEDs[5];
assign o_5V_railGood = outputLEDs[6];
assign o_5V_voltageFault = outputLEDs[7];
assign o_3V3_currentFault = outputLEDs[8];
assign o_3V3_railGood = outputLEDs[9];
assign o_3V3_voltageFault = outputLEDs[10];
assign o_12V_currentFault = outputLEDs[11];
assign o_12V_railGood = outputLEDs[12];
assign o_12V_voltageFault = outputLEDs[13];
assign o_S3GoodLED = outputLEDs[14];
assign o_S2GoodLED = outputLEDs[15];
assign o_UARTError = outputLEDs[16];
assign o_S1GoodLED = outputLEDs[17];
assign o_I2CError = outputLEDs[18];



always @(posedge slowClock) begin
	if(counter == 18) begin
		counter <= 0;
	end else begin
		counter <= counter + 1;
	end
end


endmodule
