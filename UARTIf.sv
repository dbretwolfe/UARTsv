interface UART_IFace  #(parameter SYSCLK_RATE = 100000000,
			parameter BAUD_RATE = 9600,
			parameter DATA_BITS = 8,
			parameter PARITY_BIT = 1,
			parameter STOP_BITS = 2,
			parameter FIFO_DEPTH = 8)

		    // These inputs and outputs always need to be hooked up.  The last four
		    // would be the external connections to board IO.
		    (input logic SysClk, 
		     input logic Rst,
		     input logic Rx,
		     input logic CTS,
		     output logic Tx,
		     output logic RTS);

	logic 			BIST_Start;
	logic [DATA_BITS-1:0] 	Tx_Data;
	logic 			Transmit_Start;
	logic			Tx_Busy;
	logic [DATA_BITS-1:0] 	Data_Out;
	logic 			Data_Rdy;
	logic [2:0] 		Rx_Error;
	logic 			BIST_Busy;
	logic 			BIST_Error;
	logic 			Read_Done;		// Input to FIFO to cycle new data onto output
	logic			FIFO_Empty;		// Output from FIFO - no data
	logic			FIFO_Full; 		// Output from FIFO - 
	logic			FIFO_Overflow;		// Output from FIFO
	
	// Modport for the testbench user
	modport RWFunctions (import Write_Data,
			     import Read_Data);

	task automatic WriteData(logic [DATA_BITS-1:0] WriteBuf);
		while (Tx_Busy);
		@(negedge SysClk);
		Tx_Data = WriteBuf;
		@(negedge SysClk);
		Transmit_Start = '1;
		@(negedge SysClk);
	endtask

	task automatic ReadData(ref logic [DATA_BITS-1:0] ReadBuf);

	endtask
	
	// Modport for the UART side
	modport full   (output SysClk,
			output Rst,
			input Tx,
			output Rx,
			output CTS,
			input RTS,
			output Tx_Data,
			output Transmit_Start,
			output BIST_Start,
			output Read_Done,
			input Tx_Busy,
			input Data_Rdy,
			input Rx_Error,
			input BIST_Busy,
			input BIST_Error,
			input Data_Out,
			input FIFO_Empty,
			input FIFO_Full,
			input  FIFO_Overflow
			
	);
endinterface
