/*
=====================================================================================
Final Project Uart
ECE 510 
winter 2016
Randon Stasney Devin Wolfe Jonathan Fernow
Timing_Gen.sv - Timing_Gen
3/18/2016
Description:
Timing generator that parses the clocks

Version 2.1
Adapted from Devin Wolfe, Nikhil Marda, Goutham Konidala 571 project
=====================================================================================
*/
module Timing_Gen #(parameter SYSCLK_RATE = 100000000,
		parameter BAUD_RATE = 9600)
		
		(input logic SysClk,
		input Rst,
		output logic Clk);

	//Aliveness attempt
	always @ (posedge SysClk or posedge Rst) begin	
	//Aliveness attempt
initial
	begin	
		assert property (@(posedge SysClk) (BAUD_RATE>0)) else $error("BAUD_RATE must be more than 0");//-JF
		assert property (@(posedge clk) Clk ##(CLOCK_DIV) ~Clk)//to prove clock DIV is correct -JF
		assert property (@(posedge clk) (SYSCLK_RATE>0)) else $error("BAUD_RATE must be more than 0");//-JF
	end

	
	localparam CLOCK_DIV = SYSCLK_RATE / (2*BAUD_RATE); // Baud rate is transitions per second.  We get one transition per rising
														// clock edge, meaning we need two clock transitions per baud.
	integer ClockCounter;

	always @ (posedge SysClk or posedge Rst) begin
		if (Rst) begin
			Clk <= '0;
			ClockCounter <= '0;
		end
		else begin
			if (ClockCounter === CLOCK_DIV - 1) begin
				Clk <= ~Clk;
				ClockCounter <= '0;
			end
			else begin
				Clk <= Clk;
				ClockCounter <= ClockCounter + 1;
			end
		end
	end

endmodule
