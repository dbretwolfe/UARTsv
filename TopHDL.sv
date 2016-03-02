module TopHDL;

	parameter SYSCLK_RATE = 4;
	parameter BAUD_RATE = 1;
	parameter DATA_BITS = 8;
	parameter STOP_BITS = 2;
	parameter FIFO_WIDTH = 8;

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

endmodule