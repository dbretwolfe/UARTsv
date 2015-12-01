module UARTsv(UART_IFace UARTIf);

	localparam SYSCLK_RATE = UARTIf.SYSCLK_RATE;
	localparam BAUD_RATE = UARTIf.BAUD_RATE;
	localparam DATA_BITS = UARTIf.DATA_BITS;
	localparam STOP_BITS = UARTIf.STOP_BITS;
	localparam FIFO_DEPTH = UARTIf.FIFO_DEPTH;
	
	//Internal nets and variables
	wire [DATA_BITS-1:0]	Rx_Data_Out;
	wire 			Rx_In;
	wire [DATA_BITS-1:0]	Tx_Data_In;
	wire			Transmit_Start_In;
	wire			Data_Rdy_Out;		// Output from the Rx FSM indicating valid data output
	wire [DATA_BITS-1:0]	BIST_Tx_Data_Out;	// Output from the BIST module, muxed with Tx_Data
	wire 			BIST_Tx_Start_Out;	// Output from the BIST module, muxed with Transmit_Start
	wire			BIST_Mode;		// Control signal to the mux/demux, from BIST
	wire 			Clk;			// Clock generated from the timing module
	
	//Mux assignments
	assign Tx_Data_In = BIST_Mode ? BIST_Tx_Data_Out : UARTIf.Tx_Data; // If BIST is active, the Tx FSM gets its parallel data input from the BIST module,
	//assign Tx_Data_In = UARTIf.Tx_Data;
								    // otherwise from the top module port.
	assign Transmit_Start_In = BIST_Mode ? BIST_Tx_Start_Out : UARTIf.Transmit_Start; //Likewise, the Tx FSM will get its transmit start command
								    // from the BIST module, otherwise from the top module port.
	assign Rx_In = BIST_Mode ? UARTIf.Tx : UARTIf.Rx;		// If BIST is active, the Rx FSM gets it's serial data input from the serial output of the Tx FSM,
							// otherwise the Rx FSM gets its data from the top module port
	
	assign UARTIf.Data_Rdy = Data_Rdy_Out;
	
	//*********************************************
	//
	//		Modules
	//
	//  Timing Generator
	//  Receiver
	//  Transmitter
	//  Built-in Self Test
	//  FIFO
	//
	//*********************************************
	Timing_Gen #(
		.SYSCLK_RATE(SYSCLK_RATE),
		.BAUD_RATE(BAUD_RATE)
		)
	BaudGen (
		.SysClk(UARTIf.SysClk),
		.Rst(UARTIf.Rst),
		.Clk
		);

	RX_FSM #(
		.STOP_BITS(STOP_BITS),
		.DATA_BITS(DATA_BITS)
		)
	Receiver (
		.Clk,
		.Rst(UARTIf.Rst),
		.Rx_In,			// Input from de-mux
		.RTS(UARTIf.RTS),			// Output to module port
		.Data_Rdy_Out,		// Output to mux
		.Rx_Data_Out,		// Output to module port and BIST FSM
		.Rx_Error(UARTIf.Rx_Error)
	);

	TX_FSM #(
		.STOP_BITS(STOP_BITS),
		.DATA_BITS(DATA_BITS)
		)
	Transmitter (
		.Clk,
		.Rst(UARTIf.Rst),
		.Tx_Data_In,		// Input from de-mux - either from BIST or top module port
		.Transmit_Start_In,	// Input from de-mux - either from BIST or top module port
		.CTS(UARTIf.CTS),			// Input from module port
		.Tx(UARTIf.Tx),			// Output to module port
		.Tx_Busy(UARTIf.Tx_Busy)
	);

	BIST_FSM #(
		.DATA_BITS(DATA_BITS)
		)
	SelfTest (
		.Clk,
		.Rst(UARTIf.Rst),
		.BIST_Start(UARTIf.BIST_Start),		// Input from module port
		.Data_Rdy_Out,		// Input from Rx FSM
		.Rx_Data_Out,		// Input from Rx FSM
		.RTS(UARTIf.RTS),
		.Tx_Busy(UARTIf.Tx_Busy),
		.BIST_Mode,		// Output to mux/demux
		.BIST_Tx_Data_Out,	// Output to the Tx FSM input mux
		.BIST_Tx_Start_Out,	// Output to the Tx FSM input mux
		.BIST_Error(UARTIf.BIST_Error),
		.BIST_Busy(UARTIf.BIST_Busy)
	);

	//*********************************************
	//
	//		FIFO MODULE INSTANTIATION
	//
	//  
	//
	//*********************************************
	
	FIFO #(
		.DATA_BITS(DATA_BITS),
		.FIFO_DEPTH(FIFO_DEPTH)
		)
	fifo_initialize(
		.Rst(UARTIf.Rst),
		.Rx_Data(Rx_Data_Out),
		.Data_Rdy(Data_Rdy_Out),  		//	To write data to FIFO 
		.Read_Done(UARTIf.Read_Done), 		// 	To read data from FIFO
		.BIST_Mode,
		.FIFO_Empty(UARTIf.FIFO_Empty), 
		.FIFO_Full(UARTIf.FIFO_Full), 
		.FIFO_Overflow(UARTIf.FIFO_Overflow), 
		.Data_Out(UARTIf.Data_Out)
	);	
endmodule