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
	modport RWFunctions    (import Write_Data,
			     	import Read_Data,
			     	input FIFO_Empty,
				input FIFO_Full,
				input FIFO_Overflow,
				input BIST_Error,
				input Rx_Error);

	task automatic WriteData(logic [DATA_BITS-1:0] WriteBuf);
		while (Tx_Busy);	// Wait until the current transmission is finished, if any
		Tx_Data = WriteBuf;	// Set the transmit data reg
		@(negedge SysClk);	// On the next negative clock edge,
		Transmit_Start = '1;	// assert transmit start.
		@(negedge Tx);
		Transmit_Start = '1;	// Hold transmit start until the start bit is set on Tx.  The 
					// transmission should now be started.
		$display("Got here.");
	endtask

	function automatic logic ReadData(ref logic [DATA_BITS-1:0] ReadBuf);
		if (!FIFO_Empty) begin		// Make sure the fifo is not empty
			ReadBuf = Data_Out; 	// Copy the data from the FIFO output
			Read_Done = '1;		// Strobe the Read_Done input to tell the FIFO to cycle
			Read_Done = '0;		// in new data.
			return '0;
		end
		else
			return '1;
	endfunction
	
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
