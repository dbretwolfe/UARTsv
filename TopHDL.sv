module TopHDL;

	parameter SYSCLK_RATE = 4;
	parameter BAUD_RATE = 1;
	parameter DATA_BITS = 8;
	parameter STOP_BITS = 2;
	parameter FIFO_DEPTH = 8;

	localparam CLOCK_DELAY = 5;
	localparam TX_BITS = (1 + DATA_BITS + 1 + STOP_BITS);
	logic clk;
	
	assign TestIf.SysClk = clk;
	
	UART_IFace    #(.SYSCLK_RATE(SYSCLK_RATE),
					.BAUD_RATE(BAUD_RATE),
					.DATA_BITS(DATA_BITS),
					.STOP_BITS(STOP_BITS),
					.FIFO_DEPTH(FIFO_DEPTH)
				)
	TestIf();
	
	UARTsv TestUART(TestIf);

//clocking initial assertions	
	// tbx clkgen
//	initial
			//////////////////    Assertion Block     ////////////////////
		//assert range of SysCLK_Rate
		//assert ((SYSCLK_RATE > 3) && (SYSCLK_RATE<1000000000000)) else $error("SYSCLK_RATE is not in bounds");  
		//assert range of Baud_Rate  
		//assert ((BAUD_RATE > 0) && (BAUD_RATE<7000000)) else $error("BAUD_RATE is not in bounds");  
		//assert range of Data Bits  
		//assert ((DATA_BITS > 0) && (DATA_BITS<9)) else $error("DATA_BITS is not in bounds");  
		//assert range of Stop_bits  
		//assert ((STOP_BITS > 0) && (STOP_BITS<3)) else $error("STOP_BITS is not in bounds");  
		//assert range of FIFO_Depth  
		//assert ((FIFO_DEPTH > 0) && (FIFO_DEPTH<17)) else $error("FIFO_DEPTH is not in bounds");  
		//Assert critical relationships Baud rate, sysCLK_Rate, clock delay(below) 	
//	end
	
	// tbx clkgen
	initial
		begin
		clk = 0;
		forever begin
		  #10 clk = ~clk;
		end
	end	

endmodule
