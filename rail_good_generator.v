module rail_good_generator #(
	parameter STARTUP_DELAY = 32'd0
	)(
	input i_clk,
    input i_rail1, 
    input i_rail2,
    input i_rail3,
    output o_allGood
);

reg [31:0] r_counter = 0;
reg r_delayComplete = 0;

wire w_allGood;
assign w_allGood = (i_rail1 && i_rail2 && i_rail3);
assign o_allGood = w_allGood && r_delayComplete;

always @(posedge i_clk)begin
	if(w_allGood && ~r_delayComplete) begin
		r_counter <= r_counter + 1;
	end else begin
		r_counter <= 0;
	end
	
	if(r_counter > STARTUP_DELAY) begin
		r_delayComplete <= 1'b1;
	end else begin
		r_delayComplete <= r_delayComplete;
	end
	
end

endmodule