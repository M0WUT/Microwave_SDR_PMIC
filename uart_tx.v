module uart_tx
(
	input			i_clock,
	input 			i_txBegin,
	input[7:0]		i_txData,
	output 			o_txBusy,
	output reg		o_txSerial,
	output 			o_txDone
);

parameter 		CLOCKS_PER_BIT = 10; 

//states for the state machine
parameter 		s_IDLE = 0;
parameter 		s_DATABITS = 1;
parameter 		s_DONE = 2;

reg[3:0]		r_bitCounter = 0; //which bit we're currently sending
reg[9:0]		r_txData = 0; //copy txData to this in case i_txData gets altered during sending
reg[2:0]		r_state = s_IDLE; 
reg[15:0] 		r_clockCounter = 0;

assign o_txBusy = !(r_state == s_IDLE); 
assign o_txDone = (r_state == s_DONE);
 
always @ (posedge i_clock)
begin
	case (r_state)
		s_IDLE:
		begin
			o_txSerial <= 1;
			r_bitCounter <= 0;
			r_clockCounter <= 0;
			if(i_txBegin == 1) //we have valid data to start sending
			begin
				r_txData <= {1'b1, i_txData[7:0], 1'b0}; //copy input data to local copy appending start/stop bits
				r_state <= s_DATABITS;
				r_bitCounter <= 0;
			end
			else
				r_state <= s_IDLE;
		end //case s_IDLE
				
		s_DATABITS:
		begin
			o_txSerial <= r_txData[r_bitCounter];
			if(r_clockCounter < CLOCKS_PER_BIT)
			begin
				//Wait until time for next bit
				r_state <= s_DATABITS;
				r_clockCounter <= r_clockCounter + 1;
			end
			else
			begin
				//we are done sending current bit
				if(r_bitCounter < 'd9)
				begin
					//send next bit
					r_bitCounter <= r_bitCounter + 1;
					r_clockCounter <= 0;
				end
				else
				begin
					//we have sent all our data
					r_state <= s_DONE;
					r_clockCounter <= 0;
				end
			end			
		end //case s_DATABITS
		
		s_DONE:
		begin
			//1 cycle delay in which o_txDone is high (set in assign statement at top)
			o_txSerial <= 1;
			r_state <= s_IDLE;
		end //case s_DONE
		
	endcase
end 	

endmodule