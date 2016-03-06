module Timing_Gen #(parameter SYSCLK_RATE = 100000000,
		parameter BAUD_RATE = 9600)
		
		(input logic SysClk,
		input Rst,
		output logic Clk);

	//Aliveness attempt
//	always @ (posedge SysClk or posedge Rst) begin	
	//	assert property(BAUD_RATE>0) else $error("BAUD_RATE must be more than 0");//-JF
	//	assert property Clk ##(CLOCK_DIV) ~Clk//to prove clock DIV is correct -JF
	//	assert property(SYSCLK_RATE>0) else $error("BAUD_RATE must be more than 0");//-JF
//	end
	
	localparam CLOCK_DIV = SYSCLK_RATE / BAUD_RATE; // Baud rate is transitions per second.  We get one transition per rising
								// clock edge, meaning we need two clock transitions per baud.
	integer ClockCounter;

	always @ (posedge SysClk or posedge Rst) begin
		if (Rst) begin
			Clk = '0;
			ClockCounter = '0;
		end
		else begin
			if (ClockCounter === CLOCK_DIV - 1) begin
				Clk = ~Clk;
				ClockCounter = '0;
			end
			else begin
				Clk = Clk;
				ClockCounter = ClockCounter + 1;
			end
		end
	end

endmodule
