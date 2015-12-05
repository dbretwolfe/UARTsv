module TopHDL;

	parameter SYSCLK_RATE = 4;
	parameter BAUD_RATE = 1;
	parameter DATA_BITS = 8;
	parameter STOP_BITS = 2;
	parameter FIFO_DEPTH = 8;

	localparam CLOCK_DELAY = 5;
	localparam TX_BITS = (1 + DATA_BITS + 1 + STOP_BITS);
	
	UART_IFace    #(.SYSCLK_RATE(SYSCLK_RATE),
					.BAUD_RATE(BAUD_RATE),
					.DATA_BITS(DATA_BITS),
					.STOP_BITS(STOP_BITS),
					.FIFO_DEPTH(FIFO_DEPTH)
				)
	TestIf();
	
	UARTsv TestUART(TestIf);
	
	// tbx clkgen
	initial
		begin
		TestIf.SysClk = 0;
		forever begin
		  #10 TestIf.SysClk = ~TestIf.SysClk;
		end
	end	

endmodule