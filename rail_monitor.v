module rail_monitor #(
	parameter STARTUP_DELAY = 0,
	parameter ERROR_DELAY = 0
	)
	(
	input i_clk,
    input i_voltageGood,
    input i_currentGood,
    output o_railGood, // Green LED
    output o_voltageFault,  // Blue LED
    output o_currentFault  // Red LED
);

reg r_voltageFault = 0;
reg r_currentFault = 0;
reg r_enabled = 0; 
reg [22:0] r_startupCounter = 0;
reg [22:0] r_voltageErrorCounter = 0;
reg [22:0] r_currentErrorCounter = 0;
wire w_railGood;

assign w_railGood = ~r_voltageFault && ~r_currentFault;
assign o_railGood = w_railGood && r_enabled;
assign o_voltageFault = r_voltageFault;
assign o_currentFault = r_currentFault;


always @(posedge i_clk) begin
	
	// Both current and voltage (basically just voltage as we can't draw current from a disabled rail)
	// must be good for a while (to ensure rail stability) before indicating that rail is good
	if (i_voltageGood && i_currentGood && ~r_enabled) begin
		r_startupCounter <= r_startupCounter + 1;
	end else begin
		r_startupCounter <= 0;
	end
	if(r_startupCounter > STARTUP_DELAY) begin
		r_enabled <= 1'b1;
	end else begin
		r_enabled <= r_enabled;
	end	

	
	// If the rail has been indicated as good but now has a voltage fault
	// check error persists for ERROR_DELAY then latch fault
	if (r_enabled && ~i_voltageGood && ~r_currentFault) begin
		r_voltageErrorCounter <= r_voltageErrorCounter + 1;
	end else begin
		r_voltageErrorCounter <= 0;
	end


	if (r_voltageErrorCounter > ERROR_DELAY) begin
		r_voltageFault <= 1'b1;
	end else begin
		r_voltageFault <= r_voltageFault;
	end


	
	// If the rail has been indicated as good but now has a voltage fault
	// check error persists for ERROR_DELAY then latch fault
	if (r_enabled && ~i_currentGood && ~r_voltageFault) begin
		r_currentErrorCounter <= r_currentErrorCounter + 1;
	end else begin
		r_currentErrorCounter <= 0;
	end
	
	if (r_currentErrorCounter > ERROR_DELAY) begin
		r_currentFault <= 1'b1;
	end else begin
		r_currentFault <= r_currentFault;
	end


end

endmodule



