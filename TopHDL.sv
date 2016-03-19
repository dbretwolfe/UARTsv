/*
=====================================================================================
Final Project Uart
ECE 510 
winter 2016
Randon Stasney Devin Wolfe Jonathan Fernow
TopHDL.sv - TopHDL
3/18/2016
Description:
Hardware top module. Generate the clock and instantiate the interface

Version 2.2
Adapted from Devin Wolfe, Nikhil Marda, Goutham Konidala 571 project
=====================================================================================
*/
module TopHDL;

	parameter SYSCLK_RATE = 9600000;
	parameter BAUD_RATE = 9600;
	parameter DATA_BITS = 8;
	parameter STOP_BITS = 2;
	parameter FIFO_WIDTH = 4;

	localparam CLOCK_DELAY = 5;
	localparam TX_BITS = (1 + DATA_BITS + 1 + STOP_BITS);
	logic clk;

	assign TestIf.SysClk = clk;
	
	UART_IFace    #(.SYSCLK_RATE(SYSCLK_RATE),
					.BAUD_RATE(BAUD_RATE),
					.DATA_BITS(DATA_BITS),
					.STOP_BITS(STOP_BITS),
					.FIFO_WIDTH(FIFO_WIDTH)
				)
	TestIf();
	
	UARTsv TestUART(TestIf);
	
	// tbx clkgen
	initial
		begin
		clk = 0;
		forever begin
		  #10 clk = ~clk;
		end
	end	

	//////////////////    Assertion Block     ////////////////////

initial
	begin
	//Adding agreeded upon bounds(negative check, zeros, and upper tested limits of what has been tested)
	//assert range of SysCLK_Rate
	assert property (@(posedge clk) ((SYSCLK_RATE > 3) && (SYSCLK_RATE<100000000))) else $error("SYSCLK_RATE is not in bounds");  
	//assert range of Baud_Rate  
	assert property (@(posedge clk) ((BAUD_RATE > 0) && (BAUD_RATE<7000000))) else $error("BAUD_RATE is not in bounds");  
	//assert range of Data Bits  
	assert property (@(posedge clk) ((DATA_BITS > 0) && (DATA_BITS<9))) else $error("DATA_BITS is not in bounds");  
	//assert range of Stop_bits  
	assert property (@(posedge clk) ((STOP_BITS > 0) && (STOP_BITS<3))) else $error("STOP_BITS is not in bounds");  
	//assert range of FIFO_Depth  
	assert property (@(posedge clk) ((FIFO_WIDTH > 0) && (FIFO_WIDTH<17))) else $error("FIFO_DEPTH is not in bounds");  
	//Assert critical relationships Baud rate, sysCLK_Rate, clock delay(below)  
end


endmodule
