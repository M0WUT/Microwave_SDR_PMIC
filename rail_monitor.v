module rail_monitor(
    input i_voltageGood,
    input i_currentGood,
    input i_resetn,
    output o_railGood, // Green LED
    output reg o_voltageFault,  // Blue LED
    output reg o_currentFault  // Red LED
);

assign o_railGood = (i_currentGood && i_voltageGood && ~o_currentFault && ~o_voltageFault);

always @(negedge i_voltageGood or negedge i_resetn) begin
    if (~i_resetn) begin
        o_voltageFault <= 1'b0;
    end else begin
        o_voltageFault <= 1'b1;
    end
end

always @(negedge i_currentGood or negedge i_resetn) begin
    if (~i_resetn) begin
        o_currentFault <= 1'b0;
    end else begin
        o_currentFault <= 1'b1;
    end
end

endmodule



