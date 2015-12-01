module UART_HDL_tb ();

	parameter SYSCLK_RATE = 4;
	parameter BAUD_RATE = 1;
	parameter DATA_BITS = 8;
	parameter STOP_BITS = 2;
	parameter FIFO_DEPTH = 8;

	localparam CLOCK_DELAY = 5;
	localparam TX_BITS = (1 + DATA_BITS + 1 + STOP_BITS);

	logic SysClk = 0, Rst = 0, Rx = 1, CTS = 0, Data_Rdy, BIST_Busy, BIST_Error, Tx, RTS;
	logic [DATA_BITS-1:0] 	Rx_Data;
	logic [2:0] 			Rx_Error;
	logic					Clk;
	logic					FIFO_Empty;
	logic					Tests_Failed = 0;
	int						Num_Tests_Failed = 0;
	
	UART_IFace    #(.SYSCLK_RATE(SYSCLK_RATE),
					.BAUD_RATE(BAUD_RATE),
					.DATA_BITS(DATA_BITS),
					.STOP_BITS(STOP_BITS),
					.FIFO_DEPTH(FIFO_DEPTH)
				)
	TestIf (.SysClk(SysClk),
			.Rst(Rst),
			.Tx(Tx),
			.Rx(Rx),
			.CTS(CTS),
			.RTS(RTS));

endmodule