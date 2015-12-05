interface UART_IFace;

	parameter SYSCLK_RATE = 100000000;
	parameter BAUD_RATE = 9600;
	parameter DATA_BITS = 8;
	parameter PARITY_BIT = 1;
	parameter STOP_BITS = 2;
	parameter FIFO_DEPTH = 8;
	
	localparam TX_BITS = (1 + DATA_BITS + 1 + STOP_BITS);

	//pragma attribute UART_IFace partition_interface_xif 
	logic 					SysClk;
	logic					Clk;
	logic 					Rst;
	logic 					Rx;
	logic 					CTS;
	logic 					Tx;
	logic 					RTS;
	logic 					BIST_Start;
	logic [DATA_BITS-1:0] 	Tx_Data;
	logic 					Transmit_Start;
	logic					Tx_Busy;
	logic [DATA_BITS-1:0] 	Data_Out;
	logic 					Data_Rdy;
	logic [2:0] 			Rx_Error;
	logic 					BIST_Busy;
	logic 					BIST_Error;
	logic 					Read_Done;		// Input to FIFO to cycle new data onto output
	logic					FIFO_Empty;		// Output from FIFO - no data
	logic					FIFO_Full; 		// Output from FIFO - 
	logic					FIFO_Overflow;		// Output from FIFO
	
	import TestPackage::*;

	task automatic WriteData(logic [DATA_BITS-1:0] WriteBuf); //pragma tbx xtf
		while (Tx_Busy)	// Wait until the current transmission is finished, if any
			@(posedge SysClk);
		Tx_Data = WriteBuf;	// Set the transmit data reg
		@(negedge SysClk);	// On the next negative clock edge,
		Transmit_Start = '1;	// assert transmit start.
		@(negedge Tx);
		Transmit_Start = '0;	// Hold transmit start until the start bit is set on Tx.  The 
					// transmission should now be started.
	endtask

	task automatic ReadData(ref logic [DATA_BITS-1:0] ReadBuf); //pragma tbx xtf
		while (FIFO_Empty)// Make sure the fifo is not empty
			@(posedge SysClk);
		@(posedge SysClk);
		Read_Done = '1;		// Strobe the Read_Done input to tell the FIFO to cycle
		@(posedge SysClk);
		Read_Done = '0;		// in new data.
		ReadBuf = Data_Out; 	// Copy the data from the FIFO output
	endtask
	
	task automatic Start_BIST(); //pragma tbx xtf
		BIST_Start = '1;
		while(!BIST_Busy)
			@(posedge SysClk);
		BIST_Start = '0;
	endtask
			
endinterface
